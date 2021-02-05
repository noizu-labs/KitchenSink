#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Version.RevisionRepo do
  @behaviour Noizu.Cms.V2.Cms.RevisionRepoBehaviour
  use Noizu.Scaffolding.V2.RepoBehaviour,
        entity_module: Noizu.Cms.V2.Version.RevisionEntity,
        mnesia_table: Noizu.Cms.V2.Database.Version.RevisionTable

  alias Noizu.Cms.V2.Version.RevisionEntity

  alias Noizu.Cms.V2.Database.Version.RevisionTable
  use Noizu.Cms.V2.Database.Version.RevisionTable
  use Amnesia

  #------------------------
  #
  #------------------------
  def entity_revisions(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    Noizu.Cms.V2.Database.Version.RevisionTable.match([identifier: {{:ref, Noizu.Cms.V2.VersionEntity, {ref, :_}}, :_}])
    |> Amnesia.Selection.values()
    |> Enum.map(&(&1.entity))
  end

  #------------------------
  #
  #------------------------
  def active(ref, _context, _options \\ %{}) do
    case Noizu.Cms.V2.Database.Version.ActiveRevisionTable.read(ref) do
      %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{revision: r} -> r
      _ -> nil
    end
  end

  #------------------------
  #
  #------------------------
  def delete_active(version_ref, _context, _options \\ %{})
  def delete_active({:ref, _, _identifier} = ref, _context, _options) do
    Noizu.Cms.V2.Database.Version.ActiveRevisionTable.delete(ref)
  end
  def delete_active(entity, context, options) do
    version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                  |> Noizu.ERP.ref()
    Noizu.Cms.V2.Database.Version.ActiveRevisionTable.delete(version_ref)
  end

  #------------------------
  #
  #------------------------
  def set_active(revision_ref, version_ref, _context, _options \\ %{}) do
    %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{
      version: Noizu.Cms.V2.VersionEntity.ref(version_ref),
      revision: RevisionEntity.ref(revision_ref)
    } |> Noizu.Cms.V2.Database.Version.ActiveRevisionTable.write()
  end

  def version_revisions(version, context, options) do
    match([identifier: {version, :_}], context, options)
  end

  #------------------------
  #
  #------------------------
  def change_set(entity, options) do
    Enum.reduce(options, entity, fn({k, v}, acc) ->
      put_in(acc, [Access.key(k)], v)
    end)
  end

  #------------------------
  #
  #------------------------
  def new(options) do
    %Noizu.Cms.V2.Version.RevisionEntity{
      identifier: options[:identifier],
      article: options[:article],
      version: options[:version],
      created_on: options[:created_on],
      modified_on: options[:modified_on],
      editor: options[:editor],
      status: options[:status],
      archive_type: options[:archive_type],
      archive: options[:archive],
    }
  end


  def revision_create(article, version, context, options, cms) do
    cms.cms_revision().revision_create(article, version, context, options)
  end

  #------------------------
  #
  #------------------------
  def is_revision({:revision, {_i, _v, _r}}), do: true
  def is_revision(_), do: false

  def mnesia_delete(identifier), do: RevisionTable.delete(identifier)
  def mnesia_delete!(identifier), do: RevisionTable.delete!(identifier)
  def mnesia_read(identifier), do: RevisionTable.read(identifier)
  def mnesia_read!(identifier), do: RevisionTable.read!(identifier)
  def mnesia_write(identifier), do: RevisionTable.write(identifier)
  def mnesia_write!(identifier), do: RevisionTable.write!(identifier)
  def mnesia_match(m), do: RevisionTable.match(m)
  def mnesia_match!(m), do: RevisionTable.match!(m)
end
