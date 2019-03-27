#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.RepoBehaviour do

  # todo required methods.

  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Repo.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))

      defdelegate expand_records(records, context, options), to: @default_implementation
      defdelegate expand_records!(records, context, options), to: @default_implementation
      defdelegate match_records(filter, context, options), to: @default_implementation
      defdelegate filter_records(records, context, options), to: @default_implementation
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


      defdelegate get_version_history(entry, context, options), to: @versioning_provider
      defdelegate get_version_history!(entry, context, options), to: @versioning_provider
      defdelegate get_version(entry, version, context, options), to: @versioning_provider
      defdelegate get_version!(entry, version, context, options), to: @versioning_provider
      defdelegate get_all_versions(entry, context, options), to: @versioning_provider
      defdelegate get_all_versions!(entry, context, options), to: @versioning_provider
      defdelegate generate_version_hash(entry, version, context, options), to: @versioning_provider
      defdelegate write_version_record(entry, context, options), to: @versioning_provider

      defdelegate update_cms_tags(entry, context, options), to: @default_implementation
      defdelegate update_cms_master_table(entry, context, options), to: @default_implementation
      defdelegate delete_cms_records(entry, context, options), to: @default_implementation

      #---------------------------
      # Repo Callback Overrides
      #---------------------------
      defdelegate pre_create_callback(entity, context, options), to: @default_implementation
      defdelegate pre_update_callback(entity, context, options), to: @default_implementation
      defdelegate pre_delete_callback(entity, context, options), to: @default_implementation
      defdelegate post_create_callback(entity, context, options), to: @default_implementation
      defdelegate post_get_callback(entity, context, options), to: @default_implementation
      defdelegate post_update_callback(entity, context, options), to: @default_implementation
      defdelegate post_delete_callback(entity, context, options), to: @default_implementation

      defoverridable [
        expand_records: 3,
        expand_records!: 3,
        match_records: 3,
        filter_records: 3,
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
        get_version_history: 3,
        get_version_history!: 3,
        get_version: 4,
        get_version!: 4,
        get_all_versions: 3,
        get_all_versions!: 3,
        generate_version_hash: 4,
        update_cms_tags: 3,
        write_version_record: 3,
        update_cms_master_table: 3,
        delete_cms_records: 3,

        pre_create_callback: 3,
        pre_update_callback: 3,
        pre_delete_callback: 3,
        post_create_callback: 3,
        post_get_callback: 3,
        post_update_callback: 3,
        post_delete_callback: 3,
      ]

    end
  end
end