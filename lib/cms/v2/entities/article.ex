#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.ArticleEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: integer,
               vsn: float
             }

  defstruct [
    identifier: nil,
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "cms-v2",
      mnesia_table: Noizu.Cms.V2.Database.ArticleTable,
      poly_support: [
        Noizu.Cms.V2.Article.FileEntity,
        Noizu.Cms.V2.Article.ImageEntity,
        Noizu.Cms.V2.Article.PostEntity,
      ]

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule