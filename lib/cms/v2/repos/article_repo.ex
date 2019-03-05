#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.ArticleRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
      entity_module: Noizu.Cms.V2.ArticleEntity,
      entity_table: Noizu.Cms.V2.Database.ArticleTable
  use Noizu.Cms.V2.RepoBehaviour

end