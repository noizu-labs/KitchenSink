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

  #-----------------------------------
  #
  #-----------------------------------

  def assign_new_version(entry, context, options) do
    case create_version(entry, context, options) do
      version = %Noizu.Cms.V2.VersionEntity{} ->
        entry
        |> Noizu.Cms.V2.Proto.set_version(Noizu.Cms.V2.VersionEntity.ref(version), context, options)
        |> Noizu.Cms.V2.Proto.set_revision(Noizu.Cms.V2.Version.RevisionEntity.ref(version.revision), context, options)
        |> Noizu.Cms.V2.Proto.set_parent(Noizu.Cms.V2.VersionEntity.ref(version.parent), context, options)
    end
  end

  def assign_new_version!(entry, context, options) do
    Amnesia.Fragment.async(fn -> assign_new_version(entry, context, options) end)
  end

  #-----------------------------------
  #
  #-----------------------------------

  def assign_new_revision(entry, context, options) do
    # 1. get current version.
    version = Noizu.Cms.V2.Proto.get_version(entry, context, options)
              |> Noizu.Cms.V2.VersionEntity.entity()
    article_ref = Noizu.ERP.ref(entry)
    entry = Noizu.ERP.entity(entry)

    # 2. create new revision
    cond do
      version == nil ->
        if options[:auto_version] do
          assign_new_version(entry, context, options)
        else
          {:error, :invalid_version}
        end
      version.article != article_ref -> {:error, :incorrect_article}
      true ->
        case create_revision(version, entry, context, options) do
          revision = %Noizu.Cms.V2.Version.RevisionEntity{} ->

            version = %Noizu.Cms.V2.VersionEntity{version|
              revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision),
              modified_on: revision.modified_on,
              editor: revision.editor,
              status: revision.status,
            } |> Noizu.Cms.V2.VersionRepo.update(context, options)

            entry
            |> Noizu.Cms.V2.Proto.set_version!(Noizu.Cms.V2.VersionEntity.ref(version), context, options)
            |> Noizu.Cms.V2.Proto.set_revision!(Noizu.Cms.V2.Version.RevisionEntity.ref(version.revision), context, options)
            |> Noizu.Cms.V2.Proto.set_parent!(Noizu.Cms.V2.VersionEntity.ref(version.parent), context, options)
        end
    end
  end

  def assign_new_revision!(entry, context, options) do
    Amnesia.Fragment.async(fn -> assign_new_revision(entry, context, options) end)
  end

  #-----------------------------------
  # overwrite_revision
  #-----------------------------------
  def overwrite_revision(entry, context, options) do
    #article_ref = Noizu.ERP.ref(entry)

    version = Noizu.Cms.V2.Proto.get_version(entry, context, options)
              |> Noizu.Cms.V2.VersionEntity.entity()

    revision = Noizu.Cms.V2.Proto.get_revision(entry, context, options)
               |> Noizu.Cms.V2.Version.RevisionEntity.entity()

    revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
    cond do
      version == nil ->
        assign_new_version(entry, context, options)
      version && revision == nil ->
        # unexpected state.
        assign_new_revision(entry, context, options)
      version.revision != revision_ref ->
        # unexpected state, for now simply force new revision.
        assign_new_revision(entry, context, options)
      true ->
        # todo error handling.
        update_version(version, entry, context, options)
        update_revision(revision, entry, context, options)
        entry
    end
  end

  def overwrite_revision!(entry, context, options) do
    Amnesia.Fragment.async(fn -> overwrite_revision(entry, context, options) end)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def create_version(entry, context, options) do
    entry = Noizu.ERP.entity(entry)
    article_ref = Noizu.ERP.ref(entry)
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = Noizu.Cms.V2.Proto.get_article_info(entry, context, options)

    # 1. get current version.
    current_version = Noizu.Cms.V2.Proto.get_version(entry, context, options)
    current_version_ref = current_version && Noizu.Cms.V2.VersionEntity.ref(current_version)

    # 2. Determine version path we will be creating
    version_path = cond do
      current_version == nil ->
        {version_sequencer({article_ref, {}})}
      true ->
        {:ref, _, {_article, path}} = current_version_ref
        List.to_tuple(Tuple.to_list(path) ++ [version_sequencer({article_ref, path})])
    end

    # 3. Create Version Stub
    version_key = {article_ref, version_path}
    version_ref = Noizu.Cms.V2.VersionEntity.ref(version_key)

    case create_revision(version_ref, entry, context, options) do
      revision = %Noizu.Cms.V2.Version.RevisionEntity{} ->
        %Noizu.Cms.V2.VersionEntity{
          identifier: version_key,
          article: article_ref,
          parent: current_version_ref,
          revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision),
          created_on: current_time,
          modified_on: current_time,
          editor: article_info.editor,
          status: article_info.status,
        } |> Noizu.Cms.V2.VersionRepo.create(context, options)
    end
  end

  def create_version!(entry, context, options) do
    Amnesia.Fragment.async(fn ->
      create_version(entry, context, options)
    end)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def update_version(version, entry, context, options) do
    entry = Noizu.ERP.entity(entry)
    #article_ref = Noizu.ERP.ref(entry)
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = Noizu.Cms.V2.Proto.get_article_info(entry, context, options)

    %Noizu.Cms.V2.VersionEntity{version|
      modified_on: current_time,
      editor: article_info.editor,
      status: article_info.status,
    } |> Noizu.Cms.V2.VersionRepo.update(context, options)
  end

  def update_version!(version, entry, context, options) do
    Amnesia.Fragment.async(fn ->
      update_version(version, entry, context, options)
    end)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def delete_version(version, context, options) do
    # @todo constraint check if entity relies on version.
    Noizu.Cms.V2.VersionRepo.delete(version, context, options)
  end

  def delete_version!(version, context, options) do
    Amnesia.Fragment.async(fn ->
      delete_version(version, context, options)
    end)
  end



  #-----------------------------------
  #
  #-----------------------------------
  def create_revision(version, entry, context, options) do
    entry = Noizu.ERP.entity(entry)
    article_info = Noizu.Cms.V2.Proto.get_article_info(entry, context, options)
    current_time = options[:current_time] || DateTime.utc_now()
    article_ref = Noizu.ERP.ref(entry)

    version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
    version_key = Noizu.Cms.V2.VersionEntity.id(version)
    revision_key = options[:revision_key] || {version_ref, version_sequencer({:revision, version_key})}
    #revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision_key)

    %Noizu.Cms.V2.Version.RevisionEntity{
      identifier: revision_key,
      article: article_ref,
      version: version_ref,
      full_copy: true,
      created_on: current_time,
      modified_on: current_time,
      editor: article_info.editor,
      status: article_info.status,
      record: entry.__struct__.compress(entry, options),
    } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)
  end

  def create_revision!(entry, version, context, options) do
    Amnesia.Fragment.async(fn -> create_revision(version, entry, context, options) end)
  end

  #-----------------------------------
  # update_revision
  #-----------------------------------
  def update_revision(revision, entry, context, options) do
    article_ref = Noizu.ERP.ref(entry)
    entry = Noizu.ERP.entity(entry)
    article_info = Noizu.Cms.V2.Proto.get_article_info(entry, context, options)
    current_time = options[:current_time] || DateTime.utc_now()

    if revision.article == article_ref do
      %Noizu.Cms.V2.Version.RevisionEntity{revision|
        full_copy: true,
        modified_on: current_time,
        editor: article_info.editor,
        status: article_info.status,
        record: entry.__struct__.compress(entry, options),
      } |> Noizu.Cms.V2.Version.RevisionRepo.update(context)
    else
      {:error, :article_ref_mismatch}
    end
  end

  def update_revision!(revision, entry, context, options) do
    Amnesia.Fragment.async(fn -> update_revision(revision, entry, context, options) end)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def delete_revision(revision, context, options) do
    # @todo - constraint check if version relies on revision.
    Noizu.Cms.V2.VersionRepo.delete(revision, context, options)
  end

  def delete_revision!(revision, context, options) do
    Amnesia.Fragment.async(fn ->
      delete_revision(revision, context, options)
    end)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def get_versions(_entry, _context, _options)do
    {:error, :nyi}
  end

  def get_versions!(_entry, _context, _options)do
    {:error, :nyi}
  end

  #-----------------------------------
  #
  #-----------------------------------
  def get_revisions(_version, _context, _options)do
    {:error, :nyi}
  end

  def get_revisions!(_version, _context, _options)do
    {:error, :nyi}
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