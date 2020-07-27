#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.EntityBehaviour do

  @moduledoc """
    Extends Noizu.Scaffolding.V2.EntityBehaviour provider. Accepts same options as the vanilla Noizu.Scaffolding.V2.RepoBehaviour invokes
    `use Noizu.Scaffolding.V2.EntityBehaviour` before overriding default CRUD methods and adding additional ObjectRepo.CMS namespace and CMS protocol functions.

  """


  defmodule Default do
    use Amnesia

    #alias Noizu.Cms.V2.Database.IndexTable
    #alias Noizu.Cms.V2.Database.VersionTable
    #alias Noizu.Cms.V2.Database.TagTable

    use Noizu.Cms.V2.Database.IndexTable
    use Noizu.Cms.V2.Database.VersionTable
    use Noizu.Cms.V2.Database.TagTable


    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    @revision_format ~r/^(.*)@([0-9a-zA-Z][0-9a-zA-Z\.]*)-([0-9a-zA-Z]+)$/
    @version_format ~r/^(.*)@([0-9a-zA-Z][0-9a-zA-Z\.]*)$/

    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
          cms_base: %OptionValue{option: :cms_base, default: :auto},
          version_entity: %OptionValue{option: :version_entity, default: Noizu.Cms.V2.VersionEntity},
          version_repo: %OptionValue{option: :version_repo, default: Noizu.Cms.V2.VersionRepo},

          #cms_module: %OptionValue{option: :cms_module, default: Noizu.Cms.V2.CmsBehaviour},
          #cms_module_options: %OptionValue{option: :cms_module_options, default: []},

          # Tag Provider
          # Index Provider
          # Version Provider
        }
      }
      OptionSettings.expand(settings, options)
    end

    # @todo modify to allow overriding just article_string_to_id, article_id_to_string()

  end


  defmacro __using__(options) do
    cms_implementation = Keyword.get(options || [], :implementation, Noizu.Cms.V2.EntityBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(options)
    quote do
      import unquote(__MODULE__)
      require Logger


      # Invoke EntityBehaviour before overriding defaults and adding CMS specific extensions.
      use Noizu.Scaffolding.V2.EntityBehaviour, unquote(options)



      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.EntitySettings, unquote([option_settings: cms_option_settings])

      def version_path_to_string(version_path), do: cms_version().version_path_to_string(version_path)
      def string_to_id(identifier), do: cms_version().string_to_id(identifier)
      def id_to_string(identifier), do: cms_version().id_to_string(identifier)
      def article_string_to_id(identifier), do: cms_version().article_string_to_id(identifier)
      def article_id_to_string(identifier), do: cms_version().article_id_to_string(identifier)

      # @todo we need to modify entity/entity! to do a index lookup if only the raw id is exposed.
      # @todo we should add support here and elsewhere for {:version, {id, version}} references that like the above will perform active revision lookup to get the underlying entity.

      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        version_path_to_string: 1,
        string_to_id: 1,
        id_to_string: 1,
        article_string_to_id: 1,
        article_id_to_string: 1,
      ]

    end
  end
end
