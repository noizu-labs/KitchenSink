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
  alias Noizu.Cms.V2.Database.VersionTable

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



  #----------------------------------
  #
  #----------------------------------
  def update_cms_tags(entry, context, options \\ %{}) do
    article = Noizu.ERP.ref(entry)
    tags = Noizu.Cms.V2.Proto.tags(entry, context, options)
    TagTable.delete(article)
    Enum.map(tags, fn(tag) ->
      %TagTable{article: article, tag: tag} |> TagTable.write
    end)
    entry
  end


  def update_cms_master_table(entry, context, options \\ %{}) do
    index_details = Noizu.Cms.V2.Proto.index_details(entry, context, options)
    %IndexTable{
      article: index_details.article,
      status: index_details.status,
      module: index_details.module,
      type: index_details.type,
      editor: index_details.editor,
      created_on: index_details.created_on,
      modified_on: index_details.modified_on,
    } |> IndexTable.write()
    entry
  end

  #----------------------------------
  #
  #----------------------------------
  def delete_cms_records(entry, _context, _options \\[]) do
    article = Noizu.ERP.ref(entry)
    # Clear Tags
    TagTable.delete(article)

    # Clear Version History
    #VersionHistoryTable.delete(article)

    # Clear Version Records
    _record = VersionTable.match([identifier: {article, :_}])
             |> Amnesia.Selection.values()
             |> Enum.map(&( VersionTable.delete(&1.identifier)))

    # Clear Version Edit Records (match on article part of identifier)

    entry
  end

  #---------------------------
  # Repo Callback Overrides
  #---------------------------
  def pre_create_callback(entity, context, options) do
    entity = if entity.identifier == nil do
      %{entity| identifier: entity.__struct__.repo().generate_identifier()}
    else
      entity
    end

    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
                   |> put_in([Access.key(:article)], Noizu.ERP.ref(entity))
                   |> put_in([Access.key(:created_on)], DateTime.utc_now())
                   |> put_in([Access.key(:modified_on)], DateTime.utc_now())
                   |> put_in([Access.key(:editor)], context.caller)
                   |> update_in([Access.key(:status)], &(&1 || :pending))
                   |> update_in([Access.key(:type)], &(&1 || Noizu.Cms.V2.Proto.type(entity, context, options)))

    entity
    |> Noizu.Cms.V2.Proto.set_article_info(article_info, context, options)
    |> entity.__struct__.repo().create_version(context, options)
  end


  def pre_update_callback(entity, context, options) do
    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
                   |> put_in([Access.key(:article)], Noizu.ERP.ref(entity))
                   |> put_in([Access.key(:modified_on)], DateTime.utc_now())
                   |> put_in([Access.key(:editor)], context.caller)
                   |> update_in([Access.key(:status)], &(&1 || :pending))

    # @todo default type, version data if not set.

    # Create Version Record
    # Create Revision Record

    Noizu.Cms.V2.Proto.set_article_info(entity, article_info, context, options)
  end

  def pre_delete_callback(entity, context, options), do: entity


  def post_create_callback(entity, context, options) do
    ref = Noizu.ERP.ref(entity)
    tags = Noizu.Cms.V2.Proto.tags(ref, context, options)

    #--------------------
    # Inject Tags
    #--------------------

    # erase any existing tags
    Noizu.Cms.V2.Database.TagTable.delete(ref)

    # insert new tags
    Enum.map(tags, fn(tag) ->
      %Noizu.Cms.V2.Database.TagTable{article: ref, tag: tag} |> Noizu.Cms.V2.Database.TagTable.write()
    end)

    #--------------------
    # Inject Index
    #--------------------
    article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
    # @todo nil check

    %Noizu.Cms.V2.Database.IndexTable{
      article: ref,
      status: article_info.status,
      module: entity.__struct__,
      type: article_info.type,
      editor: article_info.editor,
      created_on: article_info.created_on,
      modified_on: article_info.modified_on,
      active_version: article_info.version,
    } |> Noizu.Cms.V2.Database.IndexTable.write

    entity
  end

  def post_get_callback(entity, context, options), do: entity

  def post_update_callback(entity, context, options) do
    # Update Tags
    # Update Index
    # . . .
    entity
  end


  def post_delete_callback(entity, context, options) do
    # delete versions
    # delete tags
    # delete revisions
    # delete index

    entity
  end
end