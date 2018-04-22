#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.PostRepo do
  use Noizu.Scaffolding.RepoBehaviour,
      entity_module: Noizu.Cms.PostEntity,
      mnesia_table: Noizu.Cms.Database.PostTable,
      override: [:pre_create_callback, :post_create_callback]
  require Logger

  def get_history!(ref, context) do
    post_ref = Noizu.Cms.PostEntity.ref(ref)
    Noizu.Cms.Database.Post.VersionHistoryTable.read!(post_ref)
  end

  def get_version!(version, ref, context) do
    post_ref = Noizu.Cms.PostEntity.ref(ref)
    m = [post: post_ref, version: version]
    records = Noizu.Cms.Database.Post.VersionTable.match!(m) |> Amnesia.Selection.values()
    case records do
      [h|_] -> Noizu.Cms.Post.VersionEntity.entity(h)
      _ -> nil
    end
  end

  def pre_create_callback(%Noizu.Cms.PostEntity{} = entity, context, options) do
    # Set Identifier
    entity = if entity.identifier == nil do
      put_in(entity, [Access.key(:identifier)], generate_identifier())
    else
      entity
    end

    # Set Version
    entity = case entity.version do
      nil -> put_in(entity, [Access.key(:version)], 1)
      _ -> entity
    end

    # Set Created On
    entity = case entity.created_on do
      nil -> put_in(entity, [Access.key(:created_on)], DateTime.utc_now())
      _ -> entity
    end

    # Inject Version Record
    post_ref = Noizu.Cms.PostEntity.ref(entity)
    version_record = %Noizu.Cms.Post.VersionEntity{
      post: post_ref,
      version: entity.version,
      created_on: entity.created_on,
      editor: entity.editor,
      status: entity.status,
      name: entity.name,
      description: entity.description,
      note: options[:note] || :initial_version,
      tags: entity.tags,
      record: entity.record,
    } |> Noizu.Cms.Post.VersionRepo.create!(context, options) # will break non ! calls.
    version_ref = Noizu.Cms.Post.VersionEntity.ref(version_record)

    put_in(entity, [Access.key(:version_record)], version_ref)
  end

  def post_create_callback(%Noizu.Cms.PostEntity{} = entity, context, options) do
    post_ref = Noizu.Cms.PostEntity.ref(entity)

    # Inject Version History
    %Noizu.Cms.Database.Post.VersionHistoryTable{
      identifier: post_ref,
      version: entity.version,
      created_on: DateTime.to_unix(entity.created_on),
      editor: entity.editor,
      note: options[:note] || :initial_version,
      post_version: entity.version_record
    } |> Noizu.Cms.Database.Post.VersionHistoryTable.write!()

    # Inject Tags
    Enum.map(MapSet.to_list(entity.tags),
      fn(tag) ->
        %Noizu.Cms.Database.Post.TagTable{
          post: post_ref,
          tag: tag,
        } |> Noizu.Cms.Database.Post.TagTable.write!
      end)

    entity
  end
end