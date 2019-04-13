#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.EntityBehaviour do
  @callback versioning_provider() :: any
  @callback implementation_provider() :: any
  @callback cms_provider() :: any

  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Repo.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @behaviour Noizu.Cms.V2.EntityBehaviour
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))

      def versioning_provider(), do: @versioning_provider
      def implementation_provider(), do: @default_implementation
      def cms_provider(), do: @default_implementation.cms_provider(__MODULE__)

      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        cms_provider: 0
      ]

    end
  end
end