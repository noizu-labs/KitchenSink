#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Queue.EventRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
      mnesia_table: Noizu.EmailService.Database.Email.Queue.EventTable

  require Logger

end