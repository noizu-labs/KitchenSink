#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.TemplateRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
      mnesia_table: Noizu.EmailService.Database.Email.TemplateTable

  require Logger

end