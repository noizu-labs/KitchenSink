#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Cms.QueryBehaviour.Default do
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

  #----------------------------------
  # by_status/4
  #----------------------------------
  def by_status(status, context, options, caller) do
    caller.cms_index().query_by(:status, status, context, merge_options(options))
  end

  #----------------------------------
  # by_status!/4
  #----------------------------------
  def by_status!(status, context, options, caller) do
    caller.cms_index().query_by!(:status, status, context, merge_options(options))
  end

  #----------------------------------
  # by_type/4
  #----------------------------------
  def by_type(type, context, options, caller) do
    caller.cms_index().query_by(:type, type, context, merge_options(options))
  end

  #----------------------------------
  # by_type!/4
  #----------------------------------
  def by_type!(type, context, options, caller) do
    caller.cms_index().query_by!(:type, type, context, merge_options(options))
  end

  #----------------------------------
  # by_module/4
  #----------------------------------
  def by_module(module, context, options, caller) do
    caller.cms_index().query_by(:module, module, context, merge_options(options))
  end

  #----------------------------------
  # by_module!/4
  #----------------------------------
  def by_module!(module, context, options, caller) do
    caller.cms_index().query_by!(:module, module, context, merge_options(options))
  end

  #----------------------------------
  # by_editor/4
  #----------------------------------
  def by_editor(editor, context, options, caller) do
    caller.cms_index().query_by(:editor, editor, context, merge_options(options))
  end

  #----------------------------------
  # by_editor!/4
  #----------------------------------
  def by_editor!(editor, context, options, caller) do
    caller.cms_index().query_by!(:editor, editor, context, merge_options(options))
  end

  #----------------------------------
  # by_tag/4
  #----------------------------------
  def by_tag(tag, context, options, caller) do
    options = merge_options(options)
    tag
    |> caller.cms_tags().articles_by_tag(context, options)
    |> caller.cms_index().filter_set(context, options)
  end

  #----------------------------------
  # by_tag!/4
  #----------------------------------
  def by_tag!(tag, context, options, caller) do
    options = merge_options(options)
    tag
    |> caller.cms_tags().articles_by_tag!(context, options)
    |> caller.cms_index().filter_set!(context, options)
    # Note previous iteration threw on empty map sets.
  end

  #----------------------------------
  # by_created_on/5
  #----------------------------------
  def by_created_on(from, to, context, options, caller) do
    caller.cms_index().by_created_on(from, to, context, options, merge_options(options))
  end

  #----------------------------------
  # by_created_on!/4
  #-----------------------5----------
  def by_created_on!(from, to, context, options, caller) do
    caller.cms_index().by_created_on!(from, to, context, options, merge_options(options))
  end

  #----------------------------------
  # by_modified_on/5
  #----------------------------------
  def by_modified_on(from, to, context, options, caller) do
    caller.cms_index().by_modified_on(from, to, context, options, merge_options(options))
  end

  #----------------------------------
  # by_modified_on!/5
  #----------------------------------
  def by_modified_on!(from, to, context, options, caller) do
    caller.cms_index().by_modified_on!(from, to, context, options, merge_options(options))
  end
end

defmodule Noizu.Cms.V2.Cms.QueryBehaviour do



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.Cms.QueryBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)
    # cms_options = cms_option_settings.effective_options

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])

      #-------------------------
      # Query
      #-------------------------
      def by_status(status, context, options \\ %{}), do: @cms_implementation.by_status(status, context, options, cms_base())
      def by_status!(status, context, options \\ %{}), do: @cms_implementation.by_status!(status, context, options, cms_base())

      def by_type(type, context, options \\ %{}), do: @cms_implementation.by_type(type, context, options, cms_base())
      def by_type!(type, context, options \\ %{}), do: @cms_implementation.by_type!(type, context, options, cms_base())

      def by_module(module, context, options \\ %{}), do: @cms_implementation.by_module(module, context, options, cms_base())
      def by_module!(module, context, options \\ %{}), do: @cms_implementation.by_module!(module, context, options, cms_base())

      def by_editor(editor, context, options \\ %{}), do: @cms_implementation.by_editor(editor, context, options, cms_base())
      def by_editor!(editor, context, options \\ %{}), do: @cms_implementation.by_editor!(editor, context, options, cms_base())

      def by_tag(tag, context, options \\ %{}), do: @cms_implementation.by_tag(tag, context, options, cms_base())
      def by_tag!(tag, context, options \\ %{}), do: @cms_implementation.by_tag!(tag, context, options, cms_base())

      def by_created_on(from, to, context, options \\ %{}), do: @cms_implementation.by_created_on(from, to, context, options, cms_base())
      def by_created_on!(from, to, context, options \\ %{}), do: @cms_implementation.by_created_on!(from, to, context, options, cms_base())

      def by_modified_on(from, to, context, options \\ %{}), do: @cms_implementation.by_modified_on(from, to, context, options, cms_base())
      def by_modified_on!(from, to, context, options \\ %{}), do: @cms_implementation.by_modified_on!(from, to, context, options, cms_base())

      defoverridable [
        by_status: 2,
        by_status: 3,

        by_status!: 2,
        by_status!: 3,

        by_type: 2,
        by_type: 3,

        by_type!: 2,
        by_type!: 3,

        by_module: 2,
        by_module: 3,

        by_module!: 2,
        by_module!: 3,

        by_editor: 2,
        by_editor: 3,

        by_editor!: 2,
        by_editor!: 3,

        by_tag: 2,
        by_tag: 3,

        by_tag!: 2,
        by_tag!: 3,

        by_created_on: 3,
        by_created_on: 4,

        by_created_on!: 3,
        by_created_on!: 4,

        by_modified_on: 3,
        by_modified_on: 4,

        by_modified_on!: 3,
        by_modified_on!: 4,
      ]
    end
  end
end
