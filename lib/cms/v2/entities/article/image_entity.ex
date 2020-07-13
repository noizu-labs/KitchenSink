#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Article.ImageEntity do
  @vsn 1.0
  alias Noizu.Cms.V2.Article.Image.Resolution
  @type resolution :: String.t | atom
  @type t :: %__MODULE__{
               identifier: integer,

               title: Noizu.MarkdownField.t | nil,
               alt: Noizu.MarkdownField.t | nil,
               resolution: %{resolution => Resolution.t},  # Map.t, # %{mobile: %Image.Resolution{resolution: {w,h}, file: String.t, dpi: integer}}
               attributes: Map.t,
               article_info: Noizu.Cms.V2.Article.Info.t | nil,

               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,

    title: nil,
    alt: nil,
    resolution: %{},
    attributes: %{},
    article_info: nil,

    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Scaffolding.V2.EntityBehaviour,
      poly_base: Noizu.Cms.V2.ArticleEntity
  use Noizu.Cms.V2.EntityBehaviour,
      cms_base: Noizu.Cms.V2.ArticleEntity
  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule
