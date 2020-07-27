#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.ChangeSet do
  alias Noizu.MnesiaVersioning.ChangeSet
  use Amnesia
  use Noizu.Cms.V2.Database
  use Noizu.MnesiaVersioning.SchemaBehaviour

  def neighbors() do
    topology_provider = Application.get_env(:noizu_mnesia_versioning, :topology_provider)
    {:ok, nodes} = topology_provider.mnesia_nodes();
    nodes
  end
  #-----------------------------------------------------------------------------
  # ChangeSets
  #-----------------------------------------------------------------------------
  def change_sets do
    [
      %ChangeSet{
        changeset:  "Cms V2 Schema",
        author: "Keith Brings",
        note: "",
        environments: :all,
        update: fn() ->
                  neighbors = neighbors()
                  create_table(Noizu.Cms.V2.Database.ArticleTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.IndexTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.TagTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.VersionSequencerTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.VersionTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.Version.RevisionTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.Version.ActiveRevisionTable, [disk: neighbors])
                  :success
        end,
        rollback: fn() ->
          destroy_table(Noizu.Cms.V2.Database.ArticleTable)
          destroy_table(Noizu.Cms.V2.Database.IndexTable)
          destroy_table(Noizu.Cms.V2.Database.TagTable)
          destroy_table(Noizu.Cms.V2.Database.VersionSequencerTable)
          destroy_table(Noizu.Cms.V2.Database.VersionTable)
          destroy_table(Noizu.Cms.V2.Database.Version.RevisionTable)
          destroy_table(Noizu.Cms.V2.Database.Version.ActiveRevisionTable)
          :removed
        end
      }
    ]
  end
end
