#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Version.RevisionEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: tuple,
               article: Noizu.KitchenSink.Types.entity_reference,
               version: Noizu.KitchenSink.Types.entity_reference,
               created_on: DateTime.t,
               modified_on: DateTime.t,
               editor: Noizu.KitchenSink.Types.entity_reference,
               status: any,
               archive_type: atom,
               archive: any,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    article: nil,
    version: nil,
    created_on: nil,
    modified_on: nil,
    editor: nil,
    status: nil,
    archive_type: nil,
    archive: nil,
    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "cms-revision-v2",
      mnesia_table: Noizu.Cms.V2.Database.Version.RevisionTable,
      as_record_options: %{
        additional_fields: [:editor, :status,  :created_on, :modified_on]
      }

  #------------
  #
  #------------
  def id(nil), do: nil
  def id({:ref, __MODULE__, identifier} = _ref), do: identifier
  def id(%{__struct__: __MODULE__, identifier: identifier}), do: identifier
  def id(%{entity: %{__struct__: __MODULE__, identifier: identifier}}), do: identifier
  def id({{:ref, Noizu.Cms.V2.VersionEntity, _version}, _id} = ref), do: ref
  def id("ref.cms-revision-v2." <> ref), do: id(ref)
  def id(ref) when is_bitstring(ref) do
    case string_to_id(ref) do
      {:ok, v} -> v
      {:error, _} -> nil
      v -> v
    end
  end
  def id(_ref), do: nil

  #------------
  #
  #------------
  def string_to_id(_identifier) do
    {:ok, :wip}
  end

  #------------
  #
  #------------
  def id_to_string(_identifier) do
    {:ok, "wip"}
  end

  def is_cms_entity?(_, _context, _options), do: false
  def is_cms_entity!(_, _context, _options), do: false

  def is_versioning_record?(_, _context, _options), do: true
  def is_versioning_record!(_, _context, _options), do: true

  def is_revision_record?(_, _context, _options), do: true
  def is_revision_record?(_, _context, _options), do: true

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule


#=====================================================
#
#=====================================================
defimpl Noizu.Cms.V2.Proto, for: [Noizu.Cms.V2.Version.RevisionEntity] do
  #----------------------
  #
  #----------------------
  def tags(ref, _context, _options), do: ref.article_info.tags
  def tags!(ref, _context, _options), do: ref.article_info.tags

  #----------------------
  #
  #----------------------
  def type(ref, _context, _options), do: ref.article_info.type
  def type!(ref, _context, _options), do: ref.article_info.type

  #----------------------
  #
  #----------------------
  def is_cms_entity?(_ref, _context, _options), do: false
  def is_cms_entity!(_ref, _context, _options), do: false

  #----------------------
  #
  #----------------------
  def is_versioning_record?(_ref, _context, _options), do: true
  def is_versioning_record!(_ref, _context, _options), do: true

  #----------------------
  #
  #----------------------
  def is_revision_record?(_ref, _context, _options), do: true
  def is_revision_record!(_ref, _context, _options), do: true
  #----------------------
  #
  #----------------------
  def versioned_identifier(_ref, _context, _options), do: throw :not_supported
  def versioned_identifier!(_ref, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def article_identifier(_ref, _context, _options), do: throw :not_supported
  def article_identifier!(_ref, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def versioned_ref(_ref, _context, _options), do: throw :not_supported
  def versioned_ref!(_ref, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def article_ref(_ref, _context, _options), do: throw :not_supported
  def article_ref!(_ref, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_article(ref, _context, _options), do: ref.article
  def get_article!(ref, _context, _options), do: ref.article

  #----------------------
  #
  #----------------------
  def compress_archive(ref, _context, _options) do
    {ref.full_copy, ref.record}
  end

  def compress_archive!(ref, _context, _options) do
    {ref.full_copy, ref.record}
  end

  #----------------------
  #
  #----------------------
  def set_version(_ref, _version, _context, _options), do: throw :not_supported
  def set_version!(_ref, _version, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_version(ref, _context, _options), do: ref.version
  def get_version!(ref, _context, _options), do: ref.version

  #----------------------
  #
  #----------------------
  def set_revision(_ref, _revision, _context, _options), do: throw :not_supported
  def set_revision!(_ref, _revision, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_revision(ref, _context, _options), do: ref
  def get_revision!(ref, _context, _options), do: ref

  #----------------------
  #
  #----------------------
  def set_parent(_ref, _version, _context, _options), do: throw :not_supported
  def set_parent!(_ref, _version, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_parent(ref, _context, _options), do: ref.parent
  def get_parent!(ref, _context, _options), do: ref.parent


  #----------------------
  #
  #----------------------
  def get_article_info(_ref, _context, _options), do: throw :not_supported
  def get_article_info!(_ref, _context, _options), do: throw :not_supported


  #--------------------------------
  # @init_article_info
  #--------------------------------
  def init_article_info(ref, context, options), do: throw :not_supported
  def init_article_info!(ref, context, options), do: throw :not_supported

  #--------------------------------
  # @update_article_info
  #--------------------------------
  def update_article_info(ref, context, options), do: throw :not_supported
  def update_article_info!(ref, context, options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def set_article_info(_ref, _article_info, _context, _options), do: throw :not_supported
  def set_article_info!(_ref, _article_info, _context, _options), do: throw :not_supported
end
