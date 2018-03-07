#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SmartToken.TokenEntity do
  alias Noizu.SmartToken.TokenEntity
  alias Noizu.KitchenSink.Types, as: T

  @moduledoc """
    This class is used to represent a token that will be generated and stored to mnesia.
    It's data structure allows for late binding of fields like recipient, time_period, etc.
    On created late bindings are converted to final values.
  """
  @vsn 1.00

  @type t :: %__MODULE__{
               identifier: integer,
               token: :generate | {String.t, String.t},
               type: atom,
               resource: {:bind, atom} | T.entity_reference,
               scope: atom | tuple,
               active: true,
               state: T.state,
               context: {:bind, atom} | T.entity_reference,
               owner: {:bind, atom} | T.entity_reference,
               validity_period: nil | {:unbound | {:relative, Dict.t} | {:exact, DateTime.t}, :unbound | {:relative, Dict.t} | {:exact, DateTime.t}},
               permissions: {:bind, atom} | {atom, {:bind, atom}} | T.permissions,
               extended_info: any, # remaining access attempts, additional security settings, etc.
               access_history: any,
               template: any,
               kind: module,

               vsn: float
             }

  defstruct [
    identifier: nil,
    token: :generate,
    type: nil,
    resource: nil,
    scope: nil,
    active: true,
    state: nil,
    context: nil,
    owner: nil,
    validity_period: nil,
    permissions: nil,
    extended_info: nil,
    access_history: nil,
    template: nil,
    kind: __MODULE__,
    vsn: @vsn
  ]

  use Noizu.Scaffolding.EntityBehaviour,
      sref_module: "smart-token",
      mnesia_table: Noizu.SmartToken.Database.TokenTable,
      as_record_options: %{additional_fields: [:active, :token]},
      override: [],
      default_implementation: Noizu.Scaffolding.EntityBehaviour.DefaultImplementation

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

  #---------------------------
  #
  #---------------------------
  def bind(%__MODULE__{} = this, bindings) do
    %__MODULE__{this|
      token: bind_token(this.token, bindings),
      resource: bind_ref(this.resource, bindings),
      context: bind_ref(this.context, bindings),
      owner: bind_ref(this.owner, bindings),
      validity_period: bind_period(this.validity_period, bindings),
      access_history: %{history: [], count: 0},
      template: this
    }
  end

  #---------------------------
  #
  #---------------------------
  def bind_ref(ref, bindings) do
    case ref do
      {:bind, field} when !is_list(field) -> get_in(bindings, [field]) |> Noizu.ERP.ref()
      {:bind, path} when is_list(path) -> get_in(bindings, path) |> Noizu.ERP.ref()
      _ -> ref
    end
  end

  #---------------------------
  #
  #---------------------------
  def bind_token(:generate, bindings) do
    {UUID.uuid4(), UUID.uuid4()}
  end
  def bind_token(token, bindings), do: token

  #---------------------------
  #
  #---------------------------
  def bind_period(%__MODULE__{} = this, bindings) do
    case this.validity_period do
      :nil -> :nil
      {lv, rv} ->
        lv = case lv do
          :unbound -> :unbound
          {:relative, shift} -> Timex.shift(DateTime.utc_now(), shift)
          {:fixed, time} -> time
        end
        rv = case rv do
          :unbound -> :unbound
          {:relative, shift} -> Timex.shift(DateTime.utc_now(), shift)
          {:fixed, time} -> time
        end
        {lv, rv}
    end
  end

  #---------------------------
  # validate/4
  #---------------------------
  def validate(this, conn, context, options) do
    this = entity!(this)

    p_c = validate_period(this, options)
    a_c = validate_access_count(this)

    cond do
      p_c == :valid && a_c == :valid -> {:ok, this}
      true -> {:error, {{:period, p_c}, {:access_count, a_c}}}
    end
  end


  #---------------------------
  # validate_period/2
  #---------------------------
  def validate_period(this, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    case this.validity_period do
      nil -> :valid
      :unbound -> :valid
      {l_bound, r_bound} ->
          cond do
            l_bound != :unbound && DateTime.compare(current_time, l_bound) == :lt -> {:error, :lt_range}
            r_bound != :unbound && DateTime.compare(current_time, r_bound) == :gt -> {:error, :gt_range}
            true -> :valid
          end
    end
  end

  #---------------------------
  # access_count/1
  #---------------------------
  def access_count(%__MODULE__{} = this) do
    this.access_history.count
  end

  #---------------------------
  # validate_access_count/1
  #---------------------------
  def validate_access_count(%__MODULE__{} = this) do
    case this.extended_info do
      %{single_use: true} ->
        # confirm first valid check
        if access_count(this) == 0 do
          :valid
        else
          {:error, :single_use_exceeded}
        end

      %{multi_use: true, limit: limit} ->
        if access_count(this) < limit do
          :valid
        else
          {:error, :multi_use_exceeded}
        end
      %{unlimited_use: true} -> :valid
    end
  end

  #---------------------------
  # record_valid_access!/2
  #---------------------------
  def record_valid_access!(%__MODULE{} == this, conn) do
    ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    entry = %{time: DateTime.utc_now(), ip: ip,  type: :valid}
    record_access!(this, conn, entry)
  end

  #---------------------------
  # record_access!/3
  #---------------------------
  def record_access!(%__MODULE__{} = this, entry) when is_list(tokens) do
    this
    |> update_in([Access.key(:access_history), :count], &((&1 || 0) + 1))
    |> update_in([Access.key(:access_history), :history], &((&1 || []) ++ [entry]))
    |> Noizu.SmartToken.TokenRepo.update!(Noizu.ElixirCore.CallingContext.system())
  end

  #---------------------------
  # record_invalid_access/2
  #---------------------------
  def record_invalid_access!(tokens, conn) when is_list(tokens) do
    ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    entry = %{time: DateTime.utc_now(), ip: ip,  type: {:error, :check_mismatch}}
    # TODO deal with active flag if it needs to be changed. @PRI-2
    Enum.map(tokens, fn(token) ->
      record_access!(token, conn, entry)
    end)
  end

  def record_invalid_access!(%__MODULE{} == this, conn) do
    ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    entry = %{time: DateTime.utc_now(), ip: ip,  type: {:error, :check_mismatch}}
    record_access!(token, conn, entry)
  end

end