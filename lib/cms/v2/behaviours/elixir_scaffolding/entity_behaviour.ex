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
    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
          cms_base: %OptionValue{option: :cms_base, default: :auto},
        }
      }
      OptionSettings.expand(settings, options)
    end
  end


  defmacro __using__(options) do
    cms_implementation = Keyword.get(options || [], :implementation, Noizu.Cms.V2.EntityBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(options)
    quote do
      require Logger
      import unquote(__MODULE__)
      @cms_implementation unquote(cms_implementation)

      # Invoke EntityBehaviour before overriding defaults and adding CMS specific extensions.
      use Noizu.Scaffolding.V2.EntityBehaviour, unquote(options)
      use Noizu.Cms.V2.SettingsBehaviour.EntitySettings, unquote([option_settings: cms_option_settings])

      def version_path_to_string(version_path), do: cms_version().version_path_to_string(version_path)
      def string_to_id(identifier), do: cms_version().string_to_id(identifier)
      def id_to_string(identifier), do: cms_version().id_to_string(identifier)
      def article_string_to_id(identifier), do: cms_version().article_string_to_id(identifier)
      def article_id_to_string(identifier), do: cms_version().article_id_to_string(identifier)

      def cms_type(), do: :generic

      def article_info_entity(), do: Noizu.Cms.V2.Article.Info

      # @todo we need to modify entity/entity! to do a index lookup if only the raw id is exposed.
      # @todo we should add support here and elsewhere for {:version, {id, version}} references that like the above will perform active revision lookup to get the underlying entity.

      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        cms_type: 0,
        article_info_entity: 0,
        version_path_to_string: 1,
        string_to_id: 1,
        id_to_string: 1,
        article_string_to_id: 1,
        article_id_to_string: 1,
      ]
    end
  end
end
