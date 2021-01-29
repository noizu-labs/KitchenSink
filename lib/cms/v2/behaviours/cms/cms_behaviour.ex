#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.CmsBehaviour.Default do
  use Amnesia

  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue

  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        verbose: %OptionValue{option: :verbose, default: false},
        query_module: %OptionValue{option: :query_module, default: Noizu.Cms.V2.Cms.QueryBehaviour},
        version_module: %OptionValue{option: :version_module, default: Noizu.Cms.V2.Cms.VersionBehaviour},
        revision_module: %OptionValue{option: :revision_module, default: Noizu.Cms.V2.Cms.RevisionBehaviour},
        tags_module: %OptionValue{option: :tags_module, default: Noizu.Cms.V2.Cms.TagsBehaviour},
        index_module: %OptionValue{option: :index_module, default: Noizu.Cms.V2.Cms.IndexBehaviour},
        query_module_options: %OptionValue{option: :query_module_options, default: []},
        version_module_options: %OptionValue{option: :version_module_options, default: []},
        revision_module_options: %OptionValue{option: :revision_module_options, default: []},
        tags_module_options: %OptionValue{option: :tags_module_options, default: []},
        index_module_options: %OptionValue{option: :index_module_options, default: []},
      }
    }
    OptionSettings.expand(settings, options)
  end
end


defmodule Noizu.Cms.V2.CmsBehaviour do



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.CmsBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)

    cms_options = cms_option_settings.effective_options
    query_module = cms_options.query_module
    version_module = cms_options.version_module
    revision_module = cms_options.revision_module
    tags_module = cms_options.tags_module
    index_module = cms_options.index_module




    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])

      if (unquote(query_module)) do
        defmodule Query do
          use unquote(query_module), unquote(cms_options.query_module_options)
        end
      end

      if (unquote(version_module)) do
        defmodule Version do
          use unquote(version_module), unquote(cms_options.version_module_options)
        end
      end

      if (unquote(revision_module)) do
        defmodule Revision do
          use unquote(revision_module), unquote(cms_options.revision_module_options)
        end
      end

      if (unquote(tags_module)) do
        defmodule Tags do
          use unquote(tags_module), unquote(cms_options.tags_module_options)
        end
      end

      if (unquote(index_module)) do
        defmodule Index do
          use unquote(index_module), unquote(cms_options.index_module_options)
        end
      end

      # defoverridable []

    end
  end
end
