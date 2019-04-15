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

  @callback create_version(any, any, any) :: any
  @callback create_version!(any, any, any) :: any

  @callback update_version(any, any, any) :: any
  @callback update_version!(any, any, any) :: any

  @callback delete_version(any, any, any) :: any
  @callback delete_version!(any, any, any) :: any

  @callback get_revisions(any, any, any) :: any
  @callback get_revisions!(any, any, any) :: any

  @callback create_revision(any, any, any) :: any
  @callback create_revision!(any, any, any) :: any

  @callback update_revision(any, any, any) :: any
  @callback update_revision!(any, any, any) :: any

  @callback delete_revision(any, any, any) :: any
  @callback delete_revision!(any, any, any) :: any


  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Repo.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @behaviour Noizu.Cms.V2.RepoBehaviour
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))


      def cms_versioning_provider(), do: @versioning_provider
      def cms_implementation_provider(), do: @default_implementation

      #-------------------------
      # Query
      #-------------------------
      defdelegate get_by_status(status, context, options) , to: @default_implementation
      defdelegate get_by_status!(status, context, options), to: @default_implementation

      defdelegate get_by_type(type, context, options), to: @default_implementation
      defdelegate get_by_type!(type, context, options), to: @default_implementation

      defdelegate get_by_module(module, context, options), to: @default_implementation
      defdelegate get_by_module!(module, context, options), to: @default_implementation

      defdelegate get_by_editor(editor, context, options), to: @default_implementation
      defdelegate get_by_editor!(editor, context, options), to: @default_implementation

      defdelegate get_by_tag(tag, context, options), to: @default_implementation
      defdelegate get_by_tag!(tag, context, options), to: @default_implementation

      defdelegate get_by_created_on(from, to, context, options), to: @default_implementation
      defdelegate get_by_created_on!(from, to, context, options), to: @default_implementation

      defdelegate get_by_modified_on(from, to, context, options), to: @default_implementation
      defdelegate get_by_modified_on!(from, to, context, options), to: @default_implementation


      #-------------------------
      # Book Keeping
      #-------------------------
      defdelegate update_tags(entry, context, options), to: @default_implementation
      defdelegate update_tags!(entry, context, options), to: @default_implementation

      defdelegate delete_tags(entry, context, options), to: @default_implementation
      defdelegate delete_tags!(entry, context, options), to: @default_implementation

      defdelegate update_index(entry, context, options), to: @default_implementation
      defdelegate update_index!(entry, context, options), to: @default_implementation

      defdelegate delete_index(entry, context, options), to: @default_implementation
      defdelegate delete_index!(entry, context, options), to: @default_implementation

      #-------------------------
      # Versioning
      #-------------------------
      defdelegate initialize_versioning_records(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate populate_versioning_records(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate make_active(entity, context, options \\ %{}), to: @default_implementation
      defdelegate make_active!(entity, context, options \\ %{}), to: @default_implementation

      defdelegate get_active(entity, context, options \\ %{}), to: @default_implementation
      defdelegate get_active!(entity, context, options \\ %{}), to: @default_implementation

      defdelegate update_active(entity, context, options \\ %{}), to: @default_implementation
      defdelegate update_active!(entity, context, options \\ %{}), to: @default_implementation

      defdelegate remove_active(entity, context, options \\ %{}), to: @default_implementation
      defdelegate remove_active!(entity, context, options \\ %{}), to: @default_implementation


      defdelegate init_article_info(entity, context, options \\ %{}), to: @default_implementation
      defdelegate init_article_info!(entity, context, options \\ %{}), to: @default_implementation

      defdelegate update_article_info(entity, context, options \\ %{}), to: @default_implementation
      defdelegate update_article_info!(entity, context, options \\ %{}), to: @default_implementation



      defdelegate get_versions(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate get_versions!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate get_revisions(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate get_revisions!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate create_version(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate create_version!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate update_version(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate update_version!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate delete_version(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate delete_version!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate create_revision(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate create_revision!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate update_revision(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate update_revision!(entity, context, options \\ %{}), to: @versioning_provider

      defdelegate delete_revision(entity, context, options \\ %{}), to: @versioning_provider
      defdelegate delete_revision!(entity, context, options \\ %{}), to: @versioning_provider

      #------------------
      # Repo Overrides
      #------------------
      defdelegate create(entity, context, options), to: @default_implementation
      defdelegate pre_create_callback(entity, context, options), to: @default_implementation
      defdelegate post_create_callback(entity, context, options), to: @default_implementation

      defdelegate _imp_get(module, entity, context, options), to: @default_implementation, as: :get
      defdelegate post_get_callback(entity, context, options), to: @default_implementation

      defdelegate update(entity, context, options), to: @default_implementation
      defdelegate pre_update_callback(entity, context, options), to: @default_implementation
      defdelegate post_update_callback(entity, context, options), to: @default_implementation

      defdelegate delete(entity, context, options), to: @default_implementation
      defdelegate pre_delete_callback(entity, context, options), to: @default_implementation
      defdelegate post_delete_callback(entity, context, options), to: @default_implementation

      defoverridable [
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
        initialize_versioning_records: 3,
        populate_versioning_records: 3,

        make_active: 3,
        make_active!: 3,

        update_active: 3,
        update_active!: 3,

        get_active: 3,
        get_active!: 3,

        remove_active: 3,
        remove_active!: 3,

        init_article_info: 3,
        init_article_info!: 3,

        update_article_info: 3,
        update_article_info!: 3,

        get_versions: 3,
        get_versions!: 3,

        create_version: 3,
        create_version!: 3,

        update_version: 3,
        update_version!: 3,

        delete_version: 3,
        delete_version!: 3,

        get_revisions: 3,
        get_revisions!: 3,

        create_revision: 3,
        create_revision!: 3,

        update_revision: 3,
        update_revision!: 3,

        delete_revision: 3,
        delete_revision!: 3,

        #------------------
        # Repo Behaviour
        #------------------
        create: 3,
        pre_create_callback: 3,
        post_create_callback: 3,

        _imp_get: 4,
        post_get_callback: 3,

        update: 3,
        pre_update_callback: 3,
        post_update_callback: 3,

        delete: 3,
        pre_delete_callback: 3,
        post_delete_callback: 3,
      ]
    end
  end
end