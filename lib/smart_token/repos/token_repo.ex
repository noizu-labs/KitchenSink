#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SmartToken.TokenRepo do
  use Noizu.Scaffolding.RepoBehaviour,
      mnesia_table: Noizu.SmartToken.Database.TokenTable,
      override: []
  require Logger

  @vsn 1.0

  # Time Periods
  @period_three_days {:unbound, {:relative, [{:days, 3}]}}
  @period_fifteen_days {:unbound, {:relative, [{:days, 15}]}}

  @default_settings %{
    type: :generic,
    token: :generate,
    resource: {:bind, :recipient},
    state: :enabled,
    owner: :system,
    validity_period: :nil,
    permissions: :unrestricted,
    extended_info: :nil,
    scope: :nil,
    context: {:bind, :recipient}
  }


  #-------------------------------------
  # new/2
  #-------------------------------------
  def new(settings) do
    settings = Map.merge(@default_settings, settings)
    %Noizu.SmartToken.TokenEntity{
      type: settings.type,
      token: settings.token,
      resource: settings.resource,
      scope: settings.scope,
      state: settings.state,
      context: settings.context,
      owner: settings.owner,
      validity_period: settings.validity_period,
      permissions: settings.permissions,
      extended_info: settings.extended_info,
      vsn: @vsn
    }
  end

  #-------------------------------------
  # account_verification_token/1
  #-------------------------------------
  def account_verification_token(options \\ %{}) do
    defaults = %{
                 resource: {:bind, :recipient},
                 context: {:bind, :recipient},
                 scope: {:account_info, :verification},
                 validity_period: @period_three_days,
                 extended_info: %{single_use: true}
               }
               |> Map.merge(options)
               |> put_in([:type], :account_verification)
               |> new()
  end

  #-------------------------------------
  # edit_resource_token/3
  #-------------------------------------
  def edit_resource_token(resource, scope, options) do
    defaults = %{
                 context: {:bind, :recipient},
                 validity_period: @period_fifteen_days,
                 extended_info: %{multi_use: true, limit: 25}
               }
               |> Map.merge(options)
               |> Map.merge(%{resource: resource, scope: scope, type: :edit_resource})
               |> new()
  end

  #-------------------------------------
  # authorize!/3
  #-------------------------------------
  def authorize!(token_key, conn, context, options \\ %{}) do
    # 1. Base 64 Decode
    # 2. Check for Token,
    # 3. If no match check for partial matches and log invalid attempt on any partial match, and for user.
    # 4. If match verify constraints are met. (Time Range, Access Attempts, etc.)
    # 5. If constraints failed return error status
    # 6. If constraints match return success status.

    case Base.decode64(token_key) do
      {:ok, value} ->
        {l,r} = Enum.split(:erlang.binary_to_list(value), 16)
        cond do
          length(l) == 16 && length(r) == 16 ->
            l_extract = UUID.binary_to_string!(:erlang.list_to_binary(l))
            r_extract = UUID.binary_to_string!(:erlang.list_to_binary(r))
            match = [{:active, true}, {:token, {l_extract, r_extract}}]
            # @TODO dynamic database selection.
            case Noizu.SmartToken.Database.TokenTable.match!(match) |> Amnesia.Selection.values do
              [] ->
                flag_invalid_attempt({l_extract, r_extract}, conn, context, options)
                {:error, :invalid}
              [r] -> Noizu.SmartToken.TokenEntity.validate(r, conn, context, options)
              m when is_list(m) ->
                case validate(m, conn, context, options) do
                  {:ok, token} ->
                      update = Noizu.SmartToken.TokenEntity.record_valid_access!(token, conn)
                      {:ok, update}
                    {:error, reason} ->
                      Noizu.SmartToken.TokenEntity.record_invalid_access!(m, conn)
                      {:error, reason}
                end
              _ -> {:error, :other}
            end
          true -> {:error, :encoding}
        end
      _ -> {:error, :base64}
    end
  end

  #-------------------------------------
  # flag_invalid_attempt/4
  #-------------------------------------
  def flag_invalid_attempt({l_extract, r_extract}, conn, context, options) do
    # @TODO check for partial hit. and record malformed request for user.
    # @PRI-1
    :ok
  end

  #-------------------------------------
  # validate/4
  #-------------------------------------
  def validate(nil, conn, context, options) do
    {:error, :invalid}
  end

  def validate([], conn, context, options) do
    {:error, :invalid}
  end

  def validate([h|t], conn, context, options) do
    case Noizu.SmartToken.TokenEntity.validate(h, conn, context, options) do
      {:ok, v} -> {:ok, v}
      _ -> validate(t, conn, context, options)
    end
  end

  #-------------------------------------
  # bind!/2
  #-------------------------------------
  def bind!(%Noizu.SmartToken.TokenEntity{} = token, bindings, context, options \\ %{}) do
    token
    |> Noizu.SmartToken.TokenEntity.bind(bindings)
    |> create!(context, options)
  end
end