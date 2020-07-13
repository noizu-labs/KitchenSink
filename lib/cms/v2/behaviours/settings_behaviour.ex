#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.Cms.V2.SettingsBehaviour do
  defmodule RepoSettings do
    defmacro __using__(opts) do
      cms_option_settings = Macro.expand(opts[:option_settings], __CALLER__)
      cms_options = cms_option_settings.effective_options
      # Versioning Provider, etc.

      quote do
        @cms_repo_module __MODULE__
        @cms_repo_options unquote(Macro.escape(cms_options))
        @cms_repo_handler Module.concat(@cms_repo_module, CMS)

        @doc """
        retrieve effective compile time options/settings for pool.
        """
        def cms_options(), do: @cms_repo_options
        def cms_base(), do: @cms_repo_module
        def cms(), do: @cms_repo_handler

        defoverridable [
          cms_options: 0,
          cms_base: 0,
          cms: 0,
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

        defoverridable [
          cms_options: 0,
          cms_base: 0,
          cms: 0,
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

        defoverridable [
          cms_options: 0,
          cms_base: 0,
          cms: 0,
        ]
      end
    end
  end
end
