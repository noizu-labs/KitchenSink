#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersionRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
        entity_module: Noizu.Cms.V2.VersionEntity,
        mnesia_table: Noizu.Cms.V2.Database.VersionTable

  def entity_versions(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    Noizu.Cms.V2.Database.VersionTable.match([identifier: {ref, :_}])
    |> Amnesia.Selection.values()
    |> Enum.map(&(&1.entity))
  end
end