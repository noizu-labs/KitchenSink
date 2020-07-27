#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersionRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
        entity_module: Noizu.Cms.V2.VersionEntity,
        mnesia_table: Noizu.Cms.V2.Database.VersionTable

  alias Noizu.Cms.V2.VersionEntity

  def entity_versions(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    Noizu.Cms.V2.Database.VersionTable.match([identifier: {ref, :_}])
    |> Amnesia.Selection.values()
    |> Enum.map(&(&1.entity))
  end

  def change_set(entity, options) do
    Enum.reduce(options, entity, fn({k, v}, acc) ->
      put_in(acc, [Access.key(k)], v)
    end)
  end


  def new(options) do
    %VersionEntity{
      identifier: options[:identifier],
      article: options[:article],
      parent: options[:parent],
      created_on: options[:created_on],
      modified_on: options[:modified_on],
      editor: options[:editor],
      status: options[:status],
    }
  end

  def is_version({:version, {_i, _v}}), do: true
  def is_version(_), do: false
end
