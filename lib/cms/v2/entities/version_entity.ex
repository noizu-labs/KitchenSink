#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersionEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: tuple,
               article: Noizu.KitchenSink.Types.entity_reference,
               parent: Noizu.KitchenSink.Types.entity_reference,
               created_on: DateTime.t,
               modified_on: DateTime.t,
               editor: Noizu.KitchenSink.Types.entity_reference,
               status: any,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    article: nil,
    parent: nil,
    created_on: nil,
    modified_on: nil,
    editor: nil,
    status: nil,
    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "cms-version-v2",
      mnesia_table: Noizu.Cms.V2.Database.VersionTable,
      as_record_options: %{
        additional_fields: [:editor, :status,  :created_on, :modified_on]
      }


  #------------
  #
  #------------
  def id(nil), do: nil
  def id({:ref, __MODULE__, identifier} = _ref), do: identifier
  def id(%{__struct__: __MODULE__, identifier: identifier}), do: identifier
  def id(%{entity: %{__struct__: __MODULE__, identifier: identifier}}), do: identifier
  def id({{:ref, _article_type, _article_id}, version_path} = ref) when is_tuple(version_path), do: ref
  def id("ref.cms-version-v2." <> ref), do: id(ref)
  def id(ref) when is_bitstring(ref) do
    case string_to_id(ref) do
      {:ok, v} -> v
      {:error, _} -> nil
      v -> v
    end
  end
  def id(_ref), do: nil

  #------------
  #
  #------------
  def string_to_id("ref.cms-version-v2." <> identifier), do: string_to_id(identifier)
  def string_to_id(identifier) do
    case Regex.match?(~r/^[(.*)]@([0-9\.])*$/, identifier) do
      [_,sref,version] ->
        if ref = Noizu.ERP.ref(sref) do
          version = Enum.split(version, ".") |> Enum.map(&(elem(Integer.parse(&1), 0))) |> List.to_tuple()
          {ref, version}
        else
          {:error, {:inner_ref, sref, identifier}}
        end
      _ -> {:error, {:format, identifier}}
    end
  end

  #------------
  #
  #------------
  def id_to_string({{:ref, _m, _i} = ref, path}) do
    sref = Noizu.ERP.sref(ref)
    path = Tuple.to_list(path) |> Enum.join(".")
    {:ok, "[#{sref}]@#{path}"}
  end

  def id_to_string(ref) do
    {:error, ref}
  end


  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule
