#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.ArticleEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: integer,
               article_info: Noizu.Cms.V2.Article.Info.t | nil,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    article_info: nil,
    meta: nil,
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  # use Noizu.Scaffolding.V2.EntityBehaviour
  use Noizu.Cms.V2.EntityBehaviour,
      sref_module: "cms-entry",
      entity_table: Noizu.Cms.V2.Database.ArticleTable,
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

  def is_cms_entity?(_, _context, _options), do: true
  def is_cms_entity!(_, _context, _options), do: true

  def is_versioning_record?({:ref, __MODULE__, {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_versioning_record?({:ref, __MODULE__, {:version, {_identifier, _version}}}, _context, _options), do: true
  def is_versioning_record?(%__MODULE__{identifier: {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_versioning_record?(%__MODULE__{identifier: {:version, {_identifier, _version}}}, _context, _options), do: true
  def is_versioning_record?(_, _context, _options), do: false

  def is_versioning_record!({:ref, __MODULE__, {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_versioning_record!({:ref, __MODULE__, {:version, {_identifier, _version}}}, _context, _options), do: true
  def is_versioning_record!(%__MODULE__{identifier: {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_versioning_record!(%__MODULE__{identifier: {:version, {_identifier, _version}}}, _context, _options), do: true
  def is_versioning_record!(_, _context, _options), do: false

  def is_revision_record?({:ref, __MODULE__, {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_revision_record?(%__MODULE__{identifier: {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_revision_record?(_, _context, _options), do: false


  def is_revision_record!({:ref, __MODULE__, {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_revision_record!(%__MODULE__{identifier: {:revision, {_identifier, _version, _revision}}}, _context, _options), do: true
  def is_revision_record!(_, _context, _options), do: false

end # end defmodule




#=====================================================
#
#=====================================================
defimpl Noizu.Cms.V2.Proto, for: [ Noizu.Cms.V2.ArticleEntity, Noizu.Cms.V2.Article.FileEntity, Noizu.Cms.V2.Article.ImageEntity, Noizu.Cms.V2.Article.PostEntity] do
  @provider Application.get_env(:noizu_cms, :cms_proto_provider, Noizu.Cms.V2.ProtoProvider)

  def tags(ref, context, options), do: @provider.tags(ref, context, options)
  def tags!(ref, context, options), do: @provider.tags!(ref, context, options)

  def type(ref, context, options), do: @provider.type(ref, context, options)
  def type!(ref, context, options), do: @provider.type!(ref, context, options)

  def is_cms_entity?(ref, context, options), do: @provider.is_cms_entity?(ref, context, options)
  def is_cms_entity!(ref, context, options), do: @provider.is_cms_entity!(ref, context, options)

  def is_versioning_record?(ref, context, options), do: @provider.is_versioning_record?(ref, context, options)
  def is_versioning_record!(ref, context, options), do: @provider.is_versioning_record!(ref, context, options)

  def is_revision_record?(ref, context, options), do: @provider.is_revision_record?(ref, context, options)
  def is_revision_record!(ref, context, options), do: @provider.is_revision_record!(ref, context, options)

  def versioned_identifier(ref, context, options), do: @provider.versioned_identifier(ref, context, options)
  def versioned_identifier!(ref, context, options), do: @provider.versioned_identifier!(ref, context, options)

  def article_identifier(ref, context, options), do: @provider.article_identifier(ref, context, options)
  def article_identifier!(ref, context, options), do: @provider.article_identifier!(ref, context, options)

  def versioned_ref(ref, context, options), do: @provider.versioned_ref(ref, context, options)
  def versioned_ref!(ref, context, options), do: @provider.versioned_ref!(ref, context, options)

  def article_ref(ref, context, options), do: @provider.article_ref(ref, context, options)
  def article_ref!(ref, context, options), do: @provider.article_ref!(ref, context, options)

  def compress_archive(ref, context, options), do: @provider.compress_archive(ref, context, options)
  def compress_archive!(ref, context, options), do: @provider.compress_archive!(ref, context, options)

  def get_article(ref, context, options), do: @provider.get_article(ref, context, options)
  def get_article!(ref, context, options), do: @provider.get_article!(ref, context, options)

  def set_version(ref, version, context, options), do: @provider.set_version(ref, version, context, options)
  def set_version!(ref, version, context, options), do: @provider.set_version!(ref, version, context, options)

  def get_version(ref, context, options), do: @provider.get_version(ref, context, options)
  def get_version!(ref, context, options), do: @provider.get_version!(ref, context, options)

  def set_revision(ref, revision, context, options), do: @provider.set_revision(ref, revision, context, options)
  def set_revision!(ref, revision, context, options), do: @provider.set_revision!(ref, revision, context, options)

  def get_revision(ref, context, options), do: @provider.get_revision(ref, context, options)
  def get_revision!(ref, context, options), do: @provider.get_revision!(ref, context, options)

  def set_parent(ref, version, context, options), do: @provider.set_parent(ref, version, context, options)
  def set_parent!(ref, version, context, options), do: @provider.set_parent!(ref, version, context, options)

  def get_parent(ref, context, options), do: @provider.get_parent(ref, context, options)
  def get_parent!(ref, context, options), do: @provider.get_parent!(ref, context, options)

  def get_article_info(ref, context, options), do: @provider.get_article_info(ref, context, options)
  def get_article_info!(ref, context, options), do: @provider.get_article_info!(ref, context, options)

  def init_article_info(ref, context, options), do: @provider.init_article_info(ref, context, options)
  def init_article_info!(ref, context, options), do: @provider.init_article_info!(ref, context, options)

  def update_article_info(ref, context, options), do: @provider.update_article_info(ref, context, options)
  def update_article_info!(ref, context, options), do: @provider.update_article_info!(ref, context, options)

  def set_article_info(ref, article_info, context, options), do: @provider.set_article_info(ref, article_info, context, options)
  def set_article_info!(ref, article_info, context, options), do: @provider.set_article_info!(ref, article_info, context, options)
end


