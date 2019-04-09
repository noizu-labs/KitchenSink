#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Repo.DefaultImplementation do
  use Amnesia
  use Noizu.Cms.V2.Database.IndexTable
  use Noizu.Cms.V2.Database.TagTable
  use Noizu.Cms.V2.Database.VersionTable

  alias Noizu.Cms.V2.Database.IndexTable
  alias Noizu.Cms.V2.Database.TagTable
  #alias Noizu.Cms.V2.Database.VersionTable

  @default_options %{
    expand: true,
    filter: false
  }

  #----------------------------------
  #
  #----------------------------------
  def expand_records(records, _context, %{expand: true}) when is_list(records), do: Enum.map(records, &(Noizu.ERP.entity(&1.article))) |> Enum.filter(&(&1 != nil))
  def expand_records(records, _context, _) when is_list(records), do: records
  def expand_records(e, _context, _), do: throw {:error, e}


  def expand_records!(records, _context, %{expand: true}) when is_list(records), do: Enum.map(records, &(Noizu.ERP.entity!(&1.article))) |> Enum.filter(&(&1 != nil))
  def expand_records!(records, _context, _) when is_list(records), do: records
  def expand_records!(e, _context, _), do: throw {:error, e}

  #----------------------------------
  #
  #----------------------------------
  def match_records(filter, _context, options) do
    case options.filter do
      {:type, t} -> [type: t] ++ filter # Unexpected behaviour if filter is [type: t2]
      {:module, m} -> [module: m] ++ filter
      m when is_atom(m) -> [module: m] ++ filter
      _ -> filter
    end
    |> Enum.uniq()
    |> IndexTable.match()
    |> Amnesia.Selection.values
  end
  def match_records!(filter, context, options), do: Amnesia.Fragment.async(fn -> match_records(filter, context, options) end)

  #----------------------------------
  #
  #----------------------------------
  def filter_records(records, _context, options) when is_list(records) do
    cond do
      Kernel.match?({:type, _}, options.filter) ->
        t = elem(options.filter, 1)
        Enum.filter(records, &(&1 && &1.type == t || false))
      Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
        m = elem(options.filter, 1)
        Enum.filter(records, &(&1 && &1.module == m || false))
      true ->
        Enum.filter(records, &(&1 || false))
    end
  end
  def filter_records(e, _context, _), do: throw {:error, e}

  #----------------------------------
  #
  #----------------------------------
  def get_by_status(status, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [status: status]
    |> match_records(context, options)
    |> expand_records(context, options)
  end

  def get_by_status!(status, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [status: status]
    |> match_records!(context, options)
    |> expand_records!(context, options)
  end

  #----------------------------------
  #
  #----------------------------------
  def get_by_type(type, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [type: type]
    |> match_records(context, options)
    |> expand_records(context, options)
  end

  def get_by_type!(type, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [type: type]
    |> match_records!(context, options)
    |> expand_records!(context, options)
  end

  #----------------------------------
  #
  #----------------------------------
  def get_by_module(module, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [module: module]
    |> match_records(context, options)
    |> expand_records(context, options)
  end

  def get_by_module!(module, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [module: module]
    |> match_records!(context, options)
    |> expand_records!(context, options)
  end
  #----------------------------------
  #
  #----------------------------------
  def get_by_editor(editor, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [editor: editor]
    |> match_records(context, options)
    |> expand_records(context, options)
  end

  def get_by_editor!(editor, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [editor: editor]
    |> match_records!(context, options)
    |> expand_records!(context, options)
  end

  #----------------------------------
  #
  #----------------------------------
  def get_by_tag(tag, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    [tag: tag]
    |> TagTable.match()
    |> Amnesia.Selection.values()
    |> Enum.map(&(IndexTable.read(&1.article)))
    |> filter_records(context, options)
    |> expand_records(context, options)
  end

  def get_by_tag!(tag, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    records = Amnesia.Fragment.async(fn ->
      [tag: tag]
      |> TagTable.match()
      |> Amnesia.Selection.values()
    end)

    if is_list(records) do
      records
      |> Enum.map(&(IndexTable.read!(&1.article)))
      |> filter_records(context, options)
      |> expand_records!(context, options)
    else
      throw {:error, records}
    end
  end

  #----------------------------------
  #
  #----------------------------------
  def get_by_created_on(from, to, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    cond do
      Kernel.match?({:type, _}, options.filter) ->
        t = elem(options.filter, 1)
        IndexTable.where(type == t and created_on >= from_ts and created_on < to_ts)
      Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
        m = elem(options.filter, 1)
        IndexTable.where(module == m and created_on >= from_ts and created_on < to_ts)
      true -> IndexTable.where(created_on >= from_ts and created_on < to_ts)
    end
    |> Amnesia.Selection.values
    |> expand_records(context, options)
  end

  def get_by_created_on!(from, to, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    Amnesia.Fragment.async(fn ->
      cond do
        Kernel.match?({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          IndexTable.where(type == t and created_on >= from_ts and created_on < to_ts)
        Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
          m = elem(options.filter, 1)
          IndexTable.where(module == m and created_on >= from_ts and created_on < to_ts)
        true -> IndexTable.where(created_on >= from_ts and created_on < to_ts)
      end
      |> Amnesia.Selection.values
    end)
    |> expand_records!(context, options)
  end

  #----------------------------------
  #
  #----------------------------------
  def get_by_modified_on(from, to, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    cond do
      Kernel.match?({:type, _}, options.filter) ->
        t = elem(options.filter, 1)
        IndexTable.where(type == t and modified_on >= from_ts and modified_on < to_ts)
      Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
        m = elem(options.filter, 1)
        IndexTable.where(module == m and modified_on >= from_ts and modified_on < to_ts)
      true -> IndexTable.where(modified_on >= from_ts and modified_on < to_ts)
    end
    |> Amnesia.Selection.values
    |> expand_records(context, options)
  end

  def get_by_modified_on!(from, to, context, options \\ %{}) do
    options = Map.merge(@default_options, options)
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    Amnesia.Fragment.async(fn ->
      cond do
        Kernel.match?({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          IndexTable.where(type == t and modified_on >= from_ts and modified_on < to_ts)
        Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
          m = elem(options.filter, 1)
          IndexTable.where(module == m and modified_on >= from_ts and modified_on < to_ts)
        true -> IndexTable.where(modified_on >= from_ts and modified_on < to_ts)
      end
      |> Amnesia.Selection.values
    end)
    |> expand_records!(context, options)
  end

  #=====================================================
  #
  #=====================================================
  def update_tags(entity, context, options) do
    ref = Noizu.ERP.ref(entity)


    new_tags = case Noizu.Cms.V2.Proto.tags(ref, context, options) do
      v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
      v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
      nil -> []
    end

    existing_tags = case Noizu.Cms.V2.Database.TagTable.read(ref) do
      v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
      nil -> []
      v -> {:error, v}
    end

    if (new_tags != existing_tags) do
      # erase any existing tags
      Noizu.Cms.V2.Database.TagTable.delete(ref)

      # insert new tags
      Enum.map(new_tags, fn(tag) ->
        %Noizu.Cms.V2.Database.TagTable{article: ref, tag: tag} |> Noizu.Cms.V2.Database.TagTable.write()
      end)
    end
  end

  def update_tags!(entity, context, options) do
    ref = Noizu.ERP.ref(entity)
    new_tags = case Noizu.Cms.V2.Proto.tags!(ref, context, options) do
      v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
      v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
      nil -> []
    end

    existing_tags = case Noizu.Cms.V2.Database.TagTable.read!(ref) do
      v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
      nil -> []
      v -> {:error, v}
    end

    if (new_tags != existing_tags) do
      # erase any existing tags
      Noizu.Cms.V2.Database.TagTable.delete!(ref)

      # insert new tags
      Enum.map(new_tags, fn(tag) ->
        %Noizu.Cms.V2.Database.TagTable{article: ref, tag: tag} |> Noizu.Cms.V2.Database.TagTable.write!()
      end)
    end
  end

  def delete_tags(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    # erase any existing tags
    Noizu.Cms.V2.Database.TagTable.delete(ref)
  end

  def delete_tags!(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    # erase any existing tags
    Noizu.Cms.V2.Database.TagTable.delete!(ref)
  end

  def update_index(entry, context, options) do
    ref = Noizu.ERP.ref(entry)
    entity = Noizu.ERP.entity(entry)

    article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
    case Noizu.Cms.V2.Database.IndexTable.read(ref) do
      index = %Noizu.Cms.V2.Database.IndexTable{} ->
        if (article_info.version == index.active_version) do
          %Noizu.Cms.V2.Database.IndexTable{index|
            status: article_info.status,
            module: article_info.module,
            type: article_info.type,
            editor: article_info.editor,
            modified_on: article_info.modified_on,
          } |> Noizu.Cms.V2.Database.IndexTable.write
        else
          # do not update master record if we are not editing the active version
          index
        end
      _ ->
        %Noizu.Cms.V2.Database.IndexTable{
          article: article_info.article,
          status: article_info.status,
          module: article_info.module,
          type: article_info.type,
          editor: article_info.editor,
          created_on: article_info.created_on,
          modified_on: article_info.modified_on,
          active_version: article_info.version, # Should not always be modified (if already set)
        } |> Noizu.Cms.V2.Database.IndexTable.write
    end
  end


  def update_index!(entry, context, options) do
    ref = Noizu.ERP.ref(entry)
    entity = Noizu.ERP.entity!(entry)

    article_info = Noizu.Cms.V2.Proto.get_article_info!(entity, context, options)
    case Noizu.Cms.V2.Database.IndexTable.read!(ref) do
      index = %Noizu.Cms.V2.Database.IndexTable{} ->
        if (article_info.version == index.active_version) do
          %Noizu.Cms.V2.Database.IndexTable{index|
            status: article_info.status,
            module: article_info.module,
            type: article_info.type,
            editor: article_info.editor,
            modified_on: article_info.modified_on,
          } |> Noizu.Cms.V2.Database.IndexTable.write!
        else
          # do not update master record if we are not editing the active version
          index
        end
      _ ->
        %Noizu.Cms.V2.Database.IndexTable{
          article: article_info.article,
          status: article_info.status,
          module: article_info.module,
          type: article_info.type,
          editor: article_info.editor,
          created_on: article_info.created_on,
          modified_on: article_info.modified_on,
          active_version: article_info.version, # Should not always be modified (if already set)
        } |> Noizu.Cms.V2.Database.IndexTable.write!
    end
  end

  def delete_index(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    Noizu.Cms.V2.Database.IndexTable.delete(ref)
  end

  def delete_index!(entity, _context, _options) do
    ref = Noizu.ERP.ref(entity)
    Noizu.Cms.V2.Database.IndexTable.delete!(ref)
  end

  #-----------------------------------
  # Versioning convenience methods
  #-----------------------------------
  def create_new_version(entity, context, options \\ %{}) do
    # @todo pri-0
    # The current methodology should be tweaked.
    # Depending on if our goal here is to provide CMS versioning of entities or simple versioning to allow later recovery.
    #
    # The currently persisted entity (if any) should always reflect the active version.
    # Creating a new version therefore should only create new version entries but not update the base table unless flagged as make_active.
    #  
    # any crm libraries or functions should generally work with version/revisions. that contained nested entity structures.
    # CRUD options should be heavily modified
    options_a = options
                |> put_in([:new_version], true)
    entity.__struct__.repo().update(entity, context, options_a)
  end

  def create_new_version!(entity, context, options \\ %{}) do
    options_a = options
                |> put_in([:new_version], true)
    entity.__struct__.repo().update!(entity, context, options_a)
  end

  def create_new_revision(entity, context, options \\ %{}) do
    options_a = options
                |> put_in([:new_revision], true)
    entity.__struct__.repo().update(entity, context, options_a)
  end

  def create_new_revision!(entity, context, options \\ %{}) do
    options_a = options
                |> put_in([:new_revision], true)
    entity.__struct__.repo().update!(entity, context, options_a)
  end

  #---------------------------
  # Repo Callback Overrides
  #---------------------------
  def pre_create_callback(entity, context, options) do
    options = update_in(options, [:auto_version], &((&1 == nil && true) || &1 ))
    entity = ((entity.identifier == nil) && %{entity| identifier: entity.__struct__.repo().generate_identifier()} || entity)
             |> prepare_article_info(context, options)
    cond do
      options[:new_version] ->
        entity.__struct__.repo().versioning_provider().assign_new_version(entity, context, options)
      options[:new_revision] ->
        # assign_new_revision will generate the appropriate version and revision record if not yet set.
        entity.__struct__.repo().versioning_provider().assign_new_revision(entity, context, options)
      true ->
        # overwrite_revision will generate the appropriate version and revision record if not yet set.
        entity.__struct__.repo().versioning_provider().overwrite_revision(entity, context, options)
    end
  end

  def pre_update_callback(entity, context, options) do
    # Revision and Versioning logic controlled by input parameters.
    # If call made with out specifying new version, new revision than existing values will simply be updated.
    options = update_in(options, [:auto_version], &((&1 == nil && true) || &1 ))
    entity = update_article_info(entity, context, options)
    cond do
      options[:new_version] ->
        entity.__struct__.repo().versioning_provider().assign_new_version(entity, context, options)
      options[:new_revision] ->
        entity.__struct__.repo().versioning_provider().assign_new_revision(entity, context, options)
      true ->
        entity.__struct__.repo().versioning_provider().overwrite_revision(entity, context, options)
    end
  end

  def pre_delete_callback(entity, _context, _options), do: entity

  def post_create_callback(entity, context, options) do
    if options[:make_active] do
      update_tags(entity, context, options)
      update_index(entity, context, options)
    end
    entity
  end

  def post_get_callback(entity, _context, _options), do: entity

  def post_update_callback(entity, context, options) do
    if options[:make_active] do
      update_tags(entity, context, options)
      update_index(entity, context, options)
    end
    entity
  end

  def post_delete_callback(entity, context, options) do
    versions = Noizu.Cms.V2.VersionRepo.entity_versions(entity, context, options)
    Enum.map(versions, fn(version) ->  Noizu.Cms.V2.VersionRepo.delete(version, context) end)

    revisions = Noizu.Cms.V2.Version.RevisionRepo.entity_revisions(entity, context, options)
    Enum.map(revisions, fn(revision) ->  Noizu.Cms.V2.Version.RevisionRepo.delete(revision, context) end)

    # Delete Tags
    delete_tags(entity, context, options)
    delete_index(entity, context, options)
    entity
  end

  defp update_article_info(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> put_in([Access.key(:article)], Noizu.ERP.ref(entity))
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
    entity
    |> Noizu.Cms.V2.Proto.set_article_info(article_info, context, options)
  end

  defp prepare_article_info(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> put_in([Access.key(:article)], Noizu.ERP.ref(entity))
                   |> update_in([Access.key(:created_on)], &(&1 || current_time))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> update_in([Access.key(:type)], &(&1 || Noizu.Cms.V2.Proto.type(entity, context, options)))
    entity
    |> Noizu.Cms.V2.Proto.set_article_info(article_info, context, options)
  end


end