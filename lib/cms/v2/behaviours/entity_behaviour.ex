#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.EntityBehaviour do

  @callback versioning_provider() :: any
  @callback implementation_provider() :: any

  @callback get_versions() :: any
  @callback get_versions!() :: any

  @callback get_revisions() :: any
  @callback get_revisions!() :: any

  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Repo.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @behaviour Noizu.Cms.V2.EntityBehaviour
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))

      def versioning_provider(), do: @versioning_provider
      def implementation_provider(), do: @default_implementation

      #-------------------------
      # Versioning Related.
      #-------------------------
      defdelegate get_versions(entry, context, options), to: @versioning_provider
      defdelegate get_versions!(entry, context, options), to: @versioning_provider

      defdelegate get_revisions(entry, context, options), to: @versioning_provider
      defdelegate get_revisions!(entry, context, options), to: @versioning_provider

      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        get_versions: 3,
        get_versions!: 3,
        get_revisions: 3,
        get_revisions!: 3,
      ]

    end
  end
end