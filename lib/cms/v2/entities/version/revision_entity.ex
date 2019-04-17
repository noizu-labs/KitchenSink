#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Version.RevisionEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: tuple,
               article: Noizu.KitchenSink.Types.entity_reference,
               version: Noizu.KitchenSink.Types.entity_reference,
               created_on: DateTime.t,
               modified_on: DateTime.t,
               editor: Noizu.KitchenSink.Types.entity_reference,
               status: any,
               archive_type: atom,
               archive: any,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    article: nil,
    version: nil,
    created_on: nil,
    modified_on: nil,
    editor: nil,
    status: nil,
    archive_type: nil,
    archive: nil,
    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "cms-revision-v2",
      mnesia_table: Noizu.Cms.V2.Database.Version.RevisionTable


  #------------
  #
  #------------
  def id(nil), do: nil
  def id({:ref, __MODULE__, identifier} = _ref), do: identifier
  def id(%{__struct__: __MODULE__, identifier: identifier}), do: identifier
  def id(%{entity: %{__struct__: __MODULE__, identifier: identifier}}), do: identifier
  def id({{:ref, Noizu.Cms.V2.VersionEntity, _version}, _id} = ref), do: ref
  def id("ref.cms-revision-v2." <> ref), do: id(ref)
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
  def string_to_id(identifier) do
    {:ok, :wip}
  end

  #------------
  #
  #------------
  def id_to_string(identifier) do
    {:ok, "wip"}
  end

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule