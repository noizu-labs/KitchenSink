#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Repo.DefaultProvider do

  defmacro __using__(options) do
    index_table = Keyword.get(options, :index_table, Noizu.Cms.V2.Database.IndexTable)
    version_table = Keyword.get(options, :version_table, Noizu.Cms.V2.Database.VersionTable)
    tag_table = Keyword.get(options, :tag_table, Noizu.Cms.V2.Database.TagTable)

    quote do

      use Amnesia
      alias unquote(index_table), as: IndexTable
      alias unquote(version_table), as: VersionTable
      alias unquote(tag_table), as: TagTable

      use IndexTable
      use VersionTable
      use TagTable

      @default_options %{
        expand: true,
        filter: false
      }

      #----------------------------------
      # default_options/0
      #----------------------------------
      def default_options(), do: @default_options

      #----------------------------------
      # cms_provider/1
      #----------------------------------
      def cms_provider(caller), do: caller.repo()

      #----------------------------------
      # expand_records/4
      #----------------------------------
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
      def match_records!(filter, context, options, caller), do: Amnesia.Fragment.async(fn -> caller.match_records(filter, context, options) end)

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
        |> caller.match_records(context, options)
        |> caller.expand_records(context, options)
      end

      #----------------------------------
      # get_by_status!/4
      #----------------------------------
      def get_by_status!(status, context, options, caller) do
        options = Map.merge(@default_options, options)
        [status: status]
        |> caller.match_records!(context, options)
        |> caller.expand_records!(context, options)
      end

      #----------------------------------
      # get_by_type/4
      #----------------------------------
      def get_by_type(type, context, options, caller) do
        options = Map.merge(@default_options, options)
        [type: type]
        |> caller.match_records(context, options)
        |> caller.expand_records(context, options)
      end

      #----------------------------------
      # get_by_type!/4
      #----------------------------------
      def get_by_type!(type, context, options, caller) do
        options = Map.merge(@default_options, options)
        [type: type]
        |> caller.match_records!(context, options)
        |> caller.expand_records!(context, options)
      end

      #----------------------------------
      # get_by_module/4
      #----------------------------------
      def get_by_module(module, context, options, caller) do
        options = Map.merge(@default_options, options)
        [module: module]
        |> caller.match_records(context, options)
        |> caller.expand_records(context, options)
      end

      #----------------------------------
      # get_by_module!/4
      #----------------------------------
      def get_by_module!(module, context, options, caller) do
        options = Map.merge(@default_options, options)
        [module: module]
        |> caller.match_records!(context, options)
        |> caller.expand_records!(context, options)
      end

      #----------------------------------
      # get_by_editor/4
      #----------------------------------
      def get_by_editor(editor, context, options, caller) do
        options = Map.merge(@default_options, options)
        [editor: editor]
        |> caller.match_records(context, options)
        |> caller.expand_records(context, options)
      end

      #----------------------------------
      # get_by_editor!/4
      #----------------------------------
      def get_by_editor!(editor, context, options, caller) do
        options = Map.merge(@default_options, options)
        [editor: editor]
        |> caller.match_records!(context, options)
        |> caller.expand_records!(context, options)
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
        |> caller.filter_records(context, options)
        |> caller.expand_records(context, options)
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
          |> caller.filter_records(context, options)
          |> caller.expand_records!(context, options)
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
        |> caller.expand_records(context, options)
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
        |> caller.expand_records!(context, options)
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
        |> caller.expand_records(context, options)
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
        |> caller.expand_records!(context, options)
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
            caller.update_tags(article, context, options)
            caller.update_index(article, context, options)
        end
        entity
      end

      #-----------------------------
      # make_active!/4
      #-----------------------------
      def make_active!(entity, context, options, caller) do
        Amnesia.Fragment.async(fn -> caller.make_active(entity, context, options) end)
      end

      #-----------------------------
      # update_active/4
      #-----------------------------
      def update_active(entity, context, options, caller) do
        article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
        article_ref = Noizu.ERP.ref(article)

        if article do
          active_revision = caller.get_active(article, context, options)
                            |> Noizu.ERP.ref()

          current_revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
                             |> Noizu.ERP.ref()

          if (active_revision && active_revision == current_revision) do
            # @note no data consistency check perform
            caller.update_tags(article, context, options)
            caller.update_index(article, context, options)
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
        Amnesia.Fragment.async(fn -> caller.update_active(entity, context, options) end)
      end

      #-----------------------------
      # remove_active/4
      #-----------------------------
      def remove_active(entity, context, options, caller) do
        article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
        article && caller.delete_index(article, context, options)
      end

      #-----------------------------
      # remove_active!/4
      #-----------------------------
      def remove_active!(entity, context, options, caller) do
        article = Noizu.Cms.V2.Proto.get_article!(entity, context, options)
        article && caller.delete_index!(article, context, options)
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
        Amnesia.Fragment.async(fn -> caller.init_article_info(entity, context, options) end)
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
        Amnesia.Fragment.async(fn -> caller.update_article_info(entity, context, options) end)
      end


      #-----------------------------
      # create/4
      #-----------------------------
      def create(entity, context, options, _caller) do
        try do
          # @todo conditional logic to insure only revision records persisted.
          module = entity.__struct__.repo()
          entity
          |> module.pre_create_callback(context, options)
          |> module.inner_create_callback(context, options)
          |> module.post_create_callback(context, options)
        rescue e -> {:error, e}
        catch e -> {:error, e}
        end
      end

      #-----------------------------
      # pre_create_callback/4
      #-----------------------------
      def pre_create_callback(entity, context, options, _caller) do
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
          |> cms_provider.populate_versioning_records(context, options_a)
        else
          # 5. Prepare Version and Revision, modify identifier.
          entity
          |> cms_provider.init_article_info(context, options)
          |> cms_provider.initialize_versioning_records(context, options_a)
        end
      end

      #-----------------------------
      # post_create_callback/4
      #-----------------------------
      def post_create_callback(entity, _context, _options, _caller) do
        entity
      end

      #-----------------------------
      # get/4
      #-----------------------------
      def get(identifier, context, options, caller) do
        try do
          # @todo, this belongs in the version provider, this module shouldn't know the versioning formats.
          identifier = case identifier do
            {:revision, {i, v, r}} -> identifier
            {:version, {i, v}} ->
              version_ref = Noizu.Cms.V2.VersionEntity.ref({caller.entity_module().ref(i), v})
              case Noizu.Cms.V2.Database.Version.ActiveRevisionTable.read(version_ref) do
                %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{revision: r} ->
                  case Noizu.Cms.V2.Version.RevisionEntity.id(r) do
                    {{:ref, Noizu.Cms.V2.VersionEntity, _}, revision} -> {:revision, {i, v, revision}}
                    _ -> nil
                  end
                _ -> nil
              end
            _ ->
              case IndexTable.read(caller.entity_module().ref(identifier)) do
                %IndexTable{active_version: av, active_revision: ar} ->
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
            caller.inner_get_callback(identifier, context, options)
            |> caller.post_get_callback(context, options)
          end
        rescue e -> {:error, e}
        catch e -> {:error, e}
        end

      end

      #-----------------------------
      # post_get_callback/4
      #-----------------------------
      def post_get_callback(entity, _context, _options, _caller) do
        entity
      end

      #-----------------------------
      # update/4
      #-----------------------------
      def update(entity, context, options, _caller) do
        try do
          module = entity.__struct__.repo()
          entity
          |>  module.pre_update_callback(context, options)
          |>  module.inner_update_callback(context, options)
          |>  module.post_update_callback(context, options)
        rescue e -> {:error, e}
        catch e -> {:error, e}
        end
      end

      #-----------------------------
      # pre_update_callback/4
      #-----------------------------
      def pre_update_callback(entity, context, options, _caller) do
        if (entity.identifier == nil), do: throw "Identifier not set"
        if (!Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)), do: throw "#{entity.__struct__} entities may only be persisted using cms revision ids"

        options_a = put_in(options, [:nested_update], true)
        cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options)

        entity
        |> cms_provider.update_article_info(context, options)
        |> cms_provider.populate_versioning_records(context, options_a)
      end

      #-----------------------------
      # post_update_callback/4
      #-----------------------------
      def post_update_callback(entity, _context, _options, _caller) do
        entity
      end

      #-----------------------------
      # delete/4
      #-----------------------------
      def delete(entity, context, options, _caller) do
        # @todo conditional logic to insure only revision records persisted.
        try do
          module = entity.__struct__.repo()
          entity
          |>  module.pre_delete_callback(context, options)
          |>  module.inner_delete_callback(context, options)
          |>  module.post_delete_callback(context, options)
          true
        rescue e -> {:error, e}
        catch e -> {:error, e}
        end
      end

      #-----------------------------
      # pre_delete_callback/4
      #-----------------------------
      def pre_delete_callback(entity, context, options, _caller) do
        if entity.identifier == nil, do: throw :identifier_not_set
        # Active Revision Check
        if options[:bookkeeping] != :disabled do
          if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
            # @todo this module should not have such specific knowledge of versioning formats.
            # setup an active version check in version provider.
            article_revision = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
                               |> Noizu.Cms.V2.Version.RevisionEntity.ref()

            if article_revision do
              if article_revision == cms_provider.get_active(entity, context, options) do
                throw :active_version
              end

              case article_revision do
                {:ref, _, {article_version, _revision}} ->
                  case Noizu.Cms.V2.Database.Version.ActiveRevisionTable.read(article_version) do
                    %Noizu.Cms.V2.Database.Version.ActiveRevisionTable{revision: active_revision} ->
                      if active_revision == article_revision, do: throw :active_revision
                    _ -> nil
                  end
                _ -> nil
              end
            end
          end
        end
        entity
      end

      #-----------------------------
      # post_delete_callback/4
      #-----------------------------
      def post_delete_callback(entity, _context, _options, _caller) do
        entity
      end



      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        default_options: 0,
        cms_provider: 1,
        expand_records: 4,
        expand_records!: 4,
        match_records: 4,
        match_records!: 4,
        filter_records: 4,
        get_by_status: 4,
        get_by_status!: 4,
        get_by_type: 4,
        get_by_type!: 4,
        get_by_module: 4,
        get_by_module!: 4,
        get_by_editor: 4,
        get_by_editor!: 4,
        get_by_tag: 4,
        get_by_tag!: 4,
        get_by_created_on: 5,
        get_by_created_on!: 5,
        get_by_modified_on: 5,
        get_by_modified_on!: 5,
        update_tags: 4,
        update_tags!: 4,
        delete_tags: 4,
        delete_tags!: 4,
        update_index: 4,
        update_index!: 4,
        delete_index: 4,
        delete_index!: 4,
        make_active: 4,
        make_active!: 4,
        update_active: 4,
        update_active!: 4,
        remove_active: 4,
        remove_active!: 4,
        get_active: 4,
        get_active!: 4,
        init_article_info: 4,
        init_article_info!: 4,
        update_article_info: 4,
        update_article_info!: 4,
        create: 4,
        pre_create_callback: 4,
        post_create_callback: 4,
        get: 4,
        post_get_callback: 4,
        update: 4,
        pre_update_callback: 4,
        post_update_callback: 4,
        delete: 4,
        pre_delete_callback: 4,
        post_delete_callback: 4,
      ]

    end
  end
end
