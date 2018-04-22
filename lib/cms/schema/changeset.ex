#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.ChangeSet do
  alias Noizu.MnesiaVersioning.ChangeSet
  use Amnesia
  use Noizu.Cms.Database
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
        changeset:  "Cms Schema",
        author: "Keith Brings",
        note: "You may specify your own tables and override persistence layer in the settings. ",
        environments: [],
        update: fn() ->
                  neighbors = neighbors()
                  create_table(Noizu.Cms.Database.PostTable, [disk: neighbors])
                  create_table(Noizu.Cms.Database.Post.TagTable, [disk: neighbors])
                  create_table(Noizu.Cms.Database.Post.VersionTable, [disk: neighbors])
                  create_table(Noizu.Cms.Database.Post.VersionHistoryTable, [disk: neighbors])
                  :success
        end,
        rollback: fn() ->
          destroy_table(Noizu.Cms.Database.PostTable)
          destroy_table(Noizu.Cms.Database.Post.TagTable)
          destroy_table(Noizu.Cms.Database.Post.VersionTable)
          destroy_table(Noizu.Cms.Database.Post.VersionHistoryTable)
          :removed
        end
      }
    ]
  end
end