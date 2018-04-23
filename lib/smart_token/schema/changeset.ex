#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.SmartToken.ChangeSet do
  alias Noizu.MnesiaVersioning.ChangeSet
  use Amnesia
  use Noizu.SmartToken.Database
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
        changeset:  "SmartToken Related Schema",
        author: "Keith Brings",
        note: "You may specify your own tables and override persistence layer in the settings. ",
        environments: :all,
        update: fn() ->
                  neighbors = neighbors()
                  create_table(Noizu.SmartToken.Database.TokenTable, [disk: neighbors])
                  :success
        end,
        rollback: fn() ->
          destroy_table(Noizu.SmartToken.Database.TokenTable)
          :removed
        end
      }
    ]
  end
end