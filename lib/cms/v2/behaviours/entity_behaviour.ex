#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.EntityBehaviour do
  @callback versioning_provider() :: any
  @callback implementation_provider() :: any
  @callback cms_provider() :: any

  defmacro __using__(options) do
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Cms.V2.Entity.DefaultImplementation)
    versioning_provider = Keyword.get(options, :versioning_provider,  Noizu.Cms.V2.VersioningProvider.DefaultImplementation)

    quote do
      @behaviour Noizu.Cms.V2.EntityBehaviour
      @default_implementation (unquote(implementation_provider))
      @versioning_provider (unquote(versioning_provider))

      def versioning_provider(), do: @versioning_provider
      def implementation_provider(), do: @default_implementation
      def cms_provider(), do: __MODULE__.repo() # @note provider may not always be repo.

      defdelegate string_to_id(identifier), to: @default_implementation
      defdelegate id_to_string(identifier), to: @default_implementation

      defdelegate article_string_to_id(identifier), to: @default_implementation
      defdelegate article_id_to_string(identifier), to: @default_implementation

      # @todo we need to modify entity/entity! to do a index lookup if only the raw id is exposed.
      # @todo we should add support here and elsewhere for {:version, {id, version}} references that like the above will perform active revision lookup to get the underlying entity.


      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        cms_provider: 0,
        string_to_id: 1,
        id_to_string: 1,
        article_string_to_id: 1,
        article_id_to_string: 1,
      ]

    end
  end
end