#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.DefaultRepoImplementation do
    use Noizu.Cms.V2.Database.EntryTable
    use Noizu.Cms.V2.Database.Entry.TagTable
    use Noizu.Cms.V2.Database.Entry.VersionTable
    use Noizu.Cms.V2.Database.Entry.VersionHistoryTable

    alias Noizu.Cms.V2.Database.EntryTable
    alias Noizu.Cms.V2.Database.Entry.TagTable
    alias Noizu.Cms.V2.Database.Entry.VersionTable
    alias Noizu.Cms.V2.Database.Entry.VersionHistoryTable

    # @TODO use nested path versions instead of string versions, use matrix tree encoding and expose data structure for tracking next available version for parent version.
    # @TODO implement
    alias Noizu.Cms.V2.Entry.VersionRepo
    # @TODO implement
    alias Noizu.Cms.V2.Entry.VersionEntity

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
      |> EntryTable.match()
      |> Amnesia.Selection.values
    end
    def match_records!(filter, context, options), do: Amnesia.Fragment.async(fn -> match_records(filter, context, options) end)

    #----------------------------------
    #
    #----------------------------------
    def filter_records(records, _context, options) when is_list(records) do
      cond do
        Kernel.match({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          Enum.filter(records, &(&1 && &1.type == t || false))
        Kernel.match({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
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
      |> Enum.map(&(EntryTable.read(&1.article)))
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
        |> Enum.map(&(EntryTable.read!(&1.article)))
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
      from_ts = is_integer(from) && from || DateTime.to_unix!(from)
      to_ts = is_integer(to) && to || DateTime.to_unix!(to)
      cond do
        Kernel.match({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          EntryTable.where(type == t && created_on >= from_ts && created_on < to_ts)
        Kernel.match({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
          m = elem(options.filter, 1)
          EntryTable.where(module == m && created_on >= from_ts && created_on < to_ts)
        true -> EntryTable.where(created_on >= from_ts && created_on < to_ts)
      end
      |> Amnesia.Selection.values
      |> expand_records(context, options)
    end

    def get_by_created_on!(from, to, context, options \\ %{}) do
      options = Map.merge(@default_options, options)
      from_ts = is_integer(from) && from || DateTime.to_unix!(from)
      to_ts = is_integer(to) && to || DateTime.to_unix!(to)
      Amnesia.Fragment.async(fn ->
        cond do
          Kernel.match({:type, _}, options.filter) ->
            t = elem(options.filter, 1)
            EntryTable.where(type == t && created_on >= from_ts && created_on < to_ts)
          Kernel.match({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
            m = elem(options.filter, 1)
            EntryTable.where(module == m && created_on >= from_ts && created_on < to_ts)
          true -> EntryTable.where(created_on >= from_ts && created_on < to_ts)
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
      from_ts = is_integer(from) && from || DateTime.to_unix!(from)
      to_ts = is_integer(to) && to || DateTime.to_unix!(to)
      cond do
        Kernel.match({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          EntryTable.where(type == t && modified_on >= from_ts && modified_on < to_ts)
        Kernel.match({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
          m = elem(options.filter, 1)
          EntryTable.where(module == m && modified_on >= from_ts && modified_on < to_ts)
        true -> EntryTable.where(modified_on >= from_ts && modified_on < to_ts)
      end
      |> Amnesia.Selection.values
      |> expand_records(context, options)
    end

    def get_by_modified_on!(from, to, context, options \\ %{}) do
      options = Map.merge(@default_options, options)
      from_ts = is_integer(from) && from || DateTime.to_unix!(from)
      to_ts = is_integer(to) && to || DateTime.to_unix!(to)
      Amnesia.Fragment.async(fn ->
        cond do
          Kernel.match({:type, _}, options.filter) ->
            t = elem(options.filter, 1)
            EntryTable.where(type == t && modified_on >= from_ts && modified_on < to_ts)
          Kernel.match({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
            m = elem(options.filter, 1)
            EntryTable.where(module == m && modified_on >= from_ts && modified_on < to_ts)
          true -> EntryTable.where(modified_on >= from_ts && modified_on < to_ts)
        end
        |> Amnesia.Selection.values
      end)
      |> expand_records!(context, options)
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
    def generate_version_hash(entry, context, options) do
      # @TODO Generate Version Hash - Get nmid id, hash it with entry ref.
    end

    #----------------------------------
    #
    #----------------------------------
    def update_cms_records(entry, version, context, options \\[]) do
      # @TODO Update Tags
      # @TODO Update VersionTable (automatically updates VersionHistoryTable)
    end

    #----------------------------------
    #
    #----------------------------------
    def delete_cms_records(entry, context, options \\[]) do
      # @TODO Delete Tags
      # @TODO Delete VersionTable (automatically deletes VersionHistoryTable)
    end

end