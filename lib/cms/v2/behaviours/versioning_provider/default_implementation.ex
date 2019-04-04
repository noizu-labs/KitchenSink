#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersioningProvider.DefaultImplementation do
  use Amnesia
  use Noizu.Cms.V2.Database.IndexTable
  use Noizu.Cms.V2.Database.TagTable
  use Noizu.Cms.V2.Database.VersionTable

  alias Noizu.Cms.V2.Database.VersionTable
  alias Noizu.Cms.V2.VersionRepo
  alias Noizu.Cms.V2.VersionEntity

  @behaviour Noizu.Cms.V2.VersioningProviderBehaviour
  #@default_options %{expand: true, filter: false}

  #===========================================================
  # Implementation of Behaviour
  #===========================================================
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

  def assign_new_revision(entry, context, options) do
    # 1. get current version.
    version = Noizu.Cms.V2.Proto.get_version(entry, context, options)
              |> Noizu.Cms.V2.VersionEntity.entity()
    article_ref = Noizu.ERP.ref(entry)
    entry = Noizu.ERP.entity(entry)

    # 2. create new revision
    cond do
      version == nil -> {:error, :invalid_version}
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
  #
  #-----------------------------------
  def create_version(entry, context, options) do
    entry = Noizu.ERP.entity(entry)
    current_time = options[:current_time] || DateTime.utc_now()
    status = options[:status] || :pending
    editor = options[:editor] || context.caller
    ref = Noizu.ERP.ref(entry)

    # 1. get current version.
    current_version = Noizu.Cms.V2.Proto.get_version(entry, context, options)
    current_version_ref = current_version && Noizu.Cms.V2.VersionEntity.ref(current_version)

    # 2. Determine version path we will be creating
    version_path = cond do
      current_version == nil -> {version_sequencer({ref, {}})}
      true ->
        {:ref, _, {_article, path}} = current_version_ref
        List.to_tuple(Tuple.to_list(path) ++ [version_sequencer({ref, path})])
    end

    # 3. Create Version Stub
    version_key = {ref, version_path}
    version_ref = Noizu.Cms.V2.VersionEntity.ref(version_key)

    case create_revision(version_ref, entry, context, options) do
      revision = %Noizu.Cms.V2.Version.RevisionEntity{} ->
        %Noizu.Cms.V2.VersionEntity{
          identifier: version_key,
          article: ref,
          parent: current_version_ref,
          revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision),
          created_on: current_time,
          modified_on: current_time,
          editor: editor,
          status: status,
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
  def update_version(entry, context, options) do
    {:error, :nyi}
  end

  def update_version!(entry, context, options) do
    {:error, :nyi}
  end

  #-----------------------------------
  #
  #-----------------------------------
  def delete_version(entry, context, options) do
    {:error, :nyi}
  end

  def delete_version!(entry, context, options) do
    {:error, :nyi}
  end

  #-----------------------------------
  #
  #-----------------------------------
  def create_revision(version, entry, context, options) do
    entry = Noizu.ERP.entity(entry)
    status = options[:status] || :pending
    editor = options[:editor] || context.caller
    current_time = options[:current_time] || DateTime.utc_now()
    ref = Noizu.ERP.ref(entry)

    version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
    version_key = Noizu.Cms.V2.VersionEntity.id(version)
    revision_key = {version_ref, version_sequencer({:revision, version_key})}
    revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision_key)

    %Noizu.Cms.V2.Version.RevisionEntity{
      identifier: revision_key,
      article: ref,
      version: version_ref,
      full_copy: true,
      created_on: current_time,
      editor: editor,
      status: status,
      record: entry.__struct__.compress(entry, options),
    } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)
  end

  def create_revision!(entry, version, context, options) do
    Amnesia.Fragment.async(fn -> create_revision(entry, version, context, options) end)
  end

  #-----------------------------------
  #
  #-----------------------------------
  def update_revision(entry, context, options) do
    {:error, :nyi}
  end

  def update_revision!(entry, context, options) do
    {:error, :nyi}
  end

  #-----------------------------------
  #
  #-----------------------------------
  def delete_revision(entry, context, options) do
    {:error, :nyi}
  end

  def delete_revision!(entry, context, options) do
    {:error, :nyi}
  end

  #-----------------------------------
  #
  #-----------------------------------
  def get_versions(entry, context, options)do
    {:error, :nyi}
  end

  def get_versions!(entry, context, options)do
    {:error, :nyi}
  end

  #-----------------------------------
  #
  #-----------------------------------
  def get_revisions(entry, context, options)do
    {:error, :nyi}
  end

  def get_revisions!(entry, context, options)do
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