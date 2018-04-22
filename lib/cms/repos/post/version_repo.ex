#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.Post.VersionRepo do
  use Noizu.Scaffolding.RepoBehaviour,
      entity_module: Noizu.Cms.Post.VersionEntity,
      mnesia_table: Noizu.Cms.Database.Post.VersionTable,
      override: []
  require Logger
end