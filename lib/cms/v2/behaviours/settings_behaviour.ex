#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.Cms.V2.SettingsBehaviour do
  defmodule RepoSettings do
    defmacro __using__(opts) do
      cms_option_settings = Macro.expand(opts[:option_settings], __CALLER__)
      cms_options = cms_option_settings.effective_options

      tag_repo = cms_options.tag_repo
      index_repo = cms_options.index_repo
      version_entity = cms_options.version_entity
      version_repo = cms_options.version_repo
      revision_entity = cms_options.revision_entity
      revision_repo = cms_options.revision_repo
      # Versioning Provider, etc.

      quote do
        @cms_repo_module __MODULE__
        @cms_repo_options unquote(Macro.escape(cms_options))
        @cms_repo_handler Module.concat(@cms_repo_module, CMS)
        @cms_version_handler Module.concat(@cms_repo_handler, Version)
        @cms_revision_handler Module.concat(@cms_repo_handler, Revision)
        @cms_query_handler Module.concat(@cms_repo_handler, Query)
        @cms_index_handler Module.concat(@cms_repo_handler, Index)
        @cms_tag_handler Module.concat(@cms_repo_handler, Tags)


        @cms_tag_repo unquote(tag_repo)
        @cms_index_repo unquote(index_repo)
        @cms_version_entity unquote(version_entity)
        @cms_version_repo unquote(version_repo)
        @cms_revision_entity unquote(revision_entity)
        @cms_revision_repo unquote(revision_repo)

        @doc """
        retrieve effective compile time options/settings for pool.
        """
        def cms_options(), do: @cms_repo_options
        def cms_base(), do: @cms_repo_module
        def cms(), do: @cms_repo_handler
        def cms_version(), do: @cms_version_handler
        def cms_revision(), do: @cms_revision_handler
        def cms_query(), do: @cms_query_handler
        def cms_index(), do: @cms_index_handler
        def cms_tags(), do: @cms_tag_handler

        def cms_index_repo(), do: @cms_index_repo
        def cms_tag_repo(), do: @cms_tag_repo
        def cms_version_entity(), do: @cms_version_entity
        def cms_version_repo(), do: @cms_version_repo
        def cms_revision_entity(), do: @cms_revision_entity
        def cms_revision_repo(), do: @cms_revision_repo




        defoverridable [
          cms_options: 0,
          cms_base: 0,
          cms: 0,
          cms_version: 0,
          cms_revision: 0,
          cms_query: 0,
          cms_index: 0,
          cms_tags: 0,

          cms_index_repo: 0,
          cms_tag_repo: 0,
          cms_version_entity: 0,
          cms_version_repo: 0,
          cms_revision_entity: 0,
          cms_revision_repo: 0,
        ]
      end
    end
  end



  defmodule EntitySettings do
    defmacro __using__(opts) do
      cms_option_settings = Macro.expand(opts[:option_settings], __CALLER__)
      cms_options = cms_option_settings.effective_options
      cms_base = cms_options.cms_base
      # Versioning Provider, etc.
      quote do
        @cms_entity_source (case unquote(cms_base) do
                              :auto ->
                                a = Module.split(__MODULE__) |> Enum.slice(0.. -2) |> Module.concat()
                                b = Module.split(__MODULE__) |> List.last()
                                Module.concat(a, String.slice("#{b}", 0..-7) <> "Repo")
                              v -> v
                            end)

        @doc """
        retrieve effective compile time options/settings for pool.
        """
        defdelegate cms_options(), to: @cms_entity_source
        defdelegate cms_base(), to: @cms_entity_source
        defdelegate cms(), to: @cms_entity_source
        defdelegate cms_version(), to: @cms_entity_source
        defdelegate cms_revision(), to: @cms_entity_source
        defdelegate cms_query(), to: @cms_entity_source
        defdelegate cms_index(), to: @cms_entity_source
        defdelegate cms_tags(), to: @cms_entity_source


        defdelegate cms_tag_repo(), to: @cms_entity_source
        defdelegate cms_index_repo(), to: @cms_entity_source
        defdelegate cms_version_entity(), to: @cms_entity_source
        defdelegate cms_version_repo(), to: @cms_entity_source
        defdelegate cms_revision_entity(), to: @cms_entity_source
        defdelegate cms_revision_repo(), to: @cms_entity_source

        defoverridable [
          cms_options: 0,
          cms_base: 0,
          cms: 0,
          cms_version: 0,
          cms_revision: 0,
          cms_query: 0,
          cms_index: 0,
          cms_tags: 0,

          cms_index_repo: 0,
          cms_tag_repo: 0,
          cms_version_entity: 0,
          cms_version_repo: 0,
          cms_revision_entity: 0,
          cms_revision_repo: 0,
        ]
      end
    end
  end

  defmodule InheritedSettings do
    defmacro __using__(_opts) do
      quote do
        @cms_parent Module.split(__MODULE__) |> Enum.slice(0.. -2) |> Module.concat()

        @doc """
        retrieve effective compile time options/settings for pool.
        """
        defdelegate cms_options(), to: @cms_parent
        defdelegate cms_base(), to: @cms_parent
        defdelegate cms(), to: @cms_parent
        defdelegate cms_version(), to: @cms_parent
        defdelegate cms_revision(), to: @cms_parent
        defdelegate cms_query(), to: @cms_parent
        defdelegate cms_index(), to: @cms_parent
        defdelegate cms_tags(), to: @cms_parent

        defdelegate cms_tag_repo(), to: @cms_parent
        defdelegate cms_index_repo(), to: @cms_parent
        defdelegate cms_version_entity(), to: @cms_parent
        defdelegate cms_version_repo(), to: @cms_parent
        defdelegate cms_revision_entity(), to: @cms_parent
        defdelegate cms_revision_repo(), to: @cms_parent



        defoverridable [
          cms_options: 0,
          cms_base: 0,
          cms: 0,
          cms_version: 0,
          cms_revision: 0,
          cms_query: 0,
          cms_index: 0,
          cms_tags: 0,

          cms_index_repo: 0,
          cms_tag_repo: 0,
          cms_version_entity: 0,
          cms_version_repo: 0,
          cms_revision_entity: 0,
          cms_revision_repo: 0,
        ]
      end
    end
  end
end
