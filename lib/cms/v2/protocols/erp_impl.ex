#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

#Article Entities
defimpl Noizu.ERP, for: [
                     Noizu.Cms.V2.ArticleEntity, Noizu.Cms.V2.Database.ArticleTable, Noizu.Cms.V2.Article.FileEntity, Noizu.Cms.V2.Article.ImageEntity, Noizu.Cms.V2.Article.PostEntity,
                     Noizu.Cms.V2.VersionEntity,  Noizu.Cms.V2.Database.VersionTable
] do
  defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
end
