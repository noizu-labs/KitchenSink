#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Cms.TagsBehaviour do
  defmodule Default do
    @moduledoc """
      Our default implementation just queries index tables. Alternative versions may query manticore/sphinx, etc. or other sources.
    """

    use Amnesia

    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList
    alias Noizu.Cms.V2.Database.TagTable
    use Noizu.Cms.V2.Database.TagTable

    @default_options %{
      expand: true,
      filter: false
    }

    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
        }
      }
      OptionSettings.expand(settings, options)
    end

    #----------------------------------
    # merge_options
    #----------------------------------
    def merge_options(nil), do: @default_options
    def merge_options(%{} = options), do: Map.merge(@default_options, options || %{})



    #-----------------------------
    # update/4
    #-----------------------------
    def update(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      new_tags = case Noizu.Cms.V2.Proto.tags(entity, context, options) do
        v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
        v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
        nil -> []
      end

      existing_tags = case TagTable.read(ref) do
        v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
        nil -> []
        v -> {:error, v}
      end

      if (new_tags != existing_tags) do
        # erase any existing tags
        TagTable.delete(ref)

        # insert new tags
        Enum.map(new_tags, fn(tag) ->
          %TagTable{article: ref, tag: tag} |> TagTable.write()
        end)
      end
    end

    #-----------------------------
    # update!/4
    #-----------------------------
    def update!(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      new_tags = case Noizu.Cms.V2.Proto.tags!(entity, context, options) do
        v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
        v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
        nil -> []
      end

      existing_tags = case TagTable.read!(ref) do
        v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
        nil -> []
        v -> {:error, v}
      end

      if (new_tags != existing_tags) do
        # erase any existing tags
        TagTable.delete!(ref)

        # insert new tags
        Enum.map(new_tags, fn(tag) ->
          %TagTable{article: ref, tag: tag} |> TagTable.write!()
        end)
      end
    end

    #-----------------------------
    # delete/4
    #-----------------------------
    def delete(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      # erase any existing tags
      TagTable.delete(ref)
    end

    #-----------------------------
    # delete!/4
    #-----------------------------
    def delete!(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      # erase any existing tags
      TagTable.delete!(ref)
    end



  end



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.Cms.TagsBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)
    # cms_options = cms_option_settings.effective_options

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])


      def update(entry, context, options \\ nil), do: @cms_implementation.update(entry, context, options, cms_base())
      def update!(entry, context, options \\ nil), do: @cms_implementation.update!(entry, context, options, cms_base())

      def delete(entry, context, options \\ nil), do: @cms_implementation.delete(entry, context, options, cms_base())
      def delete!(entry, context, options \\ nil), do: @cms_implementation.delete!(entry, context, options, cms_base())


      defoverridable [
        update: 2,
        update: 3,
        update!: 2,
        update!: 3,

        delete: 2,
        delete: 3,
        delete!: 2,
        delete!: 3,
      ]
    end
  end
end
