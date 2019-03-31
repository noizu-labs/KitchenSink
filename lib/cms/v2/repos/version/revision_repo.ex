#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Version.RevisionRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
        entity_module: Noizu.Cms.V2.Version.RevisionEntity,
        mnesia_table: Noizu.Cms.V2.Database.Version.RevisionTable

  def entity_revisions(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    Noizu.Cms.V2.Database.Version.RevisionTable.match([identifier: {{:ref, Noizu.Cms.V2.VersionEntity, {ref, :_}}, :_}])
    |> Amnesia.Selection.values()
    |> Enum.map(&(&1.entity))
  end

end