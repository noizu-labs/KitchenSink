#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersioningProvider.DefaultProvider do
  defmacro __using__(options) do
    index_table = Keyword.get(options, :index_table, Noizu.Cms.V2.Database.IndexTable)
    version_table = Keyword.get(options, :version_table, Noizu.Cms.V2.Database.VersionTable)
    tag_table = Keyword.get(options, :tag_table, Noizu.Cms.V2.Database.TagTable)
    version_sequencer_table = Keyword.get(options, :version_sequencer_table, Noizu.Cms.V2.Database.VersionSequencerTable)

    quote do

      use Amnesia
      alias unquote(index_table), as: IndexTable
      alias unquote(version_table), as: VersionTable
      alias unquote(tag_table), as: TagTable
      alias unquote(version_sequencer_table), as: VersionSequencerTable

      use Amnesia
      use IndexTable
      use TagTable
      use VersionTable
      use VersionSequencerTable

      # @behaviour Noizu.Cms.V2.VersioningProviderBehaviour

      #===========================================================
      # Implementation of Behaviour
      #===========================================================

      #------------------------------
      # new_version/4
      #------------------------------
      def new_version(entity, context, options, caller) do
        options_a = put_in(options, [:active_revision], true)
        case caller.create_version(entity, context, options_a) do
          {:ok, {version, revision}} ->
            version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
            revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
            repo = entity.__struct__.repo()
            options_b = put_in(options_a, [:nested_versioning], true)
            entity
            |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options_b)
            |> Noizu.Cms.V2.Proto.set_version(version_ref, context, options_b)
            |> Noizu.Cms.V2.Proto.set_parent(version.parent, context, options_b)
            |> repo.update(context, options_a)
          {:error, e} -> throw {:error, {:creating_revision, e}}
          e -> throw {:error, {:creating_revision, {:unknown, e}}}
        end
      end

      #------------------------------
      #
      #------------------------------
      def new_version!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.new_version(entity, context, options) end)
      end

      #------------------------------
      #
      #------------------------------
      def new_revision(entity, context, options, caller) do
        #options_a = put_in(options, [:active_revision], true)
        case caller.create_revision(entity, context, options) do
          {:ok, revision} ->
            revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
            repo = entity.__struct__.repo()
            options_a = put_in(options, [:nested_versioning], true)
            entity
            |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options_a)
            |> repo.update(context, options_a)
          {:error, e} -> throw {:error, {:creating_revision, e}}
          e -> throw {:error, {:creating_revision, {:unknown, e}}}
        end
      end

      #------------------------------
      #
      #------------------------------
      def new_revision!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.new_revision(entity, context, options) end)
      end

      #------------------------------
      #
      #------------------------------
      def initialize_versioning_records(entity, context, options, caller) do
        options = put_in(options, [:active_revision], true)
        case caller.create_version(entity, context, options) do
          {:ok, {version, revision}} ->
            entity = entity
                     |> Noizu.Cms.V2.Proto.set_version(Noizu.Cms.V2.VersionEntity.ref(version), context, options)
                     |> Noizu.Cms.V2.Proto.set_revision(Noizu.Cms.V2.Version.RevisionEntity.ref(revision), context, options)
                     |> Noizu.Cms.V2.Proto.set_parent(Noizu.Cms.V2.VersionEntity.ref(version.parent), context, options)
            v_id = Noizu.Cms.V2.Proto.versioned_identifier(entity, context, options)
            entity = entity
                     |> put_in([Access.key(:identifier)], v_id)


            if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
              cms_provider.update_tags(entity, context, options)
              cms_provider.update_index(entity, context, options)
            end
            entity
          e -> throw "initialize_versioning_records error: #{inspect e}"
        end
      end

      #------------------------------
      #
      #------------------------------
      def populate_versioning_records(entity, context, options, caller) do
        if options[:nested_versioning] do
          entity
        else

          version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
          version_ref = Noizu.Cms.V2.VersionEntity.ref(version)

          revision = Noizu.Cms.V2.Proto.get_version(entity, context, options)
          revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)

          # if active revision then update version table, otherwise only update revision.
          case Noizu.Cms.V2.Database.Version.ActiveRevisionTable.read(version_ref) do
            %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{revision: active_revision_ref} ->

              if active_revision_ref == revision_ref || options[:active_revision] == true do
                case caller.update_version(entity, context, options) do
                  {:ok, _} ->
                    entity
                  e -> throw "populate_versioning_records error: #{inspect e}"
                end
              else
                case caller.update_revision(entity, context, options) do
                  {:ok, _} ->
                    entity
                  e -> throw "populate_versioning_records error: #{inspect e}"
                end
              end

            _ ->
              options_a = put_in(options, [:active_revision], true)
              case caller.update_version(entity, context, options_a) do
                {:ok, _} ->
                  entity
                e -> throw "populate_versioning_records error: #{inspect e}"
              end
          end
        end
      end

      #------------------------
      #
      #------------------------
      def get_versions(entity, context, options, _caller) do
        article_ref = Noizu.Cms.V2.Proto.get_article(entity, context, options)
                      |> Noizu.ERP.ref()
        cond do
          article_ref ->
            Noizu.Cms.V2.Database.VersionTable.match([identifier: {article_ref, :_}])
            |> Amnesia.Selection.values()
            |> Enum.map(&(&1.entity))
          true -> {:error, :article_unknown}
        end
      end

      #------------------------------
      #
      #------------------------------
      def get_versions!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.get_versions(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def create_version(entity, context, options, caller) do
        article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
        article_ref =  Noizu.Cms.V2.Proto.article_ref(article, context, options)

        # 1. get current version.
        current_version = Noizu.Cms.V2.Proto.get_version(article, context, options)
        current_version_ref = Noizu.Cms.V2.VersionEntity.ref(current_version)

        # 2. Determine version path we will be creating
        new_version_path = cond do
          current_version == nil ->
            {version_sequencer({article_ref, {}})}
          true ->
            {:ref, _, {_article, path}} = current_version_ref
            List.to_tuple(Tuple.to_list(path) ++ [version_sequencer({article_ref, path})])
        end

        # 3. Create Version Stub
        new_version_key = {article_ref, new_version_path}
        new_version_ref = Noizu.Cms.V2.VersionEntity.ref(new_version_key)

        article = article
                  |> Noizu.Cms.V2.Proto.set_version(new_version_key, context, options)
                  |> Noizu.Cms.V2.Proto.set_parent(current_version_ref, context, options)
                  |> Noizu.Cms.V2.Proto.set_revision(nil, context, options)

        case caller.create_revision(article, context, options) do
          {:ok, revision} ->
            # Create Version Record
            version = %Noizu.Cms.V2.VersionEntity{
                        identifier: new_version_key,
                        article: article_ref,
                        parent: current_version_ref,
                        created_on: revision.created_on,
                        modified_on: revision.modified_on,
                        editor: revision.editor,
                        status: revision.status,
                      } |> Noizu.Cms.V2.VersionRepo.create(context, options)
            {:ok, {version, revision}}

          {:error, e} -> {:error, {:creating_revision, e}}
          e -> {:error, {:creating_revision, {:unknown, e}}}
        end
      end

      #------------------------------
      #
      #------------------------------
      def create_version!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.create_version(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def update_version(entity, context, options, caller) do
        # 1. get current version.
        current_version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                          |> Noizu.Cms.V2.VersionEntity.entity()

        cond do
          current_version == nil -> {:error, :invalid_version}
          true ->
            case caller.update_revision(entity, context, options) do
              {:ok, revision} ->
                version = %Noizu.Cms.V2.VersionEntity{
                            current_version|
                            modified_on: revision.modified_on,
                            editor: revision.editor,
                            status: revision.status,
                          } |> Noizu.Cms.V2.VersionRepo.update(context, options)
                {:ok, {version, revision}}
              _ -> {:error, :update_revision}
            end
        end
      end

      #------------------------------
      #
      #------------------------------
      def update_version!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.update_version(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def delete_version(entity, context, options, caller) do
        version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                      |> Noizu.ERP.ref()

        # Active Revision Check
        if options[:bookkeeping] != :disabled do
          if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
            if active_revision = cms_provider.get_active(entity, context, options) do
              active_version = Noizu.Cms.V2.Proto.get_version(active_revision, context, options)
                               |> Noizu.ERP.ref()
              if (active_version && active_version == version_ref), do: throw :cannot_delete_active
            end
          end
        end

        cond do
          version_ref ->
            # Get revisions,
            case caller.get_revisions(entity, context, options) do
              revisions when is_list(revisions) ->
                # delete active revision mapping.
                Noizu.Cms.V2.Database.Version.ActiveRevisionTable.delete(version_ref)

                # Delete Revisions
                Enum.map(revisions, fn(revision) ->
                  # Bypass Repo, delete directly for performance reasons.
                  Noizu.Cms.V2.Database.Version.RevisionTable.delete(revision.identifier)
                end)

                # Delete Version
                # Bypass Repo, delete directly for performance reasons.
                identifier = Noizu.ERP.id(version_ref)
                Noizu.Cms.V2.Database.VersionTable.delete(identifier)

                :ok
              _ -> {:error, :revision_lookup}
            end
          true -> {:error, :revision_not_set}
        end
      end

      #------------------------
      #
      #------------------------
      def delete_version!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.delete_version(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def get_revisions(entity, context, options, caller) do
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
      def get_revisions!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.get_revisions(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def create_revision(entity, context, options, caller) do
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
            revision_key = options[:revision_key] || {version_ref, version_sequencer({:revision, version_key})}
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
      def create_revision!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.create_revision(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def update_revision(entity, context, options, caller) do
        article_ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
        article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)

        version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
        version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
        version_key = Noizu.Cms.V2.VersionEntity.id(version)

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
              if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
                active_revision = cms_provider.get_active(entity, context, options)
                active_revision = active_revision && Noizu.ERP.ref(active_revision)
                if (active_revision && active_revision == revision_ref), do: cms_provider.update_active(entity, context, options)
              end
            end
            # Return updated revision
            {:ok, revision}
        end
      end

      #------------------------------
      #
      #------------------------------
      def update_revision!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.update_revision(entity, context, options) end)
      end

      #------------------------
      #
      #------------------------
      def delete_revision(entity, context, options, caller) do
        revision_ref = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
                       |> Noizu.ERP.ref()

        # Active Revision Check
        if options[:bookkeeping] != :disabled do
          if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
            active_revision = cms_provider.get_active(entity, context, options)
                              |> Noizu.ERP.ref()
            if (active_revision && active_revision == revision_ref), do: throw :cannot_delete_active
          end
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
      def delete_revision!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.delete_revision(entity, context, options) end)
      end

      #===========================================================
      # Supporting
      #===========================================================

      #----------------------------------
      # version_sequencer/1
      #----------------------------------
      def version_sequencer(key) do
        case Noizu.Cms.V2.Database.VersionSequencerTable.read(key) do
          v = %Noizu.Cms.V2.Database.VersionSequencerTable{} ->
            %Noizu.Cms.V2.Database.VersionSequencerTable{v| sequence: v.sequence + 1}
            |> Noizu.Cms.V2.Database.VersionSequencerTable.write()
            v.sequence + 1
          nil ->
            %Noizu.Cms.V2.Database.VersionSequencerTable{identifier: key, sequence: 1}
            |> Noizu.Cms.V2.Database.VersionSequencerTable.write()
            1
        end
      end

      #----------------------------------
      # version_sequencer!/1
      #----------------------------------
      def version_sequencer!(key) do
        Amnesia.transaction do
          version_sequencer(key)
        end
      end



      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        new_version: 4,
      ]

    end
  end
end
