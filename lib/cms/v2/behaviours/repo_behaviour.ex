#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.RepoBehaviour do


  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.DefaultRepoImplementation)

    quote do
      @default_implementation (unquote(implementation_provider))

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
      defdelegate get_version_history(entry, context, options), to: @default_implementation
      defdelegate get_version_history!(entry, context, options), to: @default_implementation
      defdelegate get_version(entry, version, context, options), to: @default_implementation
      defdelegate get_version!(entry, version, context, options), to: @default_implementation
      defdelegate get_all_versions(entry, context, options), to: @default_implementation
      defdelegate get_all_versions!(entry, context, options), to: @default_implementation
      defdelegate generate_version_hash(entry, version, context, options), to: @default_implementation
      defdelegate update_cms_tags(entry, context, options), to: @default_implementation
      defdelegate write_version_record(entry, context, options), to: @default_implementation
      defdelegate update_cms_master_table(entry, context, options), to: @default_implementation
      defdelegate delete_cms_records(entry, context, options), to: @default_implementation

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
      ]

    end
  end
end