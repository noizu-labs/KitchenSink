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

  def cms_provider(m), do: m.repo()

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

  #-----------------------------
  #
  #-----------------------------
  def update_tags(entity, context, options) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    new_tags = case Noizu.Cms.V2.Proto.tags(entity, context, options) do
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
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    new_tags = case Noizu.Cms.V2.Proto.tags!(entity, context, options) do
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

  #-----------------------------
  #
  #-----------------------------
  def delete_tags(entity, context, options) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    # erase any existing tags
    Noizu.Cms.V2.Database.TagTable.delete(ref)
  end

  def delete_tags!(entity, context, options) do
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    # erase any existing tags
    Noizu.Cms.V2.Database.TagTable.delete!(ref)
  end

  #-----------------------------
  #
  #-----------------------------
  def update_index(entry, context, options) do
    entity = Noizu.ERP.entity(entry)
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
    cond do
      article_info.version == nil -> {:error, :version_not_set}
      article_info.revision == nil -> {:error, :revision_not_set}
      true ->
        case Noizu.Cms.V2.Database.IndexTable.read(ref) do
          index = %Noizu.Cms.V2.Database.IndexTable{} ->
            %Noizu.Cms.V2.Database.IndexTable{index|
              status: article_info.status,
              module: article_info.module,
              type: article_info.type,
              editor: article_info.editor,
              modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
              active_version: article_info.version,
              active_revision: article_info.revision,
            } |> Noizu.Cms.V2.Database.IndexTable.write
          _ ->
            %Noizu.Cms.V2.Database.IndexTable{
              article: article_info.article,
              status: article_info.status,
              module: article_info.module,
              type: article_info.type,
              editor: article_info.editor,
              created_on: article_info.created_on && DateTime.to_unix(article_info.created_on),
              modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
              active_version: article_info.version,
              active_revision: article_info.revision,
            } |> Noizu.Cms.V2.Database.IndexTable.write
        end
    end
  end


  def update_index!(entry, context, options) do
    entity = Noizu.ERP.entity!(entry)
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    article_info = Noizu.Cms.V2.Proto.get_article_info!(entity, context, options)
    cond do
      article_info.version == nil -> {:error, :version_not_set}
      article_info.revision == nil -> {:error, :revision_not_set}
      true ->
        case Noizu.Cms.V2.Database.IndexTable.read!(ref) do
          index = %Noizu.Cms.V2.Database.IndexTable{} ->
            %Noizu.Cms.V2.Database.IndexTable{index|
              status: article_info.status,
              module: article_info.module,
              type: article_info.type,
              editor: article_info.editor,
              modified_on: article_info.modified_on,
              active_version: article_info.version,
              active_revision: article_info.revision,
            } |> Noizu.Cms.V2.Database.IndexTable.write!
          _ ->
            %Noizu.Cms.V2.Database.IndexTable{
              article: article_info.article,
              status: article_info.status,
              module: article_info.module,
              type: article_info.type,
              editor: article_info.editor,
              created_on: article_info.created_on,
              modified_on: article_info.modified_on,
              active_version: article_info.version,
              active_revision: article_info.revision,
            } |> Noizu.Cms.V2.Database.IndexTable.write!
        end
    end
  end

  #-----------------------------
  #
  #-----------------------------
  def delete_index(entity, context, options) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    Noizu.Cms.V2.Database.IndexTable.delete(ref)
  end

  def delete_index!(entity, context, options) do
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    Noizu.Cms.V2.Database.IndexTable.delete!(ref)
  end

  #-----------------------------------
  # Versioning Related Methods
  #-----------------------------------

  #-----------------------------
  #
  #-----------------------------
  def make_active(entity, context, options \\ %{}) do
    # Entity may technically be a Version or Revision record.
    # This is fine as long as we can extract tags, and the details needed for the index.
    article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
    version = Noizu.Cms.V2.Proto.get_version(article, context, options)
    revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
    cond do
      version == nil -> {:error, :version_not_set}
      revision == nil -> {:error, :revision_not_set}
      true ->
        update_tags(article, context, options)
        update_index(article, context, options)
    end
    entity
  end

  def make_active!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> make_active(entity, context, options) end)
  end


  #-----------------------------
  #
  #-----------------------------
  def update_active(entity, context, options \\ %{}) do
    article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
    article_ref = Noizu.ERP.ref(article)

    if article do
      active_revision = get_active(article, context, options)
                        |> Noizu.ERP.ref()

      current_revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
                         |> Noizu.ERP.ref()

      if (active_revision && active_revision == current_revision) do
        # @note no data consistency check perform
        update_tags(article, context, options)
        update_index(article, context, options)
        entity
      else
        {:error, :not_active}
      end
    else
      {:error, :no_article}
    end
  end

  def update_active!(entity, context, options \\ %{}) do
    Amnesia.Fragment.async(fn -> update_active(entity, context, options) end)
  end

  #-----------------------------
  #
  #-----------------------------
  def remove_active(entity, context, options \\ %{}) do
    article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
    article && delete_index(article, context, options)
  end

  def remove_active!(entity, context, options \\ %{}) do
    article = Noizu.Cms.V2.Proto.get_article!(entity, context, options)
    article && delete_index!(article, context, options)
  end


  #-----------------------------
  #
  #-----------------------------
  def get_active(entity, context, options \\ %{}) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    case Noizu.Cms.V2.Database.IndexTable.read(ref) do
      index = %Noizu.Cms.V2.Database.IndexTable{} ->
        index.active_revision
      _ -> nil
    end
  end
  def get_active!(entity, context, options \\ %{}) do
    ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    case Noizu.Cms.V2.Database.IndexTable.read!(ref) do
      index = %Noizu.Cms.V2.Database.IndexTable{} ->
        index.active_revision
      _ -> nil
    end
  end

  #-----------------------------
  #
  #-----------------------------
  def init_article_info(entity, context, options) do
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

  def init_article_info!(entity, context, options) do
    Amnesia.Fragment.async(fn -> init_article_info(entity, context, options) end)
  end

  #-----------------------------
  #
  #-----------------------------
  def update_article_info(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> update_in([Access.key(:article)], &(&1 || article_ref))
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
    entity
    |> Noizu.Cms.V2.Proto.set_article_info(article_info, context, options)
  end

  def update_article_info!(entity, context, options) do
    Amnesia.Fragment.async(fn -> update_article_info(entity, context, options) end)
  end


  #-----------------------------
  # create/3
  #-----------------------------
  def create(entity, context, options) do
    # @todo conditional logic to insure only revision records persisted.
    module = entity.__struct__.repo()
    entity
    |> module.pre_create_callback(context, options)
    |> module.inner_create_callback(context, options)
    |> module.post_create_callback(context, options)
  end

  #-----------------------------
  #
  #-----------------------------
  def pre_create_callback(entity, context, options) do
    repo = entity.__struct__.repo()
    cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options)
    is_versioning_record? = Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)
    options_a = put_in(options, [:nested_create], true)

    # AutoGenerate Identifier if not set, check for already existing record.
    entity = cond do
      #1. AutoIncrement
      entity.identifier == nil -> %{entity| identifier: repo.generate_identifier()}

      #2. Recursion Check
      options[:nested_create] -> entity

      #3. Check for existing records.
      true ->
        # @todo if !is_version_record? we should specifically scan for any matching revisions.
        if repo.get(entity.identifier, Noizu.ElixirCore.CallingContext.system(context), options_a) do
          throw "[Create Exception] Record Exists: #{Noizu.ERP.sref(entity)}"
        else
          entity
        end
    end

    if is_versioning_record? do
      entity
      |> cms_provider.update_article_info(context, options)
      |> cms_provider.cms_versioning_provider().populate_versioning_records(context, options_a)
    else
      # 5. Prepare Version and Revision, modify identifier.
      entity
      |> cms_provider.init_article_info(context, options)
      |> cms_provider.cms_versioning_provider().initialize_versioning_records(context, options_a)
    end
  end

  #-----------------------------
  #
  #-----------------------------
  def post_create_callback(entity, context, options) do
    entity
  end

  #-----------------------------
  #
  #-----------------------------
  def get(module, identifier, context, options) do
    # @todo, this belongs in the version provider, this module shouldn't know the versioning formats.
    identifier = case identifier do
      {:revision, {i, v, r}} -> identifier
      {:version, {i, v}} ->
        version_ref = Noizu.Cms.V2.VersionEntity.ref({module.entity_module().ref(i), v})
        case Noizu.Cms.V2.Database.Version.ActiveRevisionTable.read(version_ref) do
          %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{revision: r} ->
            case Noizu.Cms.V2.Version.RevisionEntity.id(r) do
              {{:ref, Noizu.Cms.V2.VersionEntity, _}, revision} -> {:revision, {i, v, revision}}
              _ -> nil
            end
          _ -> nil
        end
      _ ->
        case Noizu.Cms.V2.Database.IndexTable.read(module.entity_module().ref(identifier)) do
          %Noizu.Cms.V2.Database.IndexTable{active_version: av, active_revision: ar} ->
            version = case Noizu.Cms.V2.VersionEntity.id(av) do
              {_, version} -> version
              _ -> nil
            end
            revision = case Noizu.Cms.V2.Version.RevisionEntity.id(ar) do
              {{:ref, Noizu.Cms.V2.VersionEntity, _}, revision} -> revision
              _ -> nil
            end
            version && revision && {:revision, {identifier, version, revision}}
          _ -> nil
        end
    end

    if identifier do
      module.inner_get_callback(identifier, context, options)
      |> module.post_get_callback(context, options)
    end
  end

  #-----------------------------
  #
  #-----------------------------
  def post_get_callback(entity, _context, _options) do
    entity
  end

  #-----------------------------
  #
  #-----------------------------
  def update(entity, context, options) do
    module = entity.__struct__.repo()
    entity
    |>  module.pre_update_callback(context, options)
    |>  module.inner_update_callback(context, options)
    |>  module.post_update_callback(context, options)
  end

  #-----------------------------
  #
  #-----------------------------
  def pre_update_callback(entity, context, options) do
    if (entity.identifier == nil), do: throw "Identifier not set"
    if (!Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)), do: throw "#{entity.__struct__} entities may only be persisted using cms revision ids"

    options_a = put_in(options, [:nested_update], true)
    cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options)

    entity
    |> cms_provider.update_article_info(context, options)
    |> cms_provider.cms_versioning_provider().populate_versioning_records(context, options_a)
  end

  #-----------------------------
  #
  #-----------------------------
  def post_update_callback(entity, context, options) do
    entity
  end

  #-----------------------------
  #
  #-----------------------------
  def delete(entity, context, options) do
    # @todo conditional logic to insure only revision records persisted.
    module = entity.__struct__.repo()
    entity
    |>  module.pre_delete_callback(context, options)
    |>  module.inner_delete_callback(context, options)
    |>  module.post_delete_callback(context, options)
    true
  end

  #-----------------------------
  #
  #-----------------------------
  def pre_delete_callback(entity, context, options) do
    # - throw if active revision (require special delete cms command)
    # - throw if identifier not set.
    entity
  end

  #-----------------------------
  #
  #-----------------------------
  def post_delete_callback(entity, context, options) do
    entity
  end
end