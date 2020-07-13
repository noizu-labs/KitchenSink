#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.Cms.V2.CmsBehaviour do
  defmodule Default do
    use Amnesia

    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    alias Noizu.Cms.V2.Database.IndexTable
    #alias Noizu.Cms.V2.Database.VersionTable
    alias Noizu.Cms.V2.Database.TagTable

    use Noizu.Cms.V2.Database.IndexTable
    use Noizu.Cms.V2.Database.VersionTable
    use Noizu.Cms.V2.Database.TagTable


    @default_options %{
      expand: true,
      filter: false
    }


    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
          # Tag Provider
          # Index Provider
          # Version Provider
        }
      }
      OptionSettings.expand(settings, options)
    end


    #----------------------------------
    # expand_records/4
    #----------------------------------
    # TODO move expand_records to cms protocol.
    def expand_records(records, _context, %{expand: true}, _caller) when is_list(records), do: Enum.map(records, &(Noizu.ERP.entity(&1.article))) |> Enum.filter(&(&1 != nil))
    def expand_records(records, _context, _, _caller) when is_list(records), do: records
    def expand_records(e, _context, _, _caller), do: throw {:error, e}

    #----------------------------------
    # expand_records!/4
    #----------------------------------
    def expand_records!(records, _context, %{expand: true}, _caller) when is_list(records), do: Enum.map(records, &(Noizu.ERP.entity!(&1.article))) |> Enum.filter(&(&1 != nil))
    def expand_records!(records, _context, _, _caller) when is_list(records), do: records
    def expand_records!(e, _context, _, _caller), do: throw {:error, e}


    #----------------------------------
    # match_records/4
    #----------------------------------
    # @TODO submodule CMS.Index
    def match_records(filter, _context, options, _caller) do
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


    #----------------------------------
    # match_records!/4
    #----------------------------------
    def match_records!(filter, context, options, caller), do: Amnesia.Fragment.async(fn -> caller.cms().match_records(filter, context, options) end)

    #----------------------------------
    # filter_records/4
    #----------------------------------
    def filter_records(records, _context, options, _caller) when is_list(records) do
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
    def filter_records(e, _context, _, _caller), do: throw {:error, e}

    #----------------------------------
    # get_by_status/4
    #----------------------------------
    def get_by_status(status, context, options, caller) do
      options = Map.merge(@default_options, options)
      [status: status]
      |> caller.cms().match_records(context, options)
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_status!/4
    #----------------------------------
    def get_by_status!(status, context, options, caller) do
      options = Map.merge(@default_options, options)
      [status: status]
      |> caller.cms().match_records!(context, options)
      |> caller.cms().expand_records!(context, options)
    end

    #----------------------------------
    # get_by_type/4
    #----------------------------------
    def get_by_type(type, context, options, caller) do
      options = Map.merge(@default_options, options)
      [type: type]
      |> caller.cms().match_records(context, options)
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_type!/4
    #----------------------------------
    def get_by_type!(type, context, options, caller) do
      options = Map.merge(@default_options, options)
      [type: type]
      |> caller.cms().match_records!(context, options)
      |> caller.cms().expand_records!(context, options)
    end

    #----------------------------------
    # get_by_module/4
    #----------------------------------
    def get_by_module(module, context, options, caller) do
      options = Map.merge(@default_options, options)
      [module: module]
      |> caller.cms().match_records(context, options)
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_module!/4
    #----------------------------------
    def get_by_module!(module, context, options, caller) do
      options = Map.merge(@default_options, options)
      [module: module]
      |> caller.cms().match_records!(context, options)
      |> caller.cms().expand_records!(context, options)
    end

    #----------------------------------
    # get_by_editor/4
    #----------------------------------
    def get_by_editor(editor, context, options, caller) do
      options = Map.merge(@default_options, options)
      [editor: editor]
      |> caller.cms().match_records(context, options)
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_editor!/4
    #----------------------------------
    def get_by_editor!(editor, context, options, caller) do
      options = Map.merge(@default_options, options)
      [editor: editor]
      |> caller.cms().match_records!(context, options)
      |> caller.cms().expand_records!(context, options)
    end

    #----------------------------------
    # get_by_tag/4
    #----------------------------------
    def get_by_tag(tag, context, options, caller) do
      options = Map.merge(@default_options, options)
      [tag: tag]
      |> TagTable.match()
      |> Amnesia.Selection.values()
      |> Enum.map(&(IndexTable.read(&1.article)))
      |> caller.cms().filter_records(context, options)
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_tag!/4
    #----------------------------------
    def get_by_tag!(tag, context, options, caller) do
      options = Map.merge(@default_options, options)
      records = Amnesia.Fragment.async(fn ->
        [tag: tag]
        |> TagTable.match()
        |> Amnesia.Selection.values()
      end)

      if is_list(records) do
        records
        |> Enum.map(&(IndexTable.read!(&1.article)))
        |> caller.cms().filter_records(context, options)
        |> caller.cms().expand_records!(context, options)
      else
        throw {:error, records}
      end
    end

    #----------------------------------
    # get_by_created_on/5
    #----------------------------------
    def get_by_created_on(from, to, context, options, caller) do
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
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_created_on!/4
    #-----------------------5----------
    def get_by_created_on!(from, to, context, options, caller) do
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
      |> caller.cms().expand_records!(context, options)
    end

    #----------------------------------
    # get_by_modified_on/5
    #----------------------------------
    def get_by_modified_on(from, to, context, options, caller) do
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
      |> caller.cms().expand_records(context, options)
    end

    #----------------------------------
    # get_by_modified_on!/5
    #----------------------------------
    def get_by_modified_on!(from, to, context, options, caller) do
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
      |> caller.cms().expand_records!(context, options)
    end



    #=====================================================
    # Tag Methods
    #=====================================================

    #-----------------------------
    # update_tags/4
    #-----------------------------
    def update_tags(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      new_tags = case Noizu.Cms.V2.Proto.tags(entity, context, options) do
        v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
        v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
        nil -> []
      end

      existing_tags = case TagTable.read(ref) do
        v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
        nil -> []
        v -> {:error, v}
      end

      if (new_tags != existing_tags) do
        # erase any existing tags
        TagTable.delete(ref)

        # insert new tags
        Enum.map(new_tags, fn(tag) ->
          %TagTable{article: ref, tag: tag} |> TagTable.write()
        end)
      end
    end

    #-----------------------------
    # update_tags!/4
    #-----------------------------
    def update_tags!(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      new_tags = case Noizu.Cms.V2.Proto.tags!(entity, context, options) do
        v when is_list(v) -> v |> Enum.uniq() |> Enum.sort()
        v = %MapSet{} -> MapSet.to_list(v) |> Enum.uniq() |> Enum.sort()
        nil -> []
      end

      existing_tags = case TagTable.read!(ref) do
        v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
        nil -> []
        v -> {:error, v}
      end

      if (new_tags != existing_tags) do
        # erase any existing tags
        TagTable.delete!(ref)

        # insert new tags
        Enum.map(new_tags, fn(tag) ->
          %TagTable{article: ref, tag: tag} |> TagTable.write!()
        end)
      end
    end

    #-----------------------------
    # delete_tags/4
    #-----------------------------
    def delete_tags(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      # erase any existing tags
      TagTable.delete(ref)
    end

    #-----------------------------
    # delete_tags!/4
    #-----------------------------
    def delete_tags!(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      # erase any existing tags
      TagTable.delete!(ref)
    end

    #-----------------------------
    # update_index/4
    #-----------------------------
    def update_index(entry, context, options, _caller) do
      entity = Noizu.ERP.entity(entry)
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
      cond do
        article_info.version == nil -> {:error, :version_not_set}
        article_info.revision == nil -> {:error, :revision_not_set}
        true ->
          case IndexTable.read(ref) do
            index = %IndexTable{} ->
              %IndexTable{index|
                status: article_info.status,
                module: article_info.module,
                type: article_info.type,
                editor: article_info.editor,
                modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
                active_version: article_info.version,
                active_revision: article_info.revision,
              } |> IndexTable.write
            _ ->
              %IndexTable{
                article: article_info.article,
                status: article_info.status,
                module: article_info.module,
                type: article_info.type,
                editor: article_info.editor,
                created_on: article_info.created_on && DateTime.to_unix(article_info.created_on),
                modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
                active_version: article_info.version,
                active_revision: article_info.revision,
              } |> IndexTable.write
          end
      end
    end

    #-----------------------------
    # update_index!/4
    #-----------------------------
    def update_index!(entry, context, options, _caller) do
      entity = Noizu.ERP.entity!(entry)
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info!(entity, context, options)
      cond do
        article_info.version == nil -> {:error, :version_not_set}
        article_info.revision == nil -> {:error, :revision_not_set}
        true ->
          case IndexTable.read!(ref) do
            index = %IndexTable{} ->
              %IndexTable{index|
                status: article_info.status,
                module: article_info.module,
                type: article_info.type,
                editor: article_info.editor,
                modified_on: article_info.modified_on,
                active_version: article_info.version,
                active_revision: article_info.revision,
              } |> IndexTable.write!
            _ ->
              %IndexTable{
                article: article_info.article,
                status: article_info.status,
                module: article_info.module,
                type: article_info.type,
                editor: article_info.editor,
                created_on: article_info.created_on,
                modified_on: article_info.modified_on,
                active_version: article_info.version,
                active_revision: article_info.revision,
              } |> IndexTable.write!
          end
      end
    end

    #-----------------------------
    # delete_index/4
    #-----------------------------
    def delete_index(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      IndexTable.delete(ref)
    end

    #-----------------------------
    # delete_index!/4
    #-----------------------------
    def delete_index!(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      IndexTable.delete!(ref)
    end

    #-----------------------------------
    # Versioning Related Methods
    #-----------------------------------

    #-----------------------------
    # make_active/4
    #-----------------------------
    def make_active(entity, context, options, caller) do
      # Entity may technically be a Version or Revision record.
      # This is fine as long as we can extract tags, and the details needed for the index.
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      version = Noizu.Cms.V2.Proto.get_version(article, context, options)
      revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
      cond do
        version == nil -> {:error, :version_not_set}
        revision == nil -> {:error, :revision_not_set}
        true ->
          caller.cms().update_tags(article, context, options)
          caller.cms().update_index(article, context, options)
      end
      entity
    end

    #-----------------------------
    # make_active!/4
    #-----------------------------
    def make_active!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().make_active(entity, context, options) end)
    end

    #-----------------------------
    # update_active/4
    #-----------------------------
    def update_active(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      #article_ref = Noizu.ERP.ref(article)

      if article do
        active_revision = caller.cms().get_active(article, context, options)
                          |> Noizu.ERP.ref()

        current_revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
                           |> Noizu.ERP.ref()

        if (active_revision && active_revision == current_revision) do
          # @note no data consistency check perform
          caller.cms().update_tags(article, context, options)
          caller.cms().update_index(article, context, options)
          entity
        else
          {:error, :not_active}
        end
      else
        {:error, :no_article}
      end
    end

    #-----------------------------
    # update_active!/4
    #-----------------------------
    def update_active!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().update_active(entity, context, options) end)
    end

    #-----------------------------
    # remove_active/4
    #-----------------------------
    def remove_active(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      article && caller.cms().delete_index(article, context, options)
    end

    #-----------------------------
    # remove_active!/4
    #-----------------------------
    def remove_active!(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article!(entity, context, options)
      article && caller.cms().delete_index!(article, context, options)
    end


    #-----------------------------
    # get_active/4
    #-----------------------------
    def get_active(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      case IndexTable.read(ref) do
        index = %IndexTable{} ->
          index.active_revision
        _ -> nil
      end
    end

    #-----------------------------
    # get_active!/4
    #-----------------------------
    def get_active!(entity, context, options, _caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      case IndexTable.read!(ref) do
        index = %IndexTable{} ->
          index.active_revision
        _ -> nil
      end
    end

    #-----------------------------
    # init_article_info/4
    #-----------------------------
    def init_article_info(entity, context, options, _caller) do
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

    #-----------------------------
    # init_article_info!/4
    #-----------------------------
    def init_article_info!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().init_article_info(entity, context, options) end)
    end

    #-----------------------------
    # update_article_info/4
    #-----------------------------
    def update_article_info(entity, context, options, _caller) do
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

    #-----------------------------
    # update_article_info!/4
    #-----------------------------
    def update_article_info!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().update_article_info(entity, context, options) end)
    end





    #------------------------------
    # new_version/4
    #------------------------------
    def new_version(entity, context, options, caller) do
      options_a = put_in(options, [:active_revision], true)
      case caller.cms().create_version(entity, context, options_a) do
        {:ok, {version, revision}} ->
          version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
          revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
          repo = entity.__struct__.repo()
          options_b = put_in(options_a, [:nested_versioning], true)
          entity
          |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options_b)
          |> Noizu.Cms.V2.Proto.set_version(version_ref, context, options_b)
          |> Noizu.Cms.V2.Proto.set_parent(version.parent, context, options_b)
          |> repo.update(context, options_a)
        {:error, e} -> throw {:error, {:creating_revision, e}}
        e -> throw {:error, {:creating_revision, {:unknown, e}}}
      end
    end

    #------------------------------
    #
    #------------------------------
    def new_version!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().new_version(entity, context, options) end)
    end

    #------------------------------
    #
    #------------------------------
    def new_revision(entity, context, options, caller) do
      #options_a = put_in(options, [:active_revision], true)
      case caller.cms().create_revision(entity, context, options) do
        {:ok, revision} ->
          revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
          repo = entity.__struct__.repo()
          options_a = put_in(options, [:nested_versioning], true)
          entity
          |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options_a)
          |> repo.update(context, options_a)
        {:error, e} -> throw {:error, {:creating_revision, e}}
        e -> throw {:error, {:creating_revision, {:unknown, e}}}
      end
    end

    #------------------------------
    #
    #------------------------------
    def new_revision!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().new_revision(entity, context, options) end)
    end

    #------------------------------
    #
    #------------------------------
    def initialize_versioning_records(entity, context, options, caller) do
      options = put_in(options, [:active_revision], true)
      case caller.cms().create_version(entity, context, options) do
        {:ok, {version, revision}} ->
          entity = entity
                   |> Noizu.Cms.V2.Proto.set_version(Noizu.Cms.V2.VersionEntity.ref(version), context, options)
                   |> Noizu.Cms.V2.Proto.set_revision(Noizu.Cms.V2.Version.RevisionEntity.ref(revision), context, options)
                   |> Noizu.Cms.V2.Proto.set_parent(Noizu.Cms.V2.VersionEntity.ref(version.parent), context, options)
          v_id = Noizu.Cms.V2.Proto.versioned_identifier(entity, context, options)
          entity = entity
                   |> put_in([Access.key(:identifier)], v_id)


          #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
            #cms_provider.update_tags(entity, context, options)
            #cms_provider.update_index(entity, context, options)
            caller.cms().update_tags(entity, context, options)
            caller.cms().update_index(entity, context, options)
          #end
          entity
        e -> throw "initialize_versioning_records error: #{inspect e}"
      end
    end

    #------------------------------
    #
    #------------------------------
    def populate_versioning_records(entity, context, options, caller) do
      if options[:nested_versioning] do
        entity
      else

        version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
        version_ref = Noizu.Cms.V2.VersionEntity.ref(version)

        revision = Noizu.Cms.V2.Proto.get_version(entity, context, options)
        revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)

        # if active revision then update version table, otherwise only update revision.
        case Noizu.Cms.V2.Database.Version.ActiveRevisionTable.read(version_ref) do
          %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{revision: active_revision_ref} ->

            if active_revision_ref == revision_ref || options[:active_revision] == true do
              case caller.cms().update_version(entity, context, options) do
                {:ok, _} ->
                  entity
                e -> throw "populate_versioning_records error: #{inspect e}"
              end
            else
              case caller.cms().update_revision(entity, context, options) do
                {:ok, _} ->
                  entity
                e -> throw "populate_versioning_records error: #{inspect e}"
              end
            end

          _ ->
            options_a = put_in(options, [:active_revision], true)
            case caller.cms().update_version(entity, context, options_a) do
              {:ok, _} ->
                entity
              e -> throw "populate_versioning_records error: #{inspect e}"
            end
        end
      end
    end

    #------------------------
    #
    #------------------------
    def get_versions(entity, context, options, _caller) do
      article_ref = Noizu.Cms.V2.Proto.get_article(entity, context, options)
                    |> Noizu.ERP.ref()
      cond do
        article_ref ->
          Noizu.Cms.V2.Database.VersionTable.match([identifier: {article_ref, :_}])
          |> Amnesia.Selection.values()
          |> Enum.map(&(&1.entity))
        true -> {:error, :article_unknown}
      end
    end

    #------------------------------
    #
    #------------------------------
    def get_versions!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().get_versions(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def create_version(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      article_ref =  Noizu.Cms.V2.Proto.article_ref(article, context, options)

      # 1. get current version.
      current_version = Noizu.Cms.V2.Proto.get_version(article, context, options)
      current_version_ref = Noizu.Cms.V2.VersionEntity.ref(current_version)

      # 2. Determine version path we will be creating
      new_version_path = cond do
        current_version == nil ->
          {version_sequencer({article_ref, {}})}
        true ->
          {:ref, _, {_article, path}} = current_version_ref
          List.to_tuple(Tuple.to_list(path) ++ [version_sequencer({article_ref, path})])
      end

      # 3. Create Version Stub
      new_version_key = {article_ref, new_version_path}
      # new_version_ref = Noizu.Cms.V2.VersionEntity.ref(new_version_key)

      article = article
                |> Noizu.Cms.V2.Proto.set_version(new_version_key, context, options)
                |> Noizu.Cms.V2.Proto.set_parent(current_version_ref, context, options)
                |> Noizu.Cms.V2.Proto.set_revision(nil, context, options)

      case caller.cms().create_revision(article, context, options) do
        {:ok, revision} ->
          # Create Version Record
          version = %Noizu.Cms.V2.VersionEntity{
                      identifier: new_version_key,
                      article: article_ref,
                      parent: current_version_ref,
                      created_on: revision.created_on,
                      modified_on: revision.modified_on,
                      editor: revision.editor,
                      status: revision.status,
                    } |> Noizu.Cms.V2.VersionRepo.create(context, options)
          {:ok, {version, revision}}

        {:error, e} -> {:error, {:creating_revision, e}}
        e -> {:error, {:creating_revision, {:unknown, e}}}
      end
    end

    #------------------------------
    #
    #------------------------------
    def create_version!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().create_version(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def update_version(entity, context, options, caller) do
      # 1. get current version.
      current_version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                        |> Noizu.Cms.V2.VersionEntity.entity()

      cond do
        current_version == nil -> {:error, :invalid_version}
        true ->
          case caller.cms().update_revision(entity, context, options) do
            {:ok, revision} ->
              version = %Noizu.Cms.V2.VersionEntity{
                          current_version|
                          modified_on: revision.modified_on,
                          editor: revision.editor,
                          status: revision.status,
                        } |> Noizu.Cms.V2.VersionRepo.update(context, options)
              {:ok, {version, revision}}
            _ -> {:error, :update_revision}
          end
      end
    end

    #------------------------------
    #
    #------------------------------
    def update_version!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().update_version(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def delete_version(entity, context, options, caller) do
      version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                    |> Noizu.ERP.ref()

      # Active Revision Check
      if options[:bookkeeping] != :disabled do
        #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
          if active_revision = caller.cms().get_active(entity, context, options) do
            active_version = Noizu.Cms.V2.Proto.get_version(active_revision, context, options)
                             |> Noizu.ERP.ref()
            if (active_version && active_version == version_ref), do: throw :cannot_delete_active
          end
        #end
      end

      cond do
        version_ref ->
          # Get revisions,
          case caller.cms().get_revisions(entity, context, options) do
            revisions when is_list(revisions) ->
              # delete active revision mapping.
              Noizu.Cms.V2.Database.Version.ActiveRevisionTable.delete(version_ref)

              # Delete Revisions
              Enum.map(revisions, fn(revision) ->
                # Bypass Repo, delete directly for performance reasons.
                Noizu.Cms.V2.Database.Version.RevisionTable.delete(revision.identifier)
              end)

              # Delete Version
              # Bypass Repo, delete directly for performance reasons.
              identifier = Noizu.ERP.id(version_ref)
              Noizu.Cms.V2.Database.VersionTable.delete(identifier)

              :ok
            _ -> {:error, :revision_lookup}
          end
        true -> {:error, :revision_not_set}
      end
    end

    #------------------------
    #
    #------------------------
    def delete_version!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().delete_version(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def get_revisions(entity, context, options, _caller) do
      version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                    |> Noizu.ERP.ref()
      cond do
        version_ref ->
          Noizu.Cms.V2.Database.Version.RevisionTable.match([identifier: {version_ref, :_}])
          |> Amnesia.Selection.values()
          |> Enum.map(&(&1.entity))
        true -> {:error, :version_unknown}
      end
    end

    #------------------------------
    #
    #------------------------------
    def get_revisions!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().get_revisions(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def create_revision(entity, context, options, _caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      article_ref =  Noizu.Cms.V2.Proto.article_ref(article, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info(article, context, options)
      current_time = options[:current_time] || DateTime.utc_now()
      article_info = %Noizu.Cms.V2.Article.Info{article_info| modified_on: current_time, created_on: current_time}
      article = Noizu.Cms.V2.Proto.set_article_info(article, article_info, context, options)

      version = Noizu.Cms.V2.Proto.get_version(article, context, options)
      version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
      version_key = Noizu.Cms.V2.VersionEntity.id(version)

      cond do
        article == nil -> {:error, :invalid_record}
        version == nil -> {:error, :no_version_provided}
        true ->
          revision_key = options[:revision_key] || {version_ref, version_sequencer({:revision, version_key})}
          revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision_key)
          article = article
                    |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options)

          {archive_type, archive} = Noizu.Cms.V2.Proto.compress_archive(article, context, options)

          revision = %Noizu.Cms.V2.Version.RevisionEntity{
                       identifier: revision_key,
                       article: article_ref,
                       version: version_ref,
                       created_on: article_info.created_on,
                       modified_on: article_info.modified_on,
                       editor: article_info.editor,
                       status: article_info.status,
                       archive_type: archive_type,
                       archive: archive,
                     } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)

          case revision do
            %Noizu.Cms.V2.Version.RevisionEntity{} ->

              # Create Active Version Record.
              if options[:active_revision] do
                %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{
                  version: Noizu.Cms.V2.VersionEntity.ref(version_ref),
                  revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision_ref)
                } |> Noizu.Cms.V2.Database.Version.ActiveRevisionTable.write()
              end

              {:ok, revision}
            _ -> {:error, {:create_revision, revision}}
          end
      end
    end

    #------------------------
    #
    #------------------------
    def create_revision!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().create_revision(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def update_revision(entity, context, options, caller) do
      article_ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)

      version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
      version_ref = Noizu.Cms.V2.VersionEntity.ref(version)
      # version_key = Noizu.Cms.V2.VersionEntity.id(version)

      revision = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
      revision_ref = Noizu.Cms.V2.Version.RevisionEntity.ref(revision)
      revision_key = Noizu.Cms.V2.Version.RevisionEntity.id(revision)

      cond do
        article_ref == nil -> {:error, :invalid_record}
        version == nil -> {:error, :no_version_provided}
        revision == nil -> {:error, :no_revision_provided}
        true ->
          # load existing record.
          revision = if revision = Noizu.Cms.V2.Version.RevisionEntity.entity(revision) do
            %Noizu.Cms.V2.Version.RevisionEntity{
              revision|
              article: article_ref,
              version: version_ref,
              modified_on: article_info.modified_on,
              editor: article_info.editor,
              status: article_info.status,
            } |> Noizu.Cms.V2.Version.RevisionRepo.update(context)
          else

            # insure ref,version correctly set before obtained qualified (Versioned) ref.
            article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
                      |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options)
                      |> Noizu.Cms.V2.Proto.set_version(version_ref, context, options)
            {archive_type, archive} = Noizu.Cms.V2.Proto.compress_archive(article, context, options)

            %Noizu.Cms.V2.Version.RevisionEntity{
              identifier: revision_key,
              article: article_ref,
              version: version_ref,
              created_on: article_info.created_on,
              modified_on: article_info.modified_on,
              editor: article_info.editor,
              status: article_info.status,
              archive_type: archive_type,
              archive: archive,
            } |> Noizu.Cms.V2.Version.RevisionRepo.create(context)
          end


          # Create Active Version Record.
          if options[:active_revision] do
            %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{
              version: Noizu.Cms.V2.VersionEntity.ref(version_ref),
              revision: Noizu.Cms.V2.Version.RevisionEntity.ref(revision_ref)
            } |> Noizu.Cms.V2.Database.Version.ActiveRevisionTable.write()
          end

          # Update Active if modifying active revision
          if options[:bookkeeping] != :disabled do
            #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
              active_revision = caller.cms().get_active(entity, context, options)
              active_revision = active_revision && Noizu.ERP.ref(active_revision)
              if (active_revision && active_revision == revision_ref), do: caller.cms().update_active(entity, context, options)
            #end
          end
          # Return updated revision
          {:ok, revision}
      end
    end

    #------------------------------
    #
    #------------------------------
    def update_revision!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().update_revision(entity, context, options) end)
    end

    #------------------------
    #
    #------------------------
    def delete_revision(entity, context, options, caller) do
      revision_ref = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
                     |> Noizu.ERP.ref()

      # Active Revision Check
      if options[:bookkeeping] != :disabled do
        #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
          active_revision = caller.cms().get_active(entity, context, options)
                            |> Noizu.ERP.ref()
          if (active_revision && active_revision == revision_ref), do: throw :cannot_delete_active
        #end
      end

      cond do
        revision_ref ->
          # Bypass Repo, delete directly for performance reasons.
          identifier = Noizu.ERP.id(revision_ref)
          Noizu.Cms.V2.Database.Version.RevisionTable.delete(identifier)
          :ok
        true -> {:error, :revision_not_set}
      end
    end

    #------------------------
    #
    #------------------------
    def delete_revision!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms().delete_revision(entity, context, options) end)
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



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.CmsBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)
    # cms_options = cms_option_settings.effective_options

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])

      #----------------------------------
      # expand_records/3
      #----------------------------------
      def expand_records(records, context, options), do: @cms_implementation.expand_records(records, context, options, cms_base())

      #----------------------------------
      # expand_records!/3
      #----------------------------------
      def expand_records!(records, context, options), do: @cms_implementation.expand_records!(records, context, options, cms_base())

      #----------------------------------
      # match_records/3
      #----------------------------------
      def match_records(filter, context, options), do: @cms_implementation.match_records(filter, context, options, cms_base())

      #----------------------------------
      # match_records!/3
      #----------------------------------
      def match_records!(filter, context, options), do: @cms_implementation.match_records!(filter, context, options, cms_base())

      #----------------------------------
      # filter_records/3
      #----------------------------------
      def filter_records(records, context, options), do: @cms_implementation.filter_records(records, context, options, cms_base())

      #-------------------------
      # Query
      #-------------------------
      def get_by_status(status, context, options), do: @cms_implementation.get_by_status(status, context, options, cms_base())
      def get_by_status!(status, context, options), do: @cms_implementation.get_by_status!(status, context, options, cms_base())

      def get_by_type(type, context, options), do: @cms_implementation.get_by_type(type, context, options, cms_base())
      def get_by_type!(type, context, options), do: @cms_implementation.get_by_type!(type, context, options, cms_base())

      def get_by_module(module, context, options), do: @cms_implementation.get_by_module(module, context, options, cms_base())
      def get_by_module!(module, context, options), do: @cms_implementation.get_by_module!(module, context, options, cms_base())

      def get_by_editor(editor, context, options), do: @cms_implementation.get_by_editor(editor, context, options, cms_base())
      def get_by_editor!(editor, context, options), do: @cms_implementation.get_by_editor!(editor, context, options, cms_base())

      def get_by_tag(tag, context, options), do: @cms_implementation.get_by_tag(tag, context, options, cms_base())
      def get_by_tag!(tag, context, options), do: @cms_implementation.get_by_tag!(tag, context, options, cms_base())

      def get_by_created_on(from, to, context, options), do: @cms_implementation.get_by_created_on(from, to, context, options, cms_base())
      def get_by_created_on!(from, to, context, options), do: @cms_implementation.get_by_created_on!(from, to, context, options, cms_base())

      def get_by_modified_on(from, to, context, options), do: @cms_implementation.get_by_modified_on(from, to, context, options, cms_base())
      def get_by_modified_on!(from, to, context, options), do: @cms_implementation.get_by_modified_on!(from, to, context, options, cms_base())

      #-------------------------
      # Book Keeping
      #-------------------------
      def update_tags(entry, context, options), do: @cms_implementation.update_tags(entry, context, options, cms_base())
      def update_tags!(entry, context, options), do: @cms_implementation.update_tags!(entry, context, options, cms_base())

      def delete_tags(entry, context, options), do: @cms_implementation.delete_tags(entry, context, options, cms_base())
      def delete_tags!(entry, context, options), do: @cms_implementation.delete_tags!(entry, context, options, cms_base())

      def update_index(entry, context, options), do: @cms_implementation.update_index(entry, context, options, cms_base())
      def update_index!(entry, context, options), do: @cms_implementation.update_index!(entry, context, options, cms_base())

      def delete_index(entry, context, options), do: @cms_implementation.delete_index(entry, context, options, cms_base())
      def delete_index!(entry, context, options), do: @cms_implementation.delete_index!(entry, context, options, cms_base())

      #-------------------------
      # Versioning
      #-------------------------
      def initialize_versioning_records(entity, context, options \\ %{}), do: @cms_implementation.initialize_versioning_records(entity, context, options, cms_base())
      def populate_versioning_records(entity, context, options \\ %{}), do: @cms_implementation.populate_versioning_records(entity, context, options, cms_base())

      def make_active(entity, context, options \\ %{}), do: @cms_implementation.make_active(entity, context, options, cms_base())
      def make_active!(entity, context, options \\ %{}), do: @cms_implementation.make_active!(entity, context, options, cms_base())

      def get_active(entity, context, options \\ %{}), do: @cms_implementation.get_active(entity, context, options, cms_base())
      def get_active!(entity, context, options \\ %{}), do: @cms_implementation.get_active!(entity, context, options, cms_base())

      def update_active(entity, context, options \\ %{}), do: @cms_implementation.update_active(entity, context, options, cms_base())
      def update_active!(entity, context, options \\ %{}), do: @cms_implementation.update_active!(entity, context, options, cms_base())

      def remove_active(entity, context, options \\ %{}), do: @cms_implementation.remove_active(entity, context, options, cms_base())
      def remove_active!(entity, context, options \\ %{}), do: @cms_implementation.remove_active!(entity, context, options, cms_base())

      #def make_version_default(entity, context, options \\ %{}), do: @default_implementation.make_version_default(entity, context, options, cms_base())
      #def make_version_default!(entity, context, options \\ %{}), do: @default_implementation.make_version_default!(entity, context, options, cms_base())

      #def get_version_default(entity, context, options \\ %{}), do: @default_implementation.get_version_default(entity, context, options, cms_base())
      #def get_version_default!(entity, context, options \\ %{}), do: @default_implementation.get_version_default!(entity, context, options, cms_base())

      #def approve_revision(entity, context, options \\ %{}), do: @default_implementation.approve_revision(entity, context, options, cms_base())
      #def approve_revision!(entity, context, options \\ %{}), do: @default_implementation.approve_revision!(entity, context, options, cms_base())

      #def reject_revision(entity, context, options \\ %{}), do: @default_implementation.reject_revision(entity, context, options, cms_base())
      #def reject_revision!(entity, context, options \\ %{}), do: @default_implementation.reject_revision!(entity, context, options, cms_base())

      # @todo json marshalling logic (mix of protocol and scaffolding methods).
      # @todo setup permission system
      # @todo setup plug / controller routes

      def init_article_info(entity, context, options \\ %{}), do: @cms_implementation.init_article_info(entity, context, options, cms_base())
      def init_article_info!(entity, context, options \\ %{}), do: @cms_implementation.init_article_info!(entity, context, options, cms_base())

      def update_article_info(entity, context, options \\ %{}), do: @cms_implementation.update_article_info(entity, context, options, cms_base())
      def update_article_info!(entity, context, options \\ %{}), do: @cms_implementation.update_article_info!(entity, context, options, cms_base())

      def get_versions(entity, context, options \\ %{}), do: @cms_implementation.get_versions(entity, context, options, cms_base())
      def get_versions!(entity, context, options \\ %{}), do: @cms_implementation.get_versions!(entity, context, options, cms_base())

      def create_version(entity, context, options \\ %{}), do: @cms_implementation.create_version(entity, context, options, cms_base())
      def create_version!(entity, context, options \\ %{}), do: @cms_implementation.create_version!(entity, context, options, cms_base())

      def update_version(entity, context, options \\ %{}), do: @cms_implementation.update_version(entity, context, options, cms_base())
      def update_version!(entity, context, options \\ %{}), do: @cms_implementation.update_version!(entity, context, options, cms_base())

      def delete_version(entity, context, options \\ %{}), do: @cms_implementation.delete_version(entity, context, options, cms_base())
      def delete_version!(entity, context, options \\ %{}), do: @cms_implementation.delete_version!(entity, context, options, cms_base())

      def get_revisions(entity, context, options \\ %{}), do: @cms_implementation.get_revisions(entity, context, options, cms_base())
      def get_revisions!(entity, context, options \\ %{}), do: @cms_implementation.get_revisions!(entity, context, options, cms_base())


      def create_revision(entity, context, options \\ %{}), do: @cms_implementation.create_revision(entity, context, options, cms_base())
      def create_revision!(entity, context, options \\ %{}), do: @cms_implementation.create_revision!(entity, context, options, cms_base())

      def update_revision(entity, context, options \\ %{}), do: @cms_implementation.update_revision(entity, context, options, cms_base())
      def update_revision!(entity, context, options \\ %{}), do: @cms_implementation.update_revision!(entity, context, options, cms_base())

      def delete_revision(entity, context, options \\ %{}), do: @cms_implementation.delete_revision(entity, context, options, cms_base())
      def delete_revision!(entity, context, options \\ %{}), do: @cms_implementation.delete_revision!(entity, context, options, cms_base())


      def new_version(entity, context, options \\ %{}), do: @cms_implementation.new_version(entity, context, options, cms_base())
      def new_version!(entity, context, options \\ %{}), do: @cms_implementation.new_version!(entity, context, options, cms_base())

      def new_revision(entity, context, options \\ %{}), do: @cms_implementation.new_revision(entity, context, options, cms_base())
      def new_revision!(entity, context, options \\ %{}), do: @cms_implementation.new_revision!(entity, context, options, cms_base())


      defoverridable [
        expand_records: 3,
        expand_records!: 3,
        match_records: 3,
        match_records!: 3,
        filter_records: 3,
        get_by_status: 3,
        get_by_status!: 3,
        get_by_type: 3,
        get_by_type!: 3,
        get_by_module: 3,
        get_by_module!: 3,
        get_by_editor: 3,
        get_by_editor!: 3,
        get_by_tag: 3,
        get_by_tag!: 3,
        get_by_created_on: 4,
        get_by_created_on!: 4,
        get_by_modified_on: 4,
        get_by_modified_on!: 4,

        update_tags: 3,
        update_tags!: 3,

        delete_tags: 3,
        delete_tags!: 3,

        update_index: 3,
        update_index!: 3,

        delete_index: 3,
        delete_index!: 3,


        initialize_versioning_records: 2,
        initialize_versioning_records: 3,
        populate_versioning_records: 2,
        populate_versioning_records: 3,

        make_active: 2,
        make_active: 3,
        make_active!: 2,
        make_active!: 3,

        get_active: 2,
        get_active: 3,
        get_active!: 2,
        get_active!: 3,

        update_active: 2,
        update_active: 3,
        update_active!: 2,
        update_active!: 3,

        remove_active: 2,
        remove_active: 3,
        remove_active!: 2,
        remove_active!: 3,

        init_article_info: 2,
        init_article_info: 3,
        init_article_info!: 2,
        init_article_info!: 3,

        update_article_info: 2,
        update_article_info: 3,
        update_article_info!: 2,
        update_article_info!: 3,

        get_versions: 2,
        get_versions: 3,
        get_versions!: 2,
        get_versions!: 3,

        create_version: 2,
        create_version: 3,
        create_version!: 2,
        create_version!: 3,

        update_version: 2,
        update_version: 3,
        update_version!: 2,
        update_version!: 3,

        delete_version: 2,
        delete_version: 3,
        delete_version!: 2,
        delete_version!: 3,

        get_revisions: 2,
        get_revisions: 3,
        get_revisions!: 2,
        get_revisions!: 3,


        create_revision: 2,
        create_revision: 3,
        create_revision!: 2,
        create_revision!: 3,

        update_revision: 2,
        update_revision: 3,
        update_revision!: 2,
        update_revision!: 3,

        delete_revision: 2,
        delete_revision: 3,
        delete_revision!: 2,
        delete_revision!: 3,


        new_version: 2,
        new_version: 3,
        new_version!: 2,
        new_version!: 3,

        new_revision: 2,
        new_revision: 3,
        new_revision!: 2,
        new_revision!: 3,
      ]


    end
  end
end
