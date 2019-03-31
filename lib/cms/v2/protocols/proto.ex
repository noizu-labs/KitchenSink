#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Cms.V2.Proto do
  @fallback_to_any false

  def tags(ref, context, options)
  def set_version(ref, version, context, options)
  def get_version(ref, context, options)
  def set_revision(ref, revision, context, options)
  def get_revision(ref, context, options)
  def set_parent(ref, version, context, options)
  def get_parent(ref, context, options)
  def prepare_version(ref, context, options)
  def expand_version(ref, version, context, options)
  def index_details(ref, context, options)
  def get_article_info(ref, context, options)
  def set_article_info(ref, article_info, context, options)
  def type(ref, context, options)

  def tags!(ref, context, options)
  def set_version!(ref, version, context, options)
  def get_version!(ref, context, options)
  def set_revision!(ref, revision, context, options)
  def get_revision!(ref, context, options)
  def set_parent!(ref, version, context, options)
  def get_parent!(ref, context, options)
  def prepare_version!(ref, context, options)
  def expand_version!(ref, version, context, options)
  def index_details!(ref, context, options)
  def get_article_info!(ref, context, options)
  def set_article_info!(ref, article_info, context, options)
  def type!(ref, context, options)
end # end defprotocol


defimpl Noizu.Cms.V2.Proto, for: [Tuple, BitString] do

  def tags(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.tags(entity, context, options)
    end
  end

  def set_version(ref, version, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_version(entity, version, context, options)
    end
  end

  def get_version(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_version(entity, context, options)
    end
  end


  def set_revision(ref, revision, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_revision(entity, revision, context, options)
    end
  end

  def get_revision(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_revision(entity, context, options)
    end
  end



  def set_parent(ref, version, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_parent(entity, version, context, options)
    end
  end

  def get_parent(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_parent(entity, context, options)
    end
  end


  #def set_version_path(ref, path, context, options) do
  #  if (entity = Noizu.ERP.entity(ref)) do
  #    Noizu.Cms.V2.Proto.set_version(entity, path, context, options)
  #  end
  #end

  #def get_version_path(ref, context, options) do
  #  if (entity = Noizu.ERP.entity(ref)) do
  #    Noizu.Cms.V2.Proto.get_version_path(entity, context, options)
  #  end
  #end

  #def set_sub_version_path(ref, path, context, options) do
  #  if (entity = Noizu.ERP.entity(ref)) do
  #    Noizu.Cms.V2.Proto.set_sub_version(entity, path, context, options)
  #  end
  #end

  #def get_sub_version_path(ref, context, options) do
  #  if (entity = Noizu.ERP.entity(ref)) do
  #    Noizu.Cms.V2.Proto.get_sub_version_path(entity, context, options)
  #  end
  #end

  def prepare_version(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.prepare_version(entity, context, options)
    end
  end

  def expand_version(ref, version, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.expand_version(entity, version, context, options)
    end
  end

  def index_details(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.index_details(entity, context, options)
    end
  end


  def get_article_info(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
    end
  end

  def set_article_info(ref, article_info, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.set_article_info(entity, article_info, context, options)
    end
  end

  def type(ref, context, options) do
    if (entity = Noizu.ERP.entity(ref)) do
      Noizu.Cms.V2.Proto.type(entity, context, options)
    end
  end


  #---------------------
  # Dirty
  #---------------------


  def tags!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.tags!(entity, context, options)
    end
  end

  def set_version!(ref, version, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_version!(entity, version, context, options)
    end
  end

  def get_version!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_version!(entity, context, options)
    end
  end

  def set_revision!(ref, revision, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_revision!(entity, revision, context, options)
    end
  end

  def get_revision!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_revision!(entity, context, options)
    end
  end


  def set_parent!(ref, version, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_parent!(entity, version, context, options)
    end
  end

  def get_parent!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_parent!(entity, context, options)
    end
  end

  #def set_version_path!(ref, path, context, options) do
  #  if (entity = Noizu.ERP.entity!(ref)) do
  #    Noizu.Cms.V2.Proto.set_version!(entity, path, context, options)
  #  end
  #end

  #def get_version_path!(ref, context, options) do
  #  if (entity = Noizu.ERP.entity!(ref)) do
  #    Noizu.Cms.V2.Proto.get_version_path!(entity, context, options)
  #  end
  #end

  #def set_sub_version_path!(ref, path, context, options) do
  #  if (entity = Noizu.ERP.entity!(ref)) do
  #    Noizu.Cms.V2.Proto.set_sub_version!(entity, path, context, options)
  #  end
  #end

  #def get_sub_version_path!(ref, context, options) do
  #  if (entity = Noizu.ERP.entity!(ref)) do
  #    Noizu.Cms.V2.Proto.get_sub_version_path!(entity, context, options)
  #  end
  #end

  def prepare_version!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.prepare_version!(entity, context, options)
    end
  end

  def expand_version!(ref, version, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.expand_version!(entity, version, context, options)
    end
  end

  def index_details!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.index_details!(entity, context, options)
    end
  end

  def get_article_info!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.get_article_info!(entity, context, options)
    end
  end

  def set_article_info!(ref, article_info, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.set_article_info!(entity, article_info, context, options)
    end
  end


  def type!(ref, context, options) do
    if (entity = Noizu.ERP.entity!(ref)) do
      Noizu.Cms.V2.Proto.type!(entity, context, options)
    end
  end
end




defimpl Noizu.Cms.V2.Proto, for: [Noizu.Cms.V2.Article.FileEntity, Noizu.Cms.V2.Article.ImageEntity, Noizu.Cms.V2.Article.PostEntity] do

  def tags(ref, _context, _options) do
    ref.article_info.tags
  end

  def set_version(ref, version, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:version)], Noizu.Cms.V2.VersionEntity.ref(version))
  end

  def get_version(ref, _context, _options) do
    ref.article_info && ref.article_info.version
  end

  def set_revision(ref, revision, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:revision)], Noizu.Cms.V2.Version.RevisionEntity.ref(revision))
  end

  def get_revision(ref, _context, _options) do
    ref.article_info && ref.article_info.revision
  end


  def set_parent(ref, version, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:parent)], Noizu.Cms.V2.VersionEntity.ref(version))
  end

  def get_parent(ref, _context, _options) do
    ref.article_info && ref.article_info.parent
  end


  #def set_version_path(ref, path, _context, _options) do
  #  put_in(ref, [Access.key(:article_info), Access.key(:version_path)], path)
  #end

  #def get_version_path(ref, _context, _options) do
  #  ref.article_info.version_path
  #end

  #def set_sub_version_path(ref, path, _context, _options) do
  #  put_in(ref, [Access.key(:article_info), Access.key(:sub_version_path)], path)
  #end

  #def get_sub_version_path(ref, _context, _options) do
  #  ref.article_info.sub_version_path
  #end

  def prepare_version(ref, _context, _options) do

    ref = Noizu.ERP.ref(ref)
    identifier = {ref, ref.article_info.version}

    parent = case ref.article_info.version do
      nil -> nil
             {1} -> nil
             {n} -> {ref, {n - 1}}
             v when is_tuple(v) ->
             {p, _} = Tuple.to_list(v) |> Enum.split(-1)
             {ref, List.to_tuple(p)}
    end
    parent = parent && {:ref, Noizu.Cms.V2.VersionEntity, parent}

    %Noizu.Cms.V2.VersionEntity{
      identifier: identifier,
      article: ref,
      parent: parent,
      full_copy: true,
      created_on: DateTime.utc_now(),
      editor: ref.article_info.editor,
      status: ref.article_info.status,
      record: ref,
    }
  end

  def expand_version(_ref, version, _context, _options) do
    version.record
  end

  def index_details(ref, _context, _options) do
    type = case ref.__struct__ do
      Noizu.Cms.V2.Article.FileEntity -> :file
      Noizu.Cms.V2.Article.ImageEntity -> :image
      Noizu.Cms.V2.Article.PostEntity -> :post
    end
    %{
      article: Noizu.ERP.ref(ref),
      status: ref.article_info.status,
      module: ref.__struct__,
      type: type,
      editor: ref.article_info.editor,
      created_on: ref.article_info.created_on,
      modified_on: ref.article_info.modified_on,
    }
  end

  def get_article_info(ref, context, options) do
    get_in(ref, [Access.key(:article_info)])
  end

  def set_article_info(ref, article_info, context, options) do
    put_in(ref, [Access.key(:article_info)], article_info)
  end

  def type(ref, _context, _options) do
    case ref.__struct__ do
      Noizu.Cms.V2.Article.FileEntity -> :file
      Noizu.Cms.V2.Article.ImageEntity -> :image
      Noizu.Cms.V2.Article.PostEntity -> :post
    end
  end

  def tags!(ref, context, options) do
    tags(ref, context, options)
  end

  def set_version!(ref, version, context, options) do
    set_version(ref, version, context, options)
  end

  def get_version!(ref, context, options) do
    get_version(ref, context, options)
  end

  def set_revision!(ref, revision, context, options) do
    set_revision(ref, revision, context, options)
  end

  def get_revision!(ref, context, options) do
    get_revision(ref, context, options)
  end


  def set_parent!(ref, version, context, options) do
    set_parent(ref, version, context, options)
  end

  def get_parent!(ref, context, options) do
    get_parent(ref, context, options)
  end
  #def set_version_path!(ref, path, context, options) do
  #  set_version_path(ref, path, context, options)
  #end

  #def get_version_path!(ref, context, options) do
  #  get_version_path(ref, context, options)
  #end

  #def set_sub_version_path!(ref, path, context, options) do
  #  set_sub_version_path(ref, path, context, options)
  #end

  #def get_sub_version_path!(ref, context, options) do
  #  get_sub_version_path(ref, context, options)
  #end

  def prepare_version!(ref, context, options) do
    prepare_version(ref, context, options)
  end

  def expand_version!(ref, version, context, options) do
    expand_version(ref, version, context, options)
  end

  def index_details!(ref, context, options) do
    index_details(ref, context, options)
  end

  def get_article_info!(ref, _context, _options) do
    get_in(ref, [Access.key(:article_info)])
  end

  def set_article_info!(ref, article_info, _context, _options) do
    put_in(ref, [Access.key(:article_info)], article_info)
  end

  def type!(ref, context, options) do
    type(ref, context, options)
  end
end
