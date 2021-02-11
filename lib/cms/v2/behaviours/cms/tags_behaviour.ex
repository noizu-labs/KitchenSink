#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Cms.TagsBehaviour.Default do
  @moduledoc """
    Our default implementation just queries index tables. Alternative versions may query manticore/sphinx, etc. or other sources.
  """

  use Amnesia

  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  #alias Noizu.ElixirCore.OptionList


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
  # save_tags/5
  #-----------------------------
  def save_tags(entity, tags, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    # erase any existing tags
    caller.cms_tag_repo().mnesia_delete(ref)

    # insert new tags
    Enum.map(tags, fn(tag) ->
      caller.cms_tag_repo().new(%{tag: tag, article: ref}) |> caller.cms_tag_repo().mnesia_write()
    end)
  end

  #-----------------------------
  # save_tags!/5
  #-----------------------------
  def save_tags!(entity, tags, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    # erase any existing tags
    caller.cms_tag_repo().mnesia_delete!(ref)

    # insert new tags
    Enum.map(tags, fn(tag) ->
      caller.cms_tag_repo().new(%{tag: tag, article: ref}) |> caller.cms_tag_repo().mnesia_write!()
    end)
  end

  #-----------------------------
  # update/4
  #-----------------------------
  def update(entity, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    new_tags = case Noizu.Cms.V2.Proto.tags(entity, context, options) do
      v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
      v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
      nil -> []
    end

    existing_tags = caller.cms_tag_repo().article_tags(entity, context, options, caller)
    if (new_tags != existing_tags) do
      caller.cms_tag_repo().update_article_tags(entity, new_tags, context, options, caller)
    end
  end

  #-----------------------------
  # update!/4
  #-----------------------------
  def update!(entity, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    new_tags = case Noizu.Cms.V2.Proto.tags!(entity, context, options) do
      v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
      v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
      nil -> []
    end

    existing_tags = caller.cms_tag_repo().article_tags!(entity, context, options, caller)

    if (new_tags != existing_tags) do
      caller.cms_tag_repo().update_article_tags!(entity, new_tags, context, options, caller)
    end
  end

  #-----------------------------
  # delete/4
  #-----------------------------
  def delete(entity, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    # erase any existing tags
    caller.cms_tag_repo().mnesia_delete(ref)
  end

  #-----------------------------
  # delete!/4
  #-----------------------------
  def delete!(entity, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    # erase any existing tags
    caller.cms_tag_repo().mnesia_delete!(ref)
  end



end

defmodule Noizu.Cms.V2.Cms.TagsBehaviour do



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.Cms.TagsBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)
    # cms_options = cms_option_settings.effective_options

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])


      def save_tags(entity, tags, context, options \\ nil), do: @cms_implementation.save_tags(entity, tags, context, options, cms_base())
      def save_tags!(entity, tags, context, options \\ nil), do: @cms_implementation.save_tags!(entity, tags, context, options, cms_base())

      def update(entry, context, options \\ nil), do: @cms_implementation.update(entry, context, options, cms_base())
      def update!(entry, context, options \\ nil), do: @cms_implementation.update!(entry, context, options, cms_base())

      def delete(entry, context, options \\ nil), do: @cms_implementation.delete(entry, context, options, cms_base())
      def delete!(entry, context, options \\ nil), do: @cms_implementation.delete!(entry, context, options, cms_base())


      defoverridable [
        save_tags: 3,
        save_tags: 4,
        save_tags!: 3,
        save_tags!: 4,

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
