#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.DefaultRepoImplementation do

    # on CRUD actions update tags, versions, etc.
    def get_by_status(status, context, options \\ []) do
      []
    end

    def get_by_type(type, context, options \\ []) do
      []
    end

    def get_by_editor(type, context, options \\ []) do
      []
    end

    def get_by_tag(tag, context, options \\ []) do
      []
    end

    def get_by_created_on(from, to, context, options \\ []) do
      []
    end

    def get_by_modified_on(from, to, context, options \\ []) do
      []
    end

    def version_history(entry, context, options \\ []) do
      []
    end

    def get_version(entry, version, context, options \\ []) do
      nil
    end

    def save_entry(entry, context, options \\[]) do
      # Version handling . . .
    end

    def update_entry(entry, context, options \\[]) do
      # Version handling . . .
    end

    def delete_entry(entry, context, options \\[]) do
      # Version handling . . .
    end
    
end