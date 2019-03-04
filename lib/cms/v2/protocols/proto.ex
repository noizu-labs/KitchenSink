#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Cms.V2.Proto do
  @fallback_to_any true

  def tags(ref, context, options)
  def set_version(ref, version, context, options)
  def prepare_version(ref, context, options)
  def expand_version(ref, version, context, options)
  def index_details(ref, context, options)

  def tags!(ref, context, options)
  def set_version!(ref, version, context, options)
  def prepare_version!(ref, context, options)
  def expand_version!(ref, version, context, options)
  def index_details!(ref, context, options)

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

end




defimpl Noizu.Cms.V2.Proto, for: [Noizu.Cms.V2.Article.FileEntity, Noizu.Cms.V2.Article.ImageEntity, Noizu.Cms.V2.Article.PostEntity] do

  def tags(ref, context, options) do
    ref.article_info.tags
  end

  def set_version(ref, version, context, options) do
    put_in(ref, [Access.key(:article_info), Access.key(:version)], version)
  end

  def prepare_version(ref, context, options) do
    %Noizu.Cms.V2.VersionEntity{
      identifier: ref.article_info.version,
      article: Noizu.ERP.ref(ref),
      parent: ref.article_info.parent_version,
      full_copy: true,
      created_on: DateTime.utc_now(),
      editor: ref.article_info.editor,
      status: ref.article_info.status,
      record: ref,
    }
  end

  def expand_version(ref, version, context, options) do
    version.record
  end

  def index_details(ref, context, options) do
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


  def tags!(ref, context, options) do
    tags(ref, context, options)
  end

  def set_version!(ref, version, context, options) do
    set_version(ref, version, context, options)
  end

  def prepare_version!(ref, context, options) do
    prepare_version(ref, context, options)
  end

  def expand_version!(ref, version, context, options) do
    expand_version(ref, version, context, options)
  end

  def index_details!(ref, context, options) do
    index_details(ref, context, options)
  end

end
