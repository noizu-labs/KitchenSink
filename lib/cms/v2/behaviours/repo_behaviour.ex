#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.RepoBehaviour do
  @callback cms_versioning_provider() :: any
  @callback cms_implementation_provider() :: any

  # Query
  @callback get_by_status(any, any, any) :: any
  @callback get_by_status!(any, any, any) :: any

  @callback get_by_type(any, any, any) :: any
  @callback get_by_type!(any, any, any) :: any

  @callback get_by_module(any, any, any) :: any
  @callback get_by_module!(any, any, any) :: any

  @callback get_by_editor(any, any, any) :: any
  @callback get_by_editor!(any, any, any) :: any

  @callback get_by_tag(any, any, any) :: any
  @callback get_by_tag!(any, any, any) :: any

  @callback get_by_created_on(any, any, any, any) :: any
  @callback get_by_created_on!(any, any, any, any) :: any

  @callback get_by_modified_on(any, any, any, any) :: any
  @callback get_by_modified_on!(any, any, any, any) :: any


  # Book Keeping
  @callback update_tags(any, any, any) :: any
  @callback update_tags!(any, any, any) :: any

  @callback delete_tags(any, any, any) :: any
  @callback delete_tags!(any, any, any) :: any

  @callback update_index(any, any, any) :: any
  @callback update_index!(any, any, any) :: any

  @callback delete_index(any, any, any) :: any
  @callback delete_index!(any, any, any) :: any

  # Versioning
  @callback initialize_versioning_records(any, any, any) :: any
  @callback populate_versioning_records(any, any, any) :: any

  @callback make_active(any, any, any) :: any
  @callback make_active!(any, any, any) :: any

  @callback get_active(any, any, any) :: any
  @callback get_active!(any, any, any) :: any

  @callback update_active(any, any, any) :: any
  @callback update_active!(any, any, any) :: any

  @callback remove_active(any, any, any) :: any
  @callback remove_active!(any, any, any) :: any

  # @todo approve/etc.

  @callback init_article_info(any, any, any) :: any
  @callback init_article_info!(any, any, any) :: any

  @callback update_article_info(any, any, any) :: any
  @callback update_article_info!(any, any, any) :: any

  @callback get_versions(any, any, any) :: any
  @callback get_versions!(any, any, any) :: any

  @callback new_version(any, any, any) :: any
  @callback new_version!(any, any, any) :: any

  @callback new_revision(any, any, any) :: any
  @callback new_revision!(any, any, any) :: any

  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Repo.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @behaviour Noizu.Cms.V2.RepoBehaviour
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))

      def cms_versioning_provider(), do: @versioning_provider
      def cms_implementation_provider(), do: @default_implementation





      #----------------------------------
      # expand_records/3
      #----------------------------------
      def expand_records(records, context, options), do: @default_implementation.expand_records(records, context, options, __MODULE__)

      #----------------------------------
      # expand_records!/3
      #----------------------------------
      def expand_records!(records, context, options), do: @default_implementation.expand_records!(records, context, options, __MODULE__)

      #----------------------------------
      # match_records/3
      #----------------------------------
      def match_records(filter, context, options), do: @default_implementation.match_records(filter, context, options, __MODULE__)

      #----------------------------------
      # match_records!/3
      #----------------------------------
      def match_records!(filter, context, options), do: @default_implementation.match_records!(filter, context, options, __MODULE__)

      #----------------------------------
      # filter_records/3
      #----------------------------------
      def filter_records(records, context, options), do: @default_implementation.filter_records(records, context, options, __MODULE__)







      #-------------------------
      # Query
      #-------------------------
      def get_by_status(status, context, options), do: @default_implementation.get_by_status(status, context, options, __MODULE__)
      def get_by_status!(status, context, options), do: @default_implementation.get_by_status!(status, context, options, __MODULE__)

      def get_by_type(type, context, options), do: @default_implementation.get_by_type(type, context, options, __MODULE__)
      def get_by_type!(type, context, options), do: @default_implementation.get_by_type!(type, context, options, __MODULE__)

      def get_by_module(module, context, options), do: @default_implementation.get_by_module(module, context, options, __MODULE__)
      def get_by_module!(module, context, options), do: @default_implementation.get_by_module!(module, context, options, __MODULE__)

      def get_by_editor(editor, context, options), do: @default_implementation.get_by_editor(editor, context, options, __MODULE__)
      def get_by_editor!(editor, context, options), do: @default_implementation.get_by_editor!(editor, context, options, __MODULE__)

      def get_by_tag(tag, context, options), do: @default_implementation.get_by_tag(tag, context, options, __MODULE__)
      def get_by_tag!(tag, context, options), do: @default_implementation.get_by_tag!(tag, context, options, __MODULE__)

      def get_by_created_on(from, to, context, options), do: @default_implementation.get_by_created_on(from, to, context, options, __MODULE__)
      def get_by_created_on!(from, to, context, options), do: @default_implementation.get_by_created_on!(from, to, context, options, __MODULE__)

      def get_by_modified_on(from, to, context, options), do: @default_implementation.get_by_modified_on(from, to, context, options, __MODULE__)
      def get_by_modified_on!(from, to, context, options), do: @default_implementation.get_by_modified_on!(from, to, context, options, __MODULE__)


      #-------------------------
      # Book Keeping
      #-------------------------
      def update_tags(entry, context, options), do: @default_implementation.update_tags(entry, context, options, __MODULE__)
      def update_tags!(entry, context, options), do: @default_implementation.update_tags!(entry, context, options, __MODULE__)

      def delete_tags(entry, context, options), do: @default_implementation.delete_tags(entry, context, options, __MODULE__)
      def delete_tags!(entry, context, options), do: @default_implementation.delete_tags!(entry, context, options, __MODULE__)

      def update_index(entry, context, options), do: @default_implementation.update_index(entry, context, options, __MODULE__)
      def update_index!(entry, context, options), do: @default_implementation.update_index!(entry, context, options, __MODULE__)

      def delete_index(entry, context, options), do: @default_implementation.delete_index(entry, context, options, __MODULE__)
      def delete_index!(entry, context, options), do: @default_implementation.delete_index!(entry, context, options, __MODULE__)

      #-------------------------
      # Versioning
      #-------------------------
      def initialize_versioning_records(entity, context, options \\ %{}), do: @versioning_provider.initialize_versioning_records(entity, context, options, __MODULE__)
      def populate_versioning_records(entity, context, options \\ %{}), do: @versioning_provider.populate_versioning_records(entity, context, options, __MODULE__)

      def make_active(entity, context, options \\ %{}), do: @default_implementation.make_active(entity, context, options, __MODULE__)
      def make_active!(entity, context, options \\ %{}), do: @default_implementation.make_active!(entity, context, options, __MODULE__)

      def get_active(entity, context, options \\ %{}), do: @default_implementation.get_active(entity, context, options, __MODULE__)
      def get_active!(entity, context, options \\ %{}), do: @default_implementation.get_active!(entity, context, options, __MODULE__)

      def update_active(entity, context, options \\ %{}), do: @default_implementation.update_active(entity, context, options, __MODULE__)
      def update_active!(entity, context, options \\ %{}), do: @default_implementation.update_active!(entity, context, options, __MODULE__)

      def remove_active(entity, context, options \\ %{}), do: @default_implementation.remove_active(entity, context, options, __MODULE__)
      def remove_active!(entity, context, options \\ %{}), do: @default_implementation.remove_active!(entity, context, options, __MODULE__)

      #def make_version_default(entity, context, options \\ %{}), do: @default_implementation.make_version_default(entity, context, options, __MODULE__)
      #def make_version_default!(entity, context, options \\ %{}), do: @default_implementation.make_version_default!(entity, context, options, __MODULE__)

      #def get_version_default(entity, context, options \\ %{}), do: @default_implementation.get_version_default(entity, context, options, __MODULE__)
      #def get_version_default!(entity, context, options \\ %{}), do: @default_implementation.get_version_default!(entity, context, options, __MODULE__)

      #def approve_revision(entity, context, options \\ %{}), do: @default_implementation.approve_revision(entity, context, options, __MODULE__)
      #def approve_revision!(entity, context, options \\ %{}), do: @default_implementation.approve_revision!(entity, context, options, __MODULE__)

      #def reject_revision(entity, context, options \\ %{}), do: @default_implementation.reject_revision(entity, context, options, __MODULE__)
      #def reject_revision!(entity, context, options \\ %{}), do: @default_implementation.reject_revision!(entity, context, options, __MODULE__)

      # @todo json marshalling logic (mix of protocol and scaffolding methods).
      # @todo setup permission system
      # @todo setup plug / controller routes

      def init_article_info(entity, context, options \\ %{}), do: @default_implementation.init_article_info(entity, context, options, __MODULE__)
      def init_article_info!(entity, context, options \\ %{}), do: @default_implementation.init_article_info!(entity, context, options, __MODULE__)

      def update_article_info(entity, context, options \\ %{}), do: @default_implementation.update_article_info(entity, context, options, __MODULE__)
      def update_article_info!(entity, context, options \\ %{}), do: @default_implementation.update_article_info!(entity, context, options, __MODULE__)

      def get_versions(entity, context, options \\ %{}), do: @versioning_provider.get_versions(entity, context, options, __MODULE__)
      def get_versions!(entity, context, options \\ %{}), do: @versioning_provider.get_versions!(entity, context, options, __MODULE__)

      def create_version(entity, context, options \\ %{}), do: @versioning_provider.create_version(entity, context, options, __MODULE__)
      def create_version!(entity, context, options \\ %{}), do: @versioning_provider.create_version!(entity, context, options, __MODULE__)

      def update_version(entity, context, options \\ %{}), do: @versioning_provider.update_version(entity, context, options, __MODULE__)
      def update_version!(entity, context, options \\ %{}), do: @versioning_provider.update_version!(entity, context, options, __MODULE__)

      def delete_version(entity, context, options \\ %{}), do: @versioning_provider.delete_version(entity, context, options, __MODULE__)
      def delete_version!(entity, context, options \\ %{}), do: @versioning_provider.delete_version!(entity, context, options, __MODULE__)

      def get_revisions(entity, context, options \\ %{}), do: @versioning_provider.get_revisions(entity, context, options, __MODULE__)
      def get_revisions!(entity, context, options \\ %{}), do: @versioning_provider.get_revisions!(entity, context, options, __MODULE__)


      def create_revision(entity, context, options \\ %{}), do: @versioning_provider.create_revision(entity, context, options, __MODULE__)
      def create_revision!(entity, context, options \\ %{}), do: @versioning_provider.create_revision!(entity, context, options, __MODULE__)

      def update_revision(entity, context, options \\ %{}), do: @versioning_provider.update_revision(entity, context, options, __MODULE__)
      def update_revision!(entity, context, options \\ %{}), do: @versioning_provider.update_revision!(entity, context, options, __MODULE__)

      def delete_revision(entity, context, options \\ %{}), do: @versioning_provider.delete_revision(entity, context, options, __MODULE__)
      def delete_revision!(entity, context, options \\ %{}), do: @versioning_provider.delete_revision!(entity, context, options, __MODULE__)


      def new_version(entity, context, options \\ %{}), do: @versioning_provider.new_version(entity, context, options, __MODULE__)
      def new_version!(entity, context, options \\ %{}), do: @versioning_provider.new_version!(entity, context, options, __MODULE__)

      def new_revision(entity, context, options \\ %{}), do: @versioning_provider.new_revision(entity, context, options, __MODULE__)
      def new_revision!(entity, context, options \\ %{}), do: @versioning_provider.new_revision!(entity, context, options, __MODULE__)

      #------------------
      # Repo Overrides
      #------------------
      def create(entity, context, options \\ %{}), do: @default_implementation.create(entity, context, options, __MODULE__)
      def pre_create_callback(entity, context, options \\ %{}), do: @default_implementation.pre_create_callback(entity, context, options, __MODULE__)
      def post_create_callback(entity, context, options \\ %{}), do: @default_implementation.post_create_callback(entity, context, options, __MODULE__)

      def get(entity, context, options \\ %{}), do: @default_implementation.get(entity, context, options, __MODULE__)
      def post_get_callback(entity, context, options \\ %{}), do: @default_implementation.post_get_callback(entity, context, options, __MODULE__)

      def update(entity, context, options \\ %{}), do: @default_implementation.update(entity, context, options, __MODULE__)
      def pre_update_callback(entity, context, options \\ %{}), do: @default_implementation.pre_update_callback(entity, context, options, __MODULE__)
      def post_update_callback(entity, context, options \\ %{}), do: @default_implementation.post_update_callback(entity, context, options, __MODULE__)

      def delete(entity, context, options \\ %{}), do: @default_implementation.delete(entity, context, options, __MODULE__)
      def pre_delete_callback(entity, context, options \\ %{}), do: @default_implementation.pre_delete_callback(entity, context, options, __MODULE__)
      def post_delete_callback(entity, context, options \\ %{}), do: @default_implementation.post_delete_callback(entity, context, options, __MODULE__)

      defoverridable [

        cms_versioning_provider: 0,
        cms_implementation_provider: 0,


        #---------------
        # Query
        #---------------
        get_by_status: 3,
        get_by_status!: 3,

        get_by_type: 3,
        get_by_type!: 3,

        get_by_module: 3,
        get_by_module!: 3,

        get_by_editor: 3,
        get_by_editor!: 3,

        get_by_tag: 3,
        get_by_tag!: 3,

        get_by_created_on: 4,
        get_by_created_on!: 4,

        get_by_modified_on: 4,
        get_by_modified_on!: 4,

        #-------------------
        # Book Keeping
        #-------------------
        update_tags: 3,
        update_tags!: 3,

        delete_tags: 3,
        delete_tags!: 3,

        update_index: 3,
        update_index!: 3,

        delete_index: 3,
        delete_index!: 3,

        #-------------------
        # Versioning
        #-------------------
        initialize_versioning_records: 2,
        initialize_versioning_records: 3,

        populate_versioning_records: 2,
        populate_versioning_records: 3,

        make_active: 2,
        make_active: 3,

        make_active!: 2,
        make_active!: 3,

        update_active: 2,
        update_active: 3,

        update_active!: 2,
        update_active!: 3,

        get_active: 2,
        get_active: 3,

        get_active!: 2,
        get_active!: 3,

        remove_active: 2,
        remove_active: 3,

        remove_active!: 2,
        remove_active!: 3,

        init_article_info: 2,
        init_article_info: 3,

        init_article_info!: 2,
        init_article_info!: 3,

        update_article_info: 2,
        update_article_info: 3,

        update_article_info!: 2,
        update_article_info!: 3,

        get_versions: 2,
        get_versions: 3,

        get_versions!: 2,
        get_versions!: 3,

        get_revisions: 2,
        get_revisions: 3,

        get_revisions!: 2,
        get_revisions!: 3,

        create_version: 2,
        create_version: 3,

        create_version!: 2,
        create_version!: 3,

        update_version: 2,
        update_version: 3,

        update_version!: 2,
        update_version!: 3,

        delete_version: 2,
        delete_version: 3,

        delete_version!: 2,
        delete_version!: 3,



        create_revision: 2,
        create_revision: 3,

        create_revision!: 2,
        create_revision!: 3,

        update_revision: 2,
        update_revision: 3,

        update_revision!: 2,
        update_revision!: 3,

        delete_revision: 2,
        delete_revision: 3,

        delete_revision!: 2,
        delete_revision!: 3,


        new_version: 2,
        new_version: 3,

        new_version!: 2,
        new_version!: 3,

        new_revision: 2,
        new_revision: 3,

        new_revision!: 2,
        new_revision!: 3,

        #------------------
        # Repo Behaviour
        #------------------
        create: 2,
        create: 3,

        pre_create_callback: 2,
        pre_create_callback: 3,

        post_create_callback: 2,
        post_create_callback: 3,

        get: 2,
        get: 3,

        post_get_callback: 2,
        post_get_callback: 3,

        update: 2,
        update: 3,

        pre_update_callback: 2,
        pre_update_callback: 3,

        post_update_callback: 2,
        post_update_callback: 3,

        delete: 2,
        delete: 3,

        pre_delete_callback: 2,
        pre_delete_callback: 3,

        post_delete_callback: 2,
        post_delete_callback: 3,
      ]
    end
  end
end
