#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.Cms.V2.Cms.RevisionBehaviour do
  defmodule Default do
    use Amnesia

    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
        }
      }
      OptionSettings.expand(settings, options)
    end

    #====================================
    # Functions
    #====================================

    #------------------------------
    #
    #------------------------------
    def new(entity, context, options, caller) do
      #options_a = put_in(options, [:active_revision], true)
      case caller.cms_revision().create(entity, context, options) do
        {:ok, revision} ->
          revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
          options_a = put_in(options, [:nested_versioning], true)
          entity
          |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options_a)
          |> caller.update(context, options_a)
        {:error, e} -> throw {:error, {:creating_revision, e}}
        e -> throw {:error, {:creating_revision, {:unknown, e}}}
      end
    end

    #------------------------------
    #
    #------------------------------
    def new!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms_revision().new(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def revisions(entity, context, options, _caller) do
      version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                    |> Noizu.ERP.ref()
      cond do
        version_ref ->
          Noizu.Cms.V2.Database.Version.RevisionTable.match([identifier: {version_ref, :_}])
          |> Amnesia.Selection.values()
          |> Enum.map(&(&1.entity))
        true -> {:error, :version_unknown}
      end
    end

    #------------------------------
    #
    #------------------------------
    def revisions!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms_revision().revisions(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def create(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      article_ref =  Noizu.Cms.V2.Proto.article_ref(article, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info(article, context, options)
      current_time = options[:current_time] || DateTime.utc_now()
      article_info = %Noizu.Cms.V2.Article.Info{article_info| modified_on: current_time, created_on: current_time}
      article = Noizu.Cms.V2.Proto.set_article_info(article, article_info, context, options)

      version = Noizu.Cms.V2.Proto.get_version(article, context, options)
      version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
      version_key = Noizu.Cms.V2.VersionEntity.id(version)

      cond do
        article == nil -> {:error, :invalid_record}
        version == nil -> {:error, :no_version_provided}
        true ->
          revision_key = options[:revision_key] || {version_ref, caller.cms_version().version_sequencer({:revision, version_key})}
          revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision_key)
          article = article
                    |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options)

          {archive_type, archive} = Noizu.Cms.V2.Proto.compress_archive(article, context, options)

          revision = %Noizu.Cms.V2.Version.RevisionEntity{
                       identifier: revision_key,
                       article: article_ref,
                       version: version_ref,
                       created_on: article_info.created_on,
                       modified_on: article_info.modified_on,
                       editor: article_info.editor,
                       status: article_info.status,
                       archive_type: archive_type,
                       archive: archive,
                     } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)

          case revision do
            %Noizu.Cms.V2.Version.RevisionEntity{} ->

              # Create Active Version Record.
              if options[:active_revision] do
                %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{
                  version: Noizu.Cms.V2.VersionEntity.ref(version_ref),
                  revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision_ref)
                } |> Noizu.Cms.V2.Database.Version.ActiveRevisionTable.write()
              end

              {:ok, revision}
            _ -> {:error, {:create_revision, revision}}
          end
      end
    end

    #------------------------
    #
    #------------------------
    def create!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms_revision().create(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def update(entity, context, options, caller) do
      article_ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)

      version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
      version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
      # version_key = Noizu.Cms.V2.VersionEntity.id(version)

      revision = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
      revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
      revision_key = Noizu.Cms.V2.Version.RevisionEntity.id(revision)

      cond do
        article_ref == nil -> {:error, :invalid_record}
        version == nil -> {:error, :no_version_provided}
        revision == nil -> {:error, :no_revision_provided}
        true ->
          # load existing record.
          revision = if revision = Noizu.Cms.V2.Version.RevisionEntity.entity(revision) do
            %Noizu.Cms.V2.Version.RevisionEntity{
              revision|
              article: article_ref,
              version: version_ref,
              modified_on: article_info.modified_on,
              editor: article_info.editor,
              status: article_info.status,
            } |> Noizu.Cms.V2.Version.RevisionRepo.update(context)
          else

            # insure ref,version correctly set before obtained qualified (Versioned) ref.
            article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
                      |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options)
                      |> Noizu.Cms.V2.Proto.set_version(version_ref, context, options)
            {archive_type, archive} = Noizu.Cms.V2.Proto.compress_archive(article, context, options)

            %Noizu.Cms.V2.Version.RevisionEntity{
              identifier: revision_key,
              article: article_ref,
              version: version_ref,
              created_on: article_info.created_on,
              modified_on: article_info.modified_on,
              editor: article_info.editor,
              status: article_info.status,
              archive_type: archive_type,
              archive: archive,
            } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)
          end


          # Create Active Version Record.
          if options[:active_revision] do
            %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{
              version: Noizu.Cms.V2.VersionEntity.ref(version_ref),
              revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision_ref)
            } |> Noizu.Cms.V2.Database.Version.ActiveRevisionTable.write()
          end

          # Update Active if modifying active revision
          if options[:bookkeeping] != :disabled do
            #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
            active_revision = caller.cms_index().get_active(entity, context, options)
            active_revision = active_revision && Noizu.ERP.ref(active_revision)
            if (active_revision && active_revision == revision_ref), do: caller.cms_index().update_active(entity, context, options)
            #end
          end
          # Return updated revision
          {:ok, revision}
      end
    end

    #------------------------------
    #
    #------------------------------
    def update!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms_revision().update(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def delete(entity, context, options, caller) do
      revision_ref = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
                     |> Noizu.ERP.ref()

      # Active Revision Check
      if options[:bookkeeping] != :disabled do
        #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
        active_revision = caller.cms_index().get_active(entity, context, options)
                          |> Noizu.ERP.ref()
        if (active_revision && active_revision == revision_ref), do: throw :cannot_delete_active
        #end
      end

      cond do
        revision_ref ->
          # Bypass Repo, delete directly for performance reasons.
          identifier = Noizu.ERP.id(revision_ref)
          Noizu.Cms.V2.Database.Version.RevisionTable.delete(identifier)
          :ok
        true -> {:error, :revision_not_set}
      end
    end

    #------------------------
    #
    #------------------------
    def delete!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms_revision().delete(entity, context, options) end)
    end

  end



  defmacro __using__(opts) do
    cms_revision_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.Cms.RevisionBehaviour.Default)
    cms_revision_option_settings = cms_revision_implementation.prepare_options(opts)

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_revision_implementation unquote(cms_revision_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_revision_option_settings])

      def revisions(entity, context, options \\ %{}), do: @cms_revision_implementation.revisions(entity, context, options, cms_base())
      def revisions!(entity, context, options \\ %{}), do: @cms_revision_implementation.revisions!(entity, context, options, cms_base())

      def create(entity, context, options \\ %{}), do: @cms_revision_implementation.create(entity, context, options, cms_base())
      def create!(entity, context, options \\ %{}), do: @cms_revision_implementation.create!(entity, context, options, cms_base())

      def update(entity, context, options \\ %{}), do: @cms_revision_implementation.update(entity, context, options, cms_base())
      def update!(entity, context, options \\ %{}), do: @cms_revision_implementation.update!(entity, context, options, cms_base())

      def delete(entity, context, options \\ %{}), do: @cms_revision_implementation.delete(entity, context, options, cms_base())
      def delete!(entity, context, options \\ %{}), do: @cms_revision_implementation.delete!(entity, context, options, cms_base())

      def new(entity, context, options \\ %{}), do: @cms_revision_implementation.new(entity, context, options, cms_base())
      def new!(entity, context, options \\ %{}), do: @cms_revision_implementation.new!(entity, context, options, cms_base())

      defoverridable [

        revisions: 2,
        revisions: 3,
        revisions!: 2,
        revisions!: 3,

        create: 2,
        create: 3,
        create!: 2,
        create!: 3,

        update: 2,
        update: 3,
        update!: 2,
        update!: 3,

        delete: 2,
        delete: 3,
        delete!: 2,
        delete!: 3,

        new: 2,
        new: 3,
        new!: 2,
        new!: 3,
      ]
    end
  end
end
