#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.ProtoProvider.Default do
  #----------------------
  #
  #----------------------
  def tags(_m, ref, _context, _options) do
    ref.article_info.tags
  end

  def tags!(_m, ref, _context, _options) do
    ref.article_info.tags
  end

  #----------------------
  #
  #----------------------
  def type(_m, ref, _context, _options) do
    ref.__struct__.cms_type()
  end

  def type!(_m, ref, _context, _options) do
    ref.__struct__.cms_type()
  end


  #----------------------
  #
  #----------------------
  def is_cms_entity?(_m, _ref, _context, _options), do: true
  def is_cms_entity!(_m, _ref, _context, _options), do: true

  #----------------------
  #
  #----------------------
  def is_versioning_record?(_m, ref, context, options) do
    ref.__struct__.is_versioning_record?(ref, context, options)
  end

  def is_versioning_record!(_m, ref, context, options) do
    ref.__struct__.is_versioning_record!(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def is_revision_record?(_m, ref, context, options) do
    ref.__struct__.is_revision_record?(ref, context, options)
  end

  def is_revision_record!(_m, ref, context, options) do
    ref.__struct__.is_revision_record!(ref, context, options)
  end


  #----------------------
  #
  #----------------------
  def versioned_identifier(_m, ref, _context, _options) do
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

  def versioned_identifier!(m, ref, context, options) do
    m.versioned_identifier(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def article_identifier(_m, ref, _context, _options) do
    case ref.identifier do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:revision, {identifier, _version, _revision}} -> identifier
      identifier -> identifier
    end
  end
  def article_identifier!(m, ref, context, options) do
    m.article_identifier(ref, context, options)
  end

  def versioned_ref(_m, ref, _context, _options) do
    if ref.article_info && ref.article_info.revision do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:ref, _, {{:ref, _v, {{:ref, _a, identifier}, version_path}}, revision_number}} = Noizu.ERP.ref(ref.article_info.revision)
      Noizu.ERP.ref(%{ref| identifier: {:revision, {identifier, version_path, revision_number}}})
    end
  end

  def versioned_ref!(m, ref, context, options) do
    m.versioned_ref(ref, context, options)
  end

  def article_ref(_m, ref, _context, _options) do
    case ref.identifier do
      # @Hack - Avoid Hard Coded Formatting, need prototypes, etc. here.
      {:revision, {identifier, _version, _revision}} -> Noizu.ERP.ref(%{ref| identifier: identifier})
      _identifier -> Noizu.ERP.ref(ref)
    end
  end

  def article_ref!(m, ref, context, options) do
    m.article_ref(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def compress_archive(_m, ref, context, options) do
    {:ref, Noizu.Cms.V2.Proto.versioned_ref(ref, context, options)}
  end

  def compress_archive!(_m, ref, context, options) do
    {:ref, Noizu.Cms.V2.Proto.versioned_ref!(ref, context, options)}
  end

  #----------------------
  #
  #----------------------
  def get_article(_m, ref, _context, _options), do: ref

  def get_article!(_m, ref, _context, _options), do: ref

  #----------------------
  #
  #----------------------
  def set_version(_m, ref, version, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:version)], Noizu.Cms.V2.VersionEntity.ref(version))
  end

  def set_version!(m, ref, version, context, options) do
    m.set_version(ref, version, context, options)
  end

  #----------------------
  #
  #----------------------
  def get_version(_m, ref, _context, _options) do
    ref.article_info && ref.article_info.version
  end

  def get_version!(m, ref, context, options) do
    m.get_version(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def set_revision(_m, ref, revision, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:revision)], Noizu.Cms.V2.Version.RevisionEntity.ref(revision))
  end

  def set_revision!(m, ref, revision, context, options) do
    m.set_revision(ref, revision, context, options)
  end

  #----------------------
  #
  #----------------------
  def get_revision(_m, ref, _context, _options) do
    ref.article_info && ref.article_info.revision
  end

  def get_revision!(m, ref, context, options) do
    m.get_revision(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def set_parent(_m, ref, version, _context, _options) do
    put_in(ref, [Access.key(:article_info), Access.key(:parent)], Noizu.Cms.V2.VersionEntity.ref(version))
  end

  def set_parent!(m, ref, version, context, options) do
    m.set_parent(ref, version, context, options)
  end
  #----------------------
  #
  #----------------------
  def get_parent(_m, ref, _context, _options) do
    ref.article_info && ref.article_info.parent
  end

  def get_parent!(m, ref, context, options) do
    m.get_parent(ref, context, options)
  end

  #----------------------
  #
  #----------------------
  def get_article_info(_m, ref, _context, _options) do
    get_in(ref, [Access.key(:article_info)])
  end

  def get_article_info!(_m, ref, _context, _options) do
    get_in(ref, [Access.key(:article_info)])
  end


  #--------------------------------
  # @init_article_info
  #--------------------------------
  def init_article_info(_m, entity, context, options) do
    entity.__struct__.article_info_entity().init(entity, context, options)
  end

  def init_article_info!(_m, entity, context, options) do
    entity.__struct__.article_info_entity().init!(entity, context, options)
  end

  #--------------------------------
  # @update_article_info
  #--------------------------------
  def update_article_info(_m, entity, context, options) do
    entity.__struct__.article_info_entity().update(entity, context, options)
  end

  def update_article_info!(_m, entity, context, options) do
    entity.__struct__.article_info_entity().update!(entity, context, options)
  end

  #----------------------
  #
  #----------------------
  def set_article_info(_m, ref, article_info, _context, _options) do
    put_in(ref, [Access.key(:article_info)], article_info)
  end

  def set_article_info!(_m, ref, article_info, _context, _options) do
    put_in(ref, [Access.key(:article_info)], article_info)
  end
end


defmodule Noizu.Cms.V2.ProtoProviderBehaviour do

  defmacro __using__(_opts) do
    quote do

      #----------------------
      #
      #----------------------
      def tags(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.tags(__MODULE__, ref, context, options)
      end

      def tags!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.tags!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def type(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.type(__MODULE__, ref, context, options)
      end

      def type!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.type!(__MODULE__, ref, context, options)
      end


      #----------------------
      #
      #----------------------
      def is_cms_entity?(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.is_cms_entity?(__MODULE__, ref, context, options)
      end
      def is_cms_entity!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.is_cms_entity!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def is_versioning_record?(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.is_versioning_record?(__MODULE__, ref, context, options)
      end

      def is_versioning_record!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.is_versioning_record!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def is_revision_record?(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.is_revision_record?(__MODULE__, ref, context, options)
      end

      def is_revision_record!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.is_revision_record!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def versioned_identifier(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.versioned_identifier(__MODULE__, ref, context, options)
      end

      def versioned_identifier!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.versioned_identifier!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def article_identifier(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.article_identifier(__MODULE__, ref, context, options)
      end
      def article_identifier!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.article_identifier!(__MODULE__, ref, context, options)
      end

      def versioned_ref(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.versioned_ref(__MODULE__, ref, context, options)
      end

      def versioned_ref!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.versioned_ref!(__MODULE__, ref, context, options)
      end

      def article_ref(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.article_ref(__MODULE__, ref, context, options)
      end

      def article_ref!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.article_ref!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def compress_archive(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.compress_archive(__MODULE__, ref, context, options)
      end

      def compress_archive!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.compress_archive!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def get_article(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_article(__MODULE__, ref, context, options)
      end

      def get_article!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_article!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def set_version(ref, version, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_version(__MODULE__, ref, version, context, options)
      end

      def set_version!(ref, version, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_version!(__MODULE__, ref, version, context, options)
      end

      #----------------------
      #
      #----------------------
      def get_version(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_version(__MODULE__, ref, context, options)
      end
      def get_version!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_version!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def set_revision(ref, revision, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_revision(__MODULE__, ref, revision, context, options)
      end
      def set_revision!(ref, revision, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_revision!(__MODULE__, ref, revision, context, options)
      end

      #----------------------
      #
      #----------------------
      def get_revision(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_revision(__MODULE__, ref, context, options)
      end

      def get_revision!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_revision!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def set_parent(ref, version, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_parent(__MODULE__, ref, version, context, options)
      end

      def set_parent!(ref, version, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_parent!(__MODULE__, ref, version, context, options)
      end
      #----------------------
      #
      #----------------------
      def get_parent(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_parent(__MODULE__, ref, context, options)
      end

      def get_parent!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_parent!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def get_article_info(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_article_info(__MODULE__, ref, context, options)
      end

      def get_article_info!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.get_article_info!(__MODULE__, ref, context, options)
      end


      #--------------------------------
      # @init_article_info
      #--------------------------------
      def init_article_info(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.init_article_info(__MODULE__, ref, context, options)
      end

      def init_article_info!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.init_article_info!(__MODULE__, ref, context, options)
      end

      #--------------------------------
      # @update_article_info
      #--------------------------------
      def update_article_info(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.update_article_info(__MODULE__, ref, context, options)
      end

      def update_article_info!(ref, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.update_article_info!(__MODULE__, ref, context, options)
      end

      #----------------------
      #
      #----------------------
      def set_article_info(ref, article_info, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_article_info(__MODULE__, ref, article_info, context, options)
      end

      def set_article_info!(ref, article_info, context, options) do
        Noizu.Cms.V2.ProtoProvider.Default.set_article_info!(__MODULE__, ref, article_info, context, options)
      end


      defoverridable [
        tags: 3,
        tags!: 3,
        type: 3,
        type!: 3,
        is_cms_entity?: 3,
        is_cms_entity!: 3,
        is_versioning_record?: 3,
        is_versioning_record!: 3,
        is_revision_record?: 3,
        is_revision_record!: 3,
        versioned_identifier: 3,
        versioned_identifier!: 3,
        article_identifier: 3,
        article_identifier!: 3,
        versioned_ref: 3,
        versioned_ref!: 3,
        article_ref: 3,
        article_ref!: 3,
        compress_archive: 3,
        compress_archive!: 3,
        get_article: 3,
        get_article!: 3,
        set_version: 4,
        set_version!: 4,
        get_version: 3,
        get_version!: 3,
        set_revision: 4,
        set_revision!: 4,
        get_revision: 3,
        get_revision!: 3,
        set_parent: 4,
        set_parent!: 4,
        get_parent: 3,
        get_parent!: 3,
        get_article_info: 3,
        get_article_info!: 3,
        init_article_info: 3,
        init_article_info!: 3,
        update_article_info: 3,
        update_article_info!: 3,
        set_article_info: 4,
        set_article_info!: 4,
      ]

    end # end quote
  end #end __using__
end #end ProtoProviderBehaviour
