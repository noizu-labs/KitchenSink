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

  #@default_options %{expand: true, filter: false}

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

  #----------------------------------
  # create_version
  #----------------------------------
  def create_version(entry, context, options \\ %{}) do
    status = options[:status] || :pending
    editor = options[:editor] || context.caller
    current_time = options[:current_time] || DateTime.utc_now()
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

    # 3. Save New Revision Record
    version_key = {ref, version_path}
    version_ref = Noizu.Cms.V2.VersionEntity.ref(version_key)
    revision_key = {version_ref, version_sequencer({:revision, version_key})}
    revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision_key)
    compressed_record = entry.__struct__.compress(entry, options)

    revision = %Noizu.Cms.V2.Version.RevisionEntity{
                 identifier: revision_key,
                 article: ref,
                 version: version_ref,
                 full_copy: true, # @todo compressed format support/delta support.
                 created_on: current_time,
                 editor: editor,
                 status: status,
                 record: compressed_record,
               } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)

    revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)

    # 4. Save New Version Record
    version = %Noizu.Cms.V2.VersionEntity{
                identifier: version_key,
                article: ref,
                parent: current_version_ref,
                revision: revision_ref,
                full_copy: true,
                created_on: current_time,
                modified_on: current_time,
                editor: editor,
                status: status,
                record: compressed_record,
              } |> Noizu.Cms.V2.VersionRepo.create(context)

    new_version_ref = Noizu.Cms.V2.VersionEntity.ref(version)

    # 5. Update entity with version/revision
    entry
    |> Noizu.Cms.V2.Proto.set_version(new_version_ref, context, options)
    |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options)
    |> Noizu.Cms.V2.Proto.set_parent(current_version_ref, context, options)
  end


  def create_version!(entry, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> create_version(entry, context, options) end)
  end


  #----------------------------------
  # update_version
  #----------------------------------
  def update_version(entry, _context, _options \\ %{}) do
    # 1. get current version.
    #current_version = Noizu.Cms.V2.Proto.get_version(entry, context, options)

    # 2. generate new version for article
    #nv = version_sequencer({Noizu.ERP.ref(entry), current_version, :sub_version})

    # Save Subversion
    # Save Version
    entry
  end

  #----------------------------------
  # delete_version
  #----------------------------------
  def delete_version(entry, _context, _options \\ %{}) do
    # Future - Handle dependent versions (non full copy that rely on deleted version/subversion)
    # Delete Versions
    # Delete SubVersions
    # Delete VersionHistory
    # Delete SubVersionHistory
    entry
  end

  #----------------------------------
  #
  #----------------------------------
  def get_version_history(_entry, _context, _options \\ %{}) do
    #(ref = Noizu.ERP.ref(entry)) && Enum.sort(VersionHistoryTable.read(ref) || [], &(&1.created_on <= &2.created_on)) || []
    []
  end

  def get_version_history!(_entry, _context, _options \\ %{}) do
    #(ref = Noizu.ERP.ref(entry)) && Enum.sort(VersionHistoryTable.read!(ref) || [], &(&1.created_on <= &2.created_on)) || []
    []
  end

  #----------------------------------
  #
  #----------------------------------
  def get_version(entry, version, _context, options \\ %{}) do
    (ref = Noizu.ERP.ref(entry)) && VersionEntity.entity({:ref, VersionEntity, {ref, version}}, options)
  end

  def get_version!(entry, version, _context, options \\ %{}) do
    (ref = Noizu.ERP.ref(entry)) && VersionEntity.entity!({:ref, VersionEntity, {ref, version}}, options)
  end

  #----------------------------------
  #
  #----------------------------------
  def get_all_versions(entry, _context, _options \\ %{}) do
    if (ref = Noizu.ERP.ref(entry)) do
      _record = VersionTable.match([identifier: {ref, :_}])
                |> Amnesia.Selection.values()
                |> Enum.map(&(&1.entity))
    else
      []
    end
  end

  #----------------------------------
  #
  #----------------------------------
  def get_all_versions!(entry, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> get_all_versions(entry, context, options) end)
  end

  #----------------------------------
  #
  #----------------------------------
  def generate_version_hash(entry, version, _context, _options) do
    if ref = Noizu.ERP.ref(entry) do
      #m = elem(ref, 1)
      #v = m.repo().nmid_generator().generate({m, :version}, %{})
      :crypto.hash(:md5, "#{Noizu.ERP.sref(ref)}-#{version}") |> Base.encode16()
    end
  end


  def write_version_record(entry, context, options \\ %{}) do
    version_entity = Noizu.Cms.V2.Proto.prepare_version(entry, context, options)
    _version_entity = VersionRepo.create(version_entity, context, options)
    #%VersionHistoryTable{
    #  article: Noizu.ERP.ref(entry),
    #  version: Noizu.ERP.ref(version_entity),
    #  parent_version: version_entity.parent,
    #  full_copy: version_entity.fully_copy,
    #  created_on: version_entity.created_on,
    #  editor: version_entity.editor
    #} |> VersionHistoryTable.write()
    entry
  end
end