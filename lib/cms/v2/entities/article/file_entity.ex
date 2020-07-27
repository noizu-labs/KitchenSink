#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Article.FileEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: integer,

               title: Noizu.MarkdownField.t | nil,
               alt: Noizu.MarkdownField.t | nil,
               file: String.t | nil,
               attributes: Map.t,
               article_info: Noizu.Cms.V2.Article.Info.t | nil,

               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,

    title: nil,
    alt: nil,
    file: nil,
    attributes: %{},
    article_info: nil,

    meta: %{},

    vsn: @vsn
  ]

  #use Noizu.Scaffolding.V2.EntityBehaviour,
  use Noizu.Cms.V2.EntityBehaviour,
      poly_base: Noizu.Cms.V2.ArticleEntity,
      cms_base: Noizu.Cms.V2.ArticleEntity
  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

  def cms_type(), do: :file

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
