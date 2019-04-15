#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersioningProvider.DefaultImplementation do
  use Amnesia
  use Noizu.Cms.V2.Database.IndexTable
  use Noizu.Cms.V2.Database.TagTable
  use Noizu.Cms.V2.Database.VersionTable

  #alias Noizu.Cms.V2.Database.VersionTable
  #alias Noizu.Cms.V2.VersionRepo
  #alias Noizu.Cms.V2.VersionEntity

  @behaviour Noizu.Cms.V2.VersioningProviderBehaviour
  #@default_options %{expand: true, filter: false}

  #===========================================================
  # Implementation of Behaviour
  #===========================================================

  def initialize_versioning_records(entity, context, options \\ %{}) do
    # Create Version Record
    # Create Revision Record (@todo consider removing revision table, and depend on master table.)
    # Use revision form identifier.

    case create_version(entity, context, options) do
      version = %{revision: revision, parent: parent} ->
        entity = entity
                 |> Noizu.Cms.V2.Proto.set_version(Noizu.ERP.ref(version), context, options)
                 |> Noizu.Cms.V2.Proto.set_revision(revision && Noizu.ERP.ref(revision), context, options)
                 |> Noizu.Cms.V2.Proto.set_parent(parent && Noizu.ERP.ref(parent), context, options)

        v_id = Noizu.Cms.V2.Proto.versioned_identifier(entity, context, options)
        entity = entity
                 |> put_in([Access.key(:identifier)], v_id)


        if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
          cms_provider.update_tags(entity, context, options)
          cms_provider.update_index(entity, context, options)
        end
        entity
      _ -> throw "Create Version Error"
    end
  end

  def populate_versioning_records(entity, context, options \\ %{}) do
    # Create Version Record
    # Create Revision Record (@todo consider removing revision table, and depend on master table.)
    entity
  end

  #------------------------
  #
  #------------------------
  def get_versions(entity, context, options \\ %{}) do
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

  def get_versions!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> get_versions(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def create_version(entity, context, options \\ %{}) do
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
    
    case create_revision(article, context, options) do
      revision = %Noizu.Cms.V2.Version.RevisionEntity{} ->
        revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
        %Noizu.Cms.V2.VersionEntity{
          identifier: new_version_key,
          article: article_ref,
          parent: current_version_ref,
          revision: revision_ref,
          article_info: revision.article_info,
          created_on: revision.created_on,
          modified_on: revision.modified_on,
          editor: revision.article_info.editor,
          status: revision.article_info.status,
        } |> Noizu.Cms.V2.VersionRepo.create(context, options)
      {:error, e} -> {:error, {:creating_revision, e}}
      e -> {:error, {:creating_revision, {:unknown, e}}}
    end
  end

  def create_version!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> create_version(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def update_version(entity, context, options \\ %{}) do
    # 1. get current version.
    current_version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                      |> Noizu.Cms.V2.VersionEntity.entity()
    cond do
      current_version == nil -> {:error, :invalid_version}
      true ->
        case update_revision(entity, context, options) do
          revision = %Noizu.Cms.V2.Version.RevisionEntity{} ->
            version = %Noizu.Cms.V2.VersionEntity{
              current_version|
              article_info: revision.article_info,
              modified_on: revision.modified_on,
              editor: revision.editor,
              status: revision.status,
            } |> Noizu.Cms.V2.VersionRepo.update(context, options)
          _ -> {:error, :update_revision}
        end
    end
  end
  def update_version!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> update_version(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def delete_version(entity, context, options \\ %{}) do
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
        case get_revisions(entity, context, options) do
          revisions when is_list(revisions) ->
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
  def delete_version!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> delete_version(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def get_revisions(entity, context, options \\ %{}) do
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

  def get_revisions!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> get_revisions(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def create_revision(entity, context, options \\ %{}) do
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

        article_info = %Noizu.Cms.V2.Article.Info{article_info|
          revision: revision_key
        }

        {full_copy, archive} = Noizu.Cms.V2.Proto.compress_archive(article, context, options)
        %Noizu.Cms.V2.Version.RevisionEntity{
          identifier: revision_key,
          article: article_ref,
          version: version_ref,
          article_info: article_info,
          created_on: article_info.created_on,
          modified_on: article_info.modified_on,
          editor: article_info.editor,
          status: article_info.status,
          full_copy: full_copy,
          record: archive,
        } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)
    end
  end
  def create_revision!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> create_revision(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def update_revision(entity, context, options \\ %{}) do
    article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
    article_ref = Noizu.ERP.ref(article)
    article_info = Noizu.Cms.V2.Proto.get_article_info(article, context, options)
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = %Noizu.Cms.V2.Article.Info{modified_on: current_time}
    article = Noizu.Cms.V2.Proto.set_article_info(article, article_info, context, options)

    version = Noizu.Cms.V2.Proto.get_version(article, context, options)
    version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
    version_key = Noizu.Cms.V2.VersionEntity.id(version)

    revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
    revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(version)
    revision_key = Noizu.Cms.V2.Version.RevisionEntity.id(version)

    cond do
      article == nil -> {:error, :invalid_record}
      version == nil -> {:error, :no_version_provided}
      revision == nil -> {:error, :no_revision_provided}
      true ->
        {full_copy, archive} = Noizu.Cms.V2.Proto.compress_archive(article, context, options)

        # @todo pri-1 if active then we must update tags/index.

        # load existing record.
        revision = if revision = Noizu.Cms.V2.Version.RevisionEntity.entity(revision) do
          %Noizu.Cms.V2.Version.RevisionEntity{
            revision|
            article: article_ref,
            version: version_ref,
            article_info: article_info,
            modified_on: article_info.modified_on,
            editor: article_info.editor,
            status: article_info.status,
            full_copy: full_copy,
            record: archive,
          } |> Noizu.Cms.V2.Version.RevisionRepo.update(context)
        else
          %Noizu.Cms.V2.Version.RevisionEntity{
            identifier: revision_key,
            article: article_ref,
            version: version_ref,
            article_info: article_info,
            created_on: current_time, # imprecise (may become out of sync with article)
            modified_on: article_info.modified_on,
            editor: article_info.editor,
            status: article_info.status,
            full_copy: full_copy,
            record: archive,
          } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)
        end

        # Update Active if modifying active revision
        if options[:bookkeeping] != :disabled do
          if cms_provider = Noizu.Cms.V2.Proto.cms_provider(article, context, options) do
            active_revision = cms_provider.get_active(article, context, options)
                              |> Noizu.ERP.ref()
            if (active_revision && active_revision == revision_ref), do: cms_provider.update_active(article, context, options)
          end
        end

        # Return updated revision
        revision
    end
  end
  def update_revision!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> update_revision(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def delete_revision(entity, context, options \\ %{}) do
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

  def delete_revision!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> delete_revision(entity, context, options) end)
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
end