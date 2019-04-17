#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

# @todo - active version check in version provider when updating revisions/versions.
# @todo - update test suite.

defprotocol Noizu.Cms.V2.Proto do
  @fallback_to_any false

  def tags(ref, context, options)
  def tags!(ref, context, options)

  def type(ref, context, options)
  def type!(ref, context, options)

  def cms_provider(ref, context, options)
  def cms_provider!(ref, context, options)

  def is_versioning_record?(ref, context, options)
  def is_versioning_record!(ref, context, options)

  def versioned_identifier(ref, context, options)
  def versioned_identifier!(ref, context, options)

  def article_identifier(ref, context, options)
  def article_identifier!(ref, context, options)

  def versioned_ref(ref, context, options)
  def versioned_ref!(ref, context, options)

  def article_ref(ref, context, options)
  def article_ref!(ref, context, options)

  def get_article(ref, context, options)
  def get_article!(ref, context, options)

  def compress_archive(ref, context, options)
  def compress_archive!(ref, context, options)

  def set_version(ref, version, context, options)
  def set_version!(ref, version, context, options)

  def get_version(ref, context, options)
  def get_version!(ref, context, options)

  def set_revision(ref, revision, context, options)
  def set_revision!(ref, revision, context, options)

  def get_revision(ref, context, options)
  def get_revision!(ref, context, options)

  def set_parent(ref, version, context, options)
  def set_parent!(ref, version, context, options)

  def get_parent(ref, context, options)
  def get_parent!(ref, context, options)

  def get_article_info(ref, context, options)
  def get_article_info!(ref, context, options)

  def set_article_info(ref, article_info, context, options)
  def set_article_info!(ref, article_info, context, options)
end # end defprotocol

#=====================================================
#
#=====================================================
defimpl Noizu.Cms.V2.Proto, for: [Tuple, BitString] do
  #----------------------
  #
  #----------------------
  def tags(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.tags(entity, context, options)
    end
  end

  def tags!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.tags!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def type(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.type(entity, context, options)
    end
  end

  def type!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.type!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def cms_provider(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.cms_provider(entity, context, options)
    end
  end

  def cms_provider!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.cms_provider!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def is_versioning_record?(ref, context, options) do
    case ref do
      {:ref, Noizu.Cms.V2.VersionEntity, _} -> true
      {:ref, Noizu.Cms.V2.Version.RevisionEntity, _} -> true
      {:ref, _module, {:revision, {_identifier, _version, _revision}}} -> true
      {:ref, _module, {:version, {_identifier, _version}}} -> true
      _ ->
        if (entity = Noizu.ERP.entity(ref)) do
          Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)
        else
          {:error, :unknown_entity}
        end
    end
  end

  def is_versioning_record!(ref, context, options) do
    case ref do
      {:ref, Noizu.Cms.V2.VersionEntity, _} -> true
      {:ref, Noizu.Cms.V2.Version.RevisionEntity, _} -> true
      {:ref, _module, {:revision, {_identifier, _version, _revision}}} -> true
      {:ref, _module, {:version, {_identifier, _version}}} -> true
      _ ->
        if (entity = Noizu.ERP.entity!(ref)) do
          Noizu.Cms.V2.Proto.is_versioning_record!(entity, context, options)
        else
          {:error, :unknown_entity}
        end
    end
  end

  #----------------------
  #
  #----------------------
  def versioned_identifier(ref, context, options) do
    case ref do
      {:ref, _module, {:revision, {_identifier, _version, _revision}} = v_id} -> v_id
      _ ->
        if (entity = Noizu.ERP.entity(ref)) do
          Noizu.Cms.V2.Proto.versioned_identifier(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end

  def versioned_identifier!(ref, context, options) do
    case ref do
      {:ref, _module, {:revision, {_identifier, _version, _revision}} = v_id} -> v_id
      _ ->
        if (entity = Noizu.ERP.entity!(ref)) do
          Noizu.Cms.V2.Proto.versioned_identifier!(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end

  def article_identifier(ref, context, options) do
    case ref do
      {:ref, _module, {:revision, {identifier, _version, _revision}}} -> identifier
      _ ->
        if (entity = Noizu.ERP.entity(ref)) do
          Noizu.Cms.V2.Proto.article_identifier(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end

  def article_identifier!(ref, context, options) do
    case ref do
      {:ref, _module, {:revision, {identifier, _version, _revision}}} -> identifier
      _ ->
        if (entity = Noizu.ERP.entity!(ref)) do
          Noizu.Cms.V2.Proto.article_identifier!(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end


  def versioned_ref(ref, context, options) do
    case ref do
      v_ref = {:ref, _module, {:revision, {_identifier, _version, _revision}}} -> v_ref
      _ ->
        if (entity = Noizu.ERP.entity(ref)) do
          Noizu.Cms.V2.Proto.versioned_ref(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end
  def versioned_ref!(ref, context, options) do
    case ref do
      v_ref = {:ref, _module, {:revision, {_identifier, _version, _revision}}} -> v_ref
      _ ->
        if (entity = Noizu.ERP.entity!(ref)) do
          Noizu.Cms.V2.Proto.versioned_ref!(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end

  def article_ref(ref, context, options) do
    case ref do
      v_ref = {:ref, m, {:revision, {identifier, _version, _revision}}} -> {:ref, m, identifier}
      {:ref, _m, _id} -> ref
      _ ->
        if (entity = Noizu.ERP.entity(ref)) do
          Noizu.Cms.V2.Proto.article_ref(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end

  def article_ref!(ref, context, options) do
    case ref do
      {:ref, m, {:revision, {identifier, _version, _revision}}} -> {:ref, m, identifier}
      {:ref, _m, _id} -> ref
      _ ->
        if (entity = Noizu.ERP.entity!(ref)) do
          Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
        else
          throw "Invalid Entity"
        end
    end
  end


  #----------------------
  #
  #----------------------
  def compress_archive(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.compress_archive(entity, context, options)
    end
  end


  def compress_archive!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.compress_archive!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_article(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_article(entity, context, options)
    end
  end

  def get_article!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_article!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def set_version(ref, version, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_version(entity, version, context, options)
    end
  end

  def set_version!(ref, version, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_version!(entity, version, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_version(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_version(entity, context, options)
    end
  end

  def get_version!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_version!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def set_revision(ref, revision, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_revision(entity, revision, context, options)
    end
  end

  def set_revision!(ref, revision, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_revision!(entity, revision, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_revision(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_revision(entity, context, options)
    end
  end

  def get_revision!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_revision!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def set_parent(ref, version, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_parent(entity, version, context, options)
    end
  end

  def set_parent!(ref, version, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_parent!(entity, version, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_parent(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_parent(entity, context, options)
    end
  end

  def get_parent!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_parent!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_article_info(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
    end
  end

  def get_article_info!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_article_info!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def set_article_info(ref, article_info, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_article_info(entity, article_info, context, options)
    end
  end


  def set_article_info!(ref, article_info, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_article_info!(entity, article_info, context, options)
    end
  end
end


#=====================================================
#
#=====================================================
defimpl Noizu.Cms.V2.Proto, for: [Noizu.Cms.V2.Article.FileEntity, Noizu.Cms.V2.Article.ImageEntity, Noizu.Cms.V2.Article.PostEntity] do

  #----------------------
  #
  #----------------------
  def tags(ref, _context, _options) do
    ref.article_info.tags
  end

  def tags!(ref, context, options) do
    tags(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def type(ref, _context, _options) do
    case ref.__struct__ do
      Noizu.Cms.V2.Article.FileEntity -> :file
      Noizu.Cms.V2.Article.ImageEntity -> :image
      Noizu.Cms.V2.Article.PostEntity -> :post
    end
  end

  def type!(ref, context, options) do
    type(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def cms_provider(ref, _context, _options) do
    ref.__struct__.cms_provider()
  end

  def cms_provider!(ref, _context, _options) do
    ref.__struct__.cms_provider()
  end

  #----------------------
  #
  #----------------------
  def is_versioning_record?(ref, context, options) do
    case ref.identifier do
      {:revision, {_identifier, _version, _revision}} -> true
      _ -> false
    end
  end

  def is_versioning_record!(ref, context, options) do
    case ref.identifier do
      {:revision, {_identifier, _version, _revision}} -> true
      _ -> false
    end
  end


  #----------------------
  #
  #----------------------
  def versioned_identifier(ref, context, options) do
    if ref.article_info && ref.article_info.revision do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:ref, _, {{:ref, _v, {_article, version_path}}, revision_number}} = Noizu.ERP.ref(ref.article_info.revision)
      case ref.identifier do
        # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
        {:revision, {identifier, _version, _revision}} -> {:revision, {identifier, version_path, revision_number}}
        identifier -> {:revision, {identifier, version_path, revision_number}}
      end
    end
  end

  def versioned_identifier!(ref, context, options) do
    versioned_identifier(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def article_identifier(ref, context, options) do
    case ref.identifier do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:revision, {identifier, _version, _revision}} -> identifier
      identifier -> identifier
    end
  end
  def article_identifier!(ref, context, options) do
    article_identifier(ref, context, options)
  end

  def versioned_ref(ref, context, options) do
    if ref.article_info && ref.article_info.revision do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:ref, _, {{:ref, _v, {{:ref, _a, identifier}, version_path}}, revision_number}} = Noizu.ERP.ref(ref.article_info.revision)
      Noizu.ERP.ref(%{ref| identifier: {:revision, {identifier, version_path, revision_number}}})
    end
  end

  def versioned_ref!(ref, context, options) do
    versioned_ref(ref, context, options)
  end

  def article_ref(ref, context, options) do
    case ref.identifier do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:revision, {identifier, _version, _revision}} -> Noizu.ERP.ref(%{ref| identifier: identifier})
      identifier -> Noizu.ERP.ref(ref)
    end
  end

  def article_ref!(ref, context, options) do
    article_ref(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def compress_archive(ref, context, options) do
    {:ref, Noizu.Cms.V2.Proto.versioned_ref(ref, context, options)}
  end

  def compress_archive!(ref, context, options) do
    {:ref, Noizu.Cms.V2.Proto.versioned_ref!(ref, context, options)}
  end

  #----------------------
  #
  #----------------------
  def get_article(ref, context, options), do: ref

  def get_article!(ref, context, options), do: ref

  #----------------------
  #
  #----------------------
  def set_version(ref, version, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:version)], Noizu.Cms.V2.VersionEntity.ref(version))
  end

  def set_version!(ref, version, context, options) do
    set_version(ref, version, context, options)
  end

  #----------------------
  #
  #----------------------
  def get_version(ref, _context, _options) do
    ref.article_info && ref.article_info.version
  end

  def get_version!(ref, context, options) do
    get_version(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def set_revision(ref, revision, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:revision)], Noizu.Cms.V2.Version.RevisionEntity.ref(revision))
  end

  def set_revision!(ref, revision, context, options) do
    set_revision(ref, revision, context, options)
  end

  #----------------------
  #
  #----------------------
  def get_revision(ref, _context, _options) do
    ref.article_info && ref.article_info.revision
  end

  def get_revision!(ref, context, options) do
    get_revision(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def set_parent(ref, version, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:parent)], Noizu.Cms.V2.VersionEntity.ref(version))
  end

  def set_parent!(ref, version, context, options) do
    set_parent(ref, version, context, options)
  end
  #----------------------
  #
  #----------------------
  def get_parent(ref, _context, _options) do
    ref.article_info && ref.article_info.parent
  end

  def get_parent!(ref, context, options) do
    get_parent(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def get_article_info(ref, context, options) do
    get_in(ref, [Access.key(:article_info)])
  end

  def get_article_info!(ref, _context, _options) do
    get_in(ref, [Access.key(:article_info)])
  end

  #----------------------
  #
  #----------------------
  def set_article_info(ref, article_info, context, options) do
    put_in(ref, [Access.key(:article_info)], article_info)
  end

  def set_article_info!(ref, article_info, _context, _options) do
    put_in(ref, [Access.key(:article_info)], article_info)
  end
end


#=====================================================
#
#=====================================================
defimpl Noizu.Cms.V2.Proto, for: [Noizu.Cms.V2.VersionEntity] do
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
  def cms_provider(ref, _context, _options) do
    # @note, this is a bit of a shortcut to avoid expanding the full ref.
    case ref.article do
      {:ref, entity, _} -> entity.cms_provider()
      _ ->
        case Noizu.ERP.ref(ref.article) do
          {:ref, entity, _} -> entity.cms_provider()
          _ -> nil
        end
    end
  end
  def cms_provider!(ref, context, options), do: cms_provider(ref, context, options)

  #----------------------
  #
  #----------------------
  def is_versioning_record?(_ref, _context, _options), do: true
  def is_versioning_record!(_ref, _context, _options), do: true

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

  def versioned_ref(_ref, _context, _options), do: throw :not_supported
  def versioned_ref!(_ref, _context, _options), do: throw :not_supported

  def article_ref(_ref, _context, _options), do: throw :not_supported
  def article_ref!(_ref, _context, _options), do: throw :not_supported
  #----------------------
  #
  #----------------------
  def compress_archive(ref, context, options) do
    # obtain revision, and call compress on it.
    if entity = Noizu.ERP.entity(ref.revision) do
      Noizu.Cms.V2.Proto.compress_archive(entity, context, options)
    end
  end

  def compress_archive!(ref, context, options) do
    # obtain revision, and call compress on it.
    if entity = Noizu.ERP.entity!(ref.revision) do
      Noizu.Cms.V2.Proto.compress_archive!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_article(ref, _context, _options), do: ref.article
  def get_article!(ref, _context, _options), do: ref.article

  #----------------------
  #
  #----------------------
  def set_version(_ref, _version, _context, _options), do: throw :not_supported
  def set_version!(_ref, _version, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_version(ref, _context, _options), do: ref
  def get_version!(ref, _context, _options), do: ref

  #----------------------
  #
  #----------------------
  def set_revision(_ref, _revision, _context, _options), do: throw :not_supported
  def set_revision!(_ref, _revision, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_revision(ref, _context, _options), do: ref.revision
  def get_revision!(ref, _context, _options), do: ref.revision

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

  #----------------------
  #
  #----------------------
  def set_article_info(_ref, _article_info, _context, _options), do: throw :not_supported
  def set_article_info!(_ref, _article_info, _context, _options), do: throw :not_supported
end



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
  def cms_provider(ref, _context, _options) do
    # @note, this is a bit of a shortcut to avoid expanding the full ref.
    case ref.article do
      {:ref, entity, _} -> entity.cms_provider()
      _ ->
        case Noizu.ERP.ref(ref.article) do
          {:ref, entity, _} -> entity.cms_provider()
          _ -> nil
        end
    end
  end
  def cms_provider!(ref, context, options), do: cms_provider(ref, context, options)

  #----------------------
  #
  #----------------------
  def is_versioning_record?(_ref, _context, _options), do: true
  def is_versioning_record!(_ref, _context, _options), do: true

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
  def compress_archive(ref, context, options) do
    {ref.full_copy, ref.record}
  end

  def compress_archive!(ref, context, options) do
    {ref.full_copy, ref.record}
  end

  #----------------------
  #
  #----------------------
  def get_article(ref, _context, _options), do: ref.article
  def get_article!(ref, _context, _options), do: ref.article

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

  #----------------------
  #
  #----------------------
  def set_article_info(_ref, _article_info, _context, _options), do: throw :not_supported
  def set_article_info!(_ref, _article_info, _context, _options), do: throw :not_supported
end