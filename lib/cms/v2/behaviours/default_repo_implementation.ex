#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.DefaultRepoImplementation do
  use Amnesia
  use Noizu.Cms.V2.Database.IndexTable
  use Noizu.Cms.V2.Database.TagTable
  use Noizu.Cms.V2.Database.VersionTable
  use Noizu.Cms.V2.Database.VersionHistoryTable

  alias Noizu.Cms.V2.Database.IndexTable
  alias Noizu.Cms.V2.Database.TagTable
  alias Noizu.Cms.V2.Database.VersionTable
  alias Noizu.Cms.V2.Database.VersionHistoryTable

  # @TODO use nested path versions instead of string versions, use matrix tree encoding and expose data structure for tracking next available version for parent version.
  # @TODO implement
  alias Noizu.Cms.V2.VersionRepo
  alias Noizu.Cms.V2.VersionEntity

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
  # version_exists?
  #----------------------------------
  def version_exists?(entry, version, context, options \\ %{}) do
    ref = Noizu.ERP.ref(entry)
    lookup_key = {ref, version}
    case Noizu.Cms.V2.Database.VersionSequenceTable.read(lookup_key) do
      %{} -> true
      nil -> false
    end
  end

  #----------------------------------
  # reserve_version
  #----------------------------------
  def reserve_version(entry, version, context, options \\ %{}) do
    ref = Noizu.ERP.ref(entry)
    if version != {} do
      {p, [c]} = Tuple.to_list(version) |> Enum.split(-1)
      parent_version = List.to_tuple(p)
      next_in_sequence = c + 1
      # @TODO data consistency check
      %Noizu.Cms.V2.Database.VersionSequenceTable{
        identifier: {ref, parent_version},
        next_in_sequence: next_in_sequence
      } |>  Noizu.Cms.V2.Database.VersionSequenceTable.write
    end

    # @TODO data consistency check
    inject_key = {ref, version}
    %Noizu.Cms.V2.Database.VersionSequenceTable{
      identifier: {Noizu.ERP.ref(entry), version},
      next_in_sequence: 1
    } |> Noizu.Cms.V2.Database.VersionSequenceTable.write
  end



  defp version_tree_info([], tree, hint) do
    :wip
  end

  defp version_tree_info([h], node, hint) do
    # @TODO data consistency checks.

    child = node.children[h]
    has_grand_children? = !((child.children == nil) || (child.children == %{}))
    max_sibling = Enum.max(Map.keys(node.children))


    ########################################################################
    # Version Path Logic
    ########################################################################

    # Goals - V2:
    # - Strategy Pattern for version maintenance
    # - Simple incrementing versions
    # - Parent Tracking
    # - Full Binary Copy
    # - Nothing Fancy.

    # Goals - V3:
    # - Support git style forking and merging of CMS repositories.
    # - Efficient Storage Mechanism/Deltas.













    # MVP,  Hash is a product of article, parent, editor, server, commit message, delta from parent, time and padding - Using HMAC


    # Temporary Action Plan,
    # 1. Document brief discussion of possible approaches.
    # 2. Use MVP implementation. Track Immediate Parent (so that we can rebuild tree in future).
    # Alternative,
    #
    #
    #
    # 1. Strictly increasing version counter per document.
    # 2. Internally track full version path for constructing delta version records.
    # 3. Internally track reverse path lookup:  `%{8: %{logical_path: 1.1.2.2, genealogy: 1.2.5.8}, hash: md5("#{sref}@#{1.2.5.8}")}`
    # 4. Use version hash strings or compressed paths to avoid confusing users with complex version identifiers when exposing srefs.
    # 5. track hash to version lookup table: e.g. hash_to_version = %{md5("sref@1.2.5.8") => 8}
    # 6. Use compressed path logic so that modifying the greatest child results in the insertion of an adjacent node instead of a child node in the identifier string.
    #
    # - Revision - Use user provided base selection alg to determine which node internal versions are based off of. (e.g. check direct parent and one up parent to see which delta is smaller for saved record).
    # - ? simpler solution. version + subversion logic.
    #
    #
    #                   :initial_version (1)
    #                            |
    #               |------------------------|----------------------|------------------------|
    #              2:(1.1,1.2)              3:(1.2,1.2.3)          9:(1.3,1.2.3.9)         10:(1.4,1.10)
    #               |
    #           |-------------------|------------------------|
    #          4:(1.1.1,1.2.4)     5:(1.1.2, 1.2.5)         6:(1.1.3,1.2.5.6)
    #                                |
    #                   |-------------------------|
    #                  7:(1.1.2.1,1.2.5.7)       8:(1.1.2.2,1.2.5.8)
    #
    # - If document parent is :initial_version aka {1} then the next version hint should be {1, 3}
    # - If document parent is {2} then version hint should be {O, 3}.



    # 1.1.1
    # 1.1.2
    # 1.2
    # 1.3

    cond do
      max_sibling == h -> hint ++ [(h + 1)]

      # if

      # Append Child if Current Version Already has children or has a newer/higher index sibling
      (has_grand_children? || (max_sibling != h)) ->
                                                           hint ++ [h, (Enum.max(Map.keys(child.children)) + 1)]
    end

    case do
      # Already has children, append next greatest child.
      child.has_children? -> hint ++ [h, (Enum.max(Map.keys(child.children)) + 1)]

      # Already has adjacent but has no children, append first child.
      (node.children[h + 1] != nil) -> hint ++ [h, 1]

      # Does not have adjacent sibling.
      true ->
        hint ++ [(h + 1)]
    end
  end

  defp version_tree_info([h|t], tree, hint) do
    # @TODO exception handling.
    version_tree_info(t, tree.children[h])
  end

  #----------------------------------
  # increment_cms_version
  #----------------------------------
  def increment_cms_version(entry, context, options \\ %{}) do
    ref = Noizu.ERP.ref(entry)

    # Determine Starting Version.
    current_version = case Noizu.Cms.V2.Proto.get_version(entry, context, options) do
      nil -> {}
      v when is_tuple(v) -> v
    end

    # Determine next available slot (Breadth first).
    case Noizu.Cms.V2.Database.VersionTreeTable.read!(ref) do
      t = %Noizu.Cms.V2.Database.VersionTreeTable{} ->

        # Walk through path, determine if sibling exists.


        :wip
      _ -> :wip
    end



    # ====================================================
    # @TODO change data structure  {ref, depth, tuple} or use a simple tree structure and force atomic access.
    # this will allow us to use simply incrementing versions 1,2,3,4,5, unless a user goes back and modifies a version that already has a child. e.g. edits version 3 when version 5 exists.
    # e.g Next version is next available slot unless next available slot is already taken in which case we add a layer of nesting.
    # ====================================================

    # Get next available version.
    lookup_key = {Noizu.ERP.ref(entry), parent_version}
    case Noizu.Cms.V2.Database.VersionSequenceTable.read(lookup_key) do
      %{next_in_sequence: n} ->
        child_version = List.to_tuple(Tuple.to_list(parent_version) ++ [n])
        # @TODO verify new version doesn't already exist
        reserve_version(entry, child_version, context, options)
        Noizu.Cms.V2.Proto.set_version(entry, child_version, context, options)
      v -> throw "Versioning System Error #{inspect v}"
    end


    # Insert Record if missing.
    if !version_exist?(entry, parent_version, context, options) do
      reserve_version(entry, parent_version, context, options)
    end

    # Get next available version.
    lookup_key = {Noizu.ERP.ref(entry), parent_version}
    case Noizu.Cms.V2.Database.VersionSequenceTable.read(lookup_key) do
      %{next_in_sequence: n} ->
        child_version = List.to_tuple(Tuple.to_list(parent_version) ++ [n])
        # @TODO verify new version doesn't already exist
        reserve_version(entry, child_version, context, options)
        Noizu.Cms.V2.Proto.set_version(entry, child_version, context, options)
      v -> throw "Versioning System Error #{inspect v}"
    end
  end


  #----------------------------------
  # increment_cms_version
  #----------------------------------
  def increment_cms_version(entry, context, options \\ %{}) do
    parent_version = case Noizu.Cms.V2.Proto.get_version(entry, context, options) do
      nil -> {}
      v when is_tuple(v) -> v
    end

    # ====================================================
    # @TODO change data structure  {ref, depth, tuple} or use a simple tree structure and force atomic access.
    # this will allow us to use simply incrementing versions 1,2,3,4,5, unless a user goes back and modifies a version that already has a child. e.g. edits version 3 when version 5 exists.
    # e.g Next version is next available slot unless next available slot is already taken in which case we add a layer of nesting.
    # ====================================================

    # Get next available version.
    lookup_key = {Noizu.ERP.ref(entry), parent_version}
    case Noizu.Cms.V2.Database.VersionSequenceTable.read(lookup_key) do
      %{next_in_sequence: n} ->
        child_version = List.to_tuple(Tuple.to_list(parent_version) ++ [n])
        # @TODO verify new version doesn't already exist
        reserve_version(entry, child_version, context, options)
        Noizu.Cms.V2.Proto.set_version(entry, child_version, context, options)
      v -> throw "Versioning System Error #{inspect v}"
    end


    # Insert Record if missing.
    if !version_exist?(entry, parent_version, context, options) do
      reserve_version(entry, parent_version, context, options)
    end

    # Get next available version.
    lookup_key = {Noizu.ERP.ref(entry), parent_version}
    case Noizu.Cms.V2.Database.VersionSequenceTable.read(lookup_key) do
      %{next_in_sequence: n} ->
        child_version = List.to_tuple(Tuple.to_list(parent_version) ++ [n])
        # @TODO verify new version doesn't already exist
        reserve_version(entry, child_version, context, options)
        Noizu.Cms.V2.Proto.set_version(entry, child_version, context, options)
      v -> throw "Versioning System Error #{inspect v}"
    end
  end

  #----------------------------------
  #
  #----------------------------------
  def get_version_history(entry, context, options \\ %{}) do
    (ref = Noizu.ERP.ref(entry)) && Enum.sort(VersionHistoryTable.read(ref) || [], &(&1.created_on <= &2.created_on)) || []
  end

  def get_version_history!(entry, context, options \\ %{}) do
    (ref = Noizu.ERP.ref(entry)) && Enum.sort(VersionHistoryTable.read!(ref) || [], &(&1.created_on <= &2.created_on)) || []
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
  def get_all_versions(entry, context, options \\ %{}) do
    if (ref = Noizu.ERP.ref(entry)) do
      record = VersionTable.match([identifier: {ref, :_}])
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
  def generate_version_hash(entry, version, context, options) do
    if ref = Noizu.ERP.ref(entry) do
      #m = elem(ref, 1)
      #v = m.repo().nmid_generator().generate({m, :version}, %{})
      :crypto.hash(:md5, "#{Noizu.ERP.sref(ref)}-#{version}") |> Base.encode16()
    end
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

  def write_version_record(entry, context, options \\ %{}) do
    version_entity = Noizu.Cms.V2.Proto.prepare_version(entry, context, options)
    version_entity = VersionRepo.create(version_entity, context, options)
    %VersionHistoryTable{
      article: Noizu.ERP.ref(entry),
      version: Noizu.ERP.ref(version_entity),
      parent_version: version_entity.parent,
      full_copy: version_entity.fully_copy,
      created_on: version_entity.created_on,
      editor: version_entity.editor
    } |> VersionHistoryTable.write()
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
  def delete_cms_records(entry, context, options \\[]) do
    article = Noizu.ERP.ref(entry)
    # Clear Tags
    TagTable.delete(article)

    # Clear Version History
    VersionHistoryTable.delete(article)

    # Clear Version Records
    record = VersionTable.match([identifier: {article, :_}])
             |> Amnesia.Selection.values()
             |> Enum.map(&( VersionTable.delete(&1.identifier)))

    entry
  end


  # @TODO provide hooks that can be called or overridden in repo's on_create/post_create, update, delete, etc. callbacks.
  # @note, so caller must insure identifier obtained before on_create/on_update is called, then generate version book keeping records (since these are tied article ref).
end