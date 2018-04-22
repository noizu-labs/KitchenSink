#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.KitchenSink.Support.UserRepo do
  use Noizu.Scaffolding.RepoBehaviour,
      entity_module: Noizu.KitchenSink.Support.UserEntity,
      mnesia_table: Noizu.KitchenSink.Database.Support.UserTable,
      override: []
  require Logger
end