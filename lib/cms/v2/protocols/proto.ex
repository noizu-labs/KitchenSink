#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Cms.V2.Proto do
  @fallback_to_any false

  #--------------------------------
  # @tags
  #--------------------------------
  def tags(ref, context, options)
  def tags!(ref, context, options)

  #--------------------------------
  # @type
  #--------------------------------
  def type(ref, context, options)
  def type!(ref, context, options)

  #--------------------------------
  # @is_cms_entity
  #--------------------------------
  def is_cms_entity?(ref, context, options)
  def is_cms_entity!(ref, context, options)

  #--------------------------------
  # @is_versioning_record
  #--------------------------------
  def is_versioning_record?(ref, context, options)
  def is_versioning_record!(ref, context, options)

  #--------------------------------
  # @is_revision_record
  #--------------------------------
  def is_revision_record?(ref, context, options)
  def is_revision_record!(ref, context, options)

  #--------------------------------
  # @versioned_identifier
  #--------------------------------
  def versioned_identifier(ref, context, options)
  def versioned_identifier!(ref, context, options)

  #--------------------------------
  # @article_identifier
  #--------------------------------
  def article_identifier(ref, context, options)
  def article_identifier!(ref, context, options)

  #--------------------------------
  # @
  #--------------------------------
  def versioned_ref(ref, context, options)
  def versioned_ref!(ref, context, options)

  #--------------------------------
  # @article_ref
  #--------------------------------
  def article_ref(ref, context, options)
  def article_ref!(ref, context, options)

  #--------------------------------
  # @get_article
  #--------------------------------
  def get_article(ref, context, options)
  def get_article!(ref, context, options)

  #--------------------------------
  # @compress_archive
  #--------------------------------
  def compress_archive(ref, context, options)
  def compress_archive!(ref, context, options)

  #--------------------------------
  # @set_version
  #--------------------------------
  def set_version(ref, version, context, options)
  def set_version!(ref, version, context, options)

  #--------------------------------
  # @get_version
  #--------------------------------
  def get_version(ref, context, options)
  def get_version!(ref, context, options)

  #--------------------------------
  # @set_revision
  #--------------------------------
  def set_revision(ref, revision, context, options)
  def set_revision!(ref, revision, context, options)

  #--------------------------------
  # @get_revision
  #--------------------------------
  def get_revision(ref, context, options)
  def get_revision!(ref, context, options)

  #--------------------------------
  # @set_parent
  #--------------------------------
  def set_parent(ref, version, context, options)
  def set_parent!(ref, version, context, options)

  #--------------------------------
  # @get_parent
  #--------------------------------
  def get_parent(ref, context, options)
  def get_parent!(ref, context, options)

  #--------------------------------
  # @get_article_info
  #--------------------------------
  def get_article_info(ref, context, options)
  def get_article_info!(ref, context, options)

  #--------------------------------
  # @init_article_info
  #--------------------------------
  def init_article_info(ref, context, options)
  def init_article_info!(ref, context, options)

  #--------------------------------
  # @update_article_info
  #--------------------------------
  def update_article_info(ref, context, options)
  def update_article_info!(ref, context, options)

  #--------------------------------
  # @set_article_info
  #--------------------------------
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
  def is_cms_entity?(ref, context, options) do
    try do
      case ref do
        {:ref, m, _} -> m.is_cms_entity?(ref, context, options)
        _ -> false
      end
    rescue _e -> false
    end
  end

  def is_cms_entity!(ref, context, options) do
    try do
      case ref do
        {:ref, m, _} -> m.is_cms_entity!(ref, context, options)
        _ -> false
      end
    rescue _e -> false
    end
  end

  #----------------------
  #
  #----------------------
  def is_versioning_record?(ref, context, options) do
    try do
      case ref do
        {:ref, m, _} -> m.is_versioning_record?(ref, context, options)
        _ -> false
      end
    rescue _e -> false
    end
  end

  def is_versioning_record!(ref, context, options) do
    try do
      case ref do
        {:ref, m, _} -> m.is_versioning_record!(ref, context, options)
        _ -> false
      end
    rescue _e -> false
    end
  end

  #----------------------
  #
  #----------------------
  def is_revision_record?(ref, context, options) do
    try do
      case ref do
        {:ref, m, _} -> m.is_revision_record?(ref, context, options)
        _ -> false
      end
    rescue _e -> false
    end
  end

  def is_revision_record!(ref, context, options) do
    try do
      case ref do
        {:ref, m, _} -> m.is_revision_record!(ref, context, options)
        _ -> false
      end
    rescue _e -> false
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
      _v_ref = {:ref, m, {:revision, {identifier, _version, _revision}}} -> {:ref, m, identifier}
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

  #--------------------------------
  # @init_article_info
  #--------------------------------
  def init_article_info(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.init_article_info(entity, context, options)
    end
  end

  def init_article_info!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.init_article_info!(entity, context, options)
    end
  end


  #--------------------------------
  # @update_article_info
  #--------------------------------
  def update_article_info(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.update_article_info(entity, context, options)
    end
  end

  def update_article_info!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.update_article_info!(entity, context, options)
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


