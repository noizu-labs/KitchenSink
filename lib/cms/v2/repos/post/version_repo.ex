#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Post.VersionRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
      entity_module: Noizu.Cms.V2.Post.VersionEntity,
      mnesia_table: Noizu.Cms.V2.Database.Post.VersionTable,
      override: []
  require Logger
end