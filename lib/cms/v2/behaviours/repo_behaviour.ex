#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.RepoBehaviour do


  @callback versioning_provider() :: any
  @callback implementation_provider() :: any

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

  # Repo Callback Overrides

  @callback versioning_provider() :: any

  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Repo.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @behaviour Noizu.Cms.V2.RepoBehaviour
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))


      def versioning_provider(), do: @versioning_provider
      def implementation_provider(), do: @default_implementation

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

      #---------------------------
      # Repo Callback Overrides
      #---------------------------
      defdelegate pre_create_callback(entity, context, options), to: @default_implementation
      defdelegate post_create_callback(entity, context, options), to: @default_implementation

      defdelegate post_get_callback(entity, context, options), to: @default_implementation

      defdelegate pre_update_callback(entity, context, options), to: @default_implementation
      defdelegate post_update_callback(entity, context, options), to: @default_implementation

      defdelegate pre_delete_callback(entity, context, options), to: @default_implementation
      defdelegate post_delete_callback(entity, context, options), to: @default_implementation

      defoverridable [
        versioning_provider: 0,

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
        # Call Back Overrides
        #-------------------
        pre_create_callback: 3,
        post_create_callback: 3,

        post_get_callback: 3,

        pre_update_callback: 3,
        post_update_callback: 3,

        pre_delete_callback: 3,
        post_delete_callback: 3,
      ]

    end
  end
end