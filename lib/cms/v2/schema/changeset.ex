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
                  create_table(Noizu.Cms.V2.Database.EntryTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.Entry.TagTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.Entry.VersionTable, [disk: neighbors])
                  create_table(Noizu.Cms.V2.Database.Entry.VersionHistoryTable, [disk: neighbors])
                  :success
        end,
        rollback: fn() ->
          destroy_table(Noizu.Cms.V2.Database.ArticleTable)
          destroy_table(Noizu.Cms.V2.Database.EntryTable)
          destroy_table(Noizu.Cms.V2.Database.Entry.TagTable)
          destroy_table(Noizu.Cms.V2.Database.Entry.VersionTable)
          destroy_table(Noizu.Cms.V2.Database.Entry.VersionHistoryTable)
          :removed
        end
      }
    ]
  end
end