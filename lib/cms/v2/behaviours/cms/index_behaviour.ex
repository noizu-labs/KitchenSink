#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Cms.IndexBehaviour do
  defmodule Default do
    @moduledoc """
      Our default implementation just queries index tables. Alternative versions may query manticore/sphinx, etc. or other sources.
    """

    use Amnesia

    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    alias Noizu.Cms.V2.Database.IndexTable
    use Noizu.Cms.V2.Database.IndexTable

    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
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



    #-----------------------------------
    # Versioning Related Methods
    #-----------------------------------


    def active(ref, context, options, caller) do
      index = caller.cms_index_repo().read(ref)
      revision = index && Noizu.Cms.V2.Proto.get_revision(index, context, options)
      cond do
        revision -> caller.cms_revision_entity().id(revision)
        true -> nil
      end
    end

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
          caller.cms_tags().update(article, context, options)
          caller.cms_index().update(article, context, options)
      end
      entity
    end

    #-----------------------------
    # make_active!/4
    #-----------------------------
    def make_active!(entity, context, options, caller) do
      Amnesia.Fragment.async(fn -> caller.cms_index().make_active(entity, context, options) end)
    end

    #-----------------------------
    # update_active/4
    #-----------------------------
    def update_active(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
      #article_ref = Noizu.ERP.ref(article)

      if article do
        active_revision = caller.cms_index().get_active(article, context, options)
                          |> Noizu.ERP.ref()

        current_revision = Noizu.Cms.V2.Proto.get_revision(article, context, options)
                           |> Noizu.ERP.ref()

        if (active_revision && active_revision == current_revision) do
          # @note no data consistency check perform
          caller.cms_tags().update(article, context, options)
          caller.cms_index().update(article, context, options)
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
      Amnesia.Fragment.async(fn -> caller.cms_index().update_active(entity, context, options) end)
    end

    #-----------------------------
    # remove_active/4
    #-----------------------------
    def remove_active(entity, context, options, caller) do
      article = Noizu.Cms.V2.Proto.get_article(entity, context, options)

      # Delete Active version entry
      version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                    |> Noizu.ERP.ref()
      caller.cms_revision().delete_active(version_ref, context, options)

      article && caller.cms_index().delete(article, context, options)
    end

    #-----------------------------
    # remove_active!/4
    #-----------------------------
    def remove_active!(entity, context, options, caller) do
      Amnesia.async(fn -> caller.cms_index().remove_active(entity, context, options) end)
    end

    #-----------------------------
    # get_active/4
    #-----------------------------
    def get_active(entity, context, options, caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      case caller.cms_index_repo().read(ref) do
        %{active_revision: r} -> r
        _ -> nil
      end
    end

    #-----------------------------
    # get_active!/4
    #-----------------------------
    def get_active!(entity, context, options, caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      case caller.cms_index_repo().read!(ref) do
        %{active_revision: r} -> r
        _ -> nil
      end
    end

    #----------------------------------
    # match_records/4
    #----------------------------------
    # @TODO submodule CMS.Index
    def match_records(filter, _context, options, caller) do
      case options.filter do
        {:type, t} -> [type: t] ++ filter # Unexpected behaviour if filter is [type: t2]
        {:module, m} -> [module: m] ++ filter
        m when is_atom(m) -> [module: m] ++ filter
        _ -> filter
      end
      |> Enum.uniq()
      |> caller.cms_index_repo().match()
      |> Amnesia.Selection.values
    end


    #----------------------------------
    # match_records!/4
    #----------------------------------
    def match_records!(filter, context, options, caller), do: Amnesia.Fragment.async(fn -> caller.cms_index().match_records(filter, context, options) end)

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
    # query_by
    #----------------------------------
    def query_by(field, value, context, options, caller) do
      [{field, value}]
      |> caller.cms_index().match_records(context, options)
      |> caller.cms_index().expand_records(context, options)
    end

    #----------------------------------
    # query_by!
    #----------------------------------
    def query_by!(field, value, context, options, caller) do
      [{field, value}]
      |> caller.cms_index().match_records!(context, options)
      |> caller.cms_index().expand_records!(context, options)
    end


    #----------------------------------
    # filter_set
    #----------------------------------
    def filter_set(articles, context, options, caller) do
      articles
      |> Enum.map(&(IndexTable.read(&1)))
      |> caller.cms_index().filter_records(context, options)
      |> caller.cms_index().expand_records(context, options)
    end

    #----------------------------------
    # filter_set!
    #----------------------------------
    def filter_set!(articles, context, options, caller) do
      articles
      |> Enum.map(&(IndexTable.read!(&1)))
      |> caller.cms_index().filter_records(context, options)
      |> caller.cms_index().expand_records!(context, options)
    end

    #----------------------------------
    # by_created_on/5
    #----------------------------------
    def by_created_on(from, to, context, options, caller) do
      caller.cms_index_repo().by_created_on(from, to, context, options)
      |> caller.cms_index().expand_records(context, options)
    end

    #----------------------------------
    # by_created_on!/4
    #-----------------------5----------
    def by_created_on!(from, to, context, options, caller) do
      caller.cms_index_repo().by_created_on!(from, to, context, options)
      |> caller.cms_index().expand_records!(context, options)
    end

    #----------------------------------
    # by_modified_on/5
    #----------------------------------
    def by_modified_on(from, to, context, options, caller) do
      caller.cms_index_repo().by_modified_on(from, to, context, options)
      |> caller.cms_index().expand_records(context, options)
    end

    #----------------------------------
    # by_modified_on!/5
    #----------------------------------
    def by_modified_on!(from, to, context, options, caller) do
      caller.cms_index_repo().by_modified_on!(from, to, context, options)
      |> caller.cms_index().expand_records!(context, options)
    end

    #-----------------------------
    # update/4
    #-----------------------------
    def update(entry, context, options, caller) do
      entity = Noizu.ERP.entity(entry)
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info(entity, context, options)
      cond do
        article_info.version == nil -> {:error, :version_not_set}
        article_info.revision == nil -> {:error, :revision_not_set}
        true ->
          case caller.cms_index_repo().read(ref) do
            index = %{} ->
              caller.cms_index_repo().change_set(index,
                %{
                  status: article_info.status,
                  module: article_info.module,
                  type: article_info.type,
                  editor: article_info.editor,
                  modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
                  active_version: article_info.version,
                  active_revision: article_info.revision,
                }) |> caller.cms_index_repo().write()

            _ ->
          caller.cms_index_repo().new(%{
                article: article_info.article,
                status: article_info.status,
                module: article_info.module,
                type: article_info.type,
                editor: article_info.editor,
                created_on: article_info.created_on && DateTime.to_unix(article_info.created_on),
                modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
                active_version: article_info.version,
                active_revision: article_info.revision,
              }) |> caller.cms_index_repo().write()
          end
      end
    end

    #-----------------------------
    # update!/4
    #-----------------------------
    def update!(entry, context, options, caller) do
      entity = Noizu.ERP.entity!(entry)
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      article_info = Noizu.Cms.V2.Proto.get_article_info!(entity, context, options)
      cond do
        article_info.version == nil -> {:error, :version_not_set}
        article_info.revision == nil -> {:error, :revision_not_set}
        true ->
          case caller.cms_index_repo().read!(ref) do
            index = %{} ->
              caller.cms_index_repo().change_set(index,
                %{
                  status: article_info.status,
                  module: article_info.module,
                  type: article_info.type,
                  editor: article_info.editor,
                  modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
                  active_version: article_info.version,
                  active_revision: article_info.revision,
                }) |> caller.cms_index_repo().write!()

            _ ->
              caller.cms_index_repo().new(%{
                article: article_info.article,
                status: article_info.status,
                module: article_info.module,
                type: article_info.type,
                editor: article_info.editor,
                created_on: article_info.created_on && DateTime.to_unix(article_info.created_on),
                modified_on: article_info.modified_on && DateTime.to_unix(article_info.modified_on),
                active_version: article_info.version,
                active_revision: article_info.revision,
              }) |> caller.cms_index_repo().write!()
          end
      end
    end

    #-----------------------------
    # delete/4
    #-----------------------------
    def delete(entity, context, options, caller) do
      ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
      caller.cms_index_repo().delete(ref)
    end

    #-----------------------------
    # delete!/4
    #-----------------------------
    def delete!(entity, context, options, caller) do
      ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
      caller.cms_index_repo().delete!(ref)
    end

  end



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.Cms.IndexBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)
    # cms_options = cms_option_settings.effective_options

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])



      def make_active(entity, context, options \\ %{}), do: @cms_implementation.make_active(entity, context, options, cms_base())
      def make_active!(entity, context, options \\ %{}), do: @cms_implementation.make_active!(entity, context, options, cms_base())

      def get_active(entity, context, options \\ %{}), do: @cms_implementation.get_active(entity, context, options, cms_base())
      def get_active!(entity, context, options \\ %{}), do: @cms_implementation.get_active!(entity, context, options, cms_base())

      def update_active(entity, context, options \\ %{}), do: @cms_implementation.update_active(entity, context, options, cms_base())
      def update_active!(entity, context, options \\ %{}), do: @cms_implementation.update_active!(entity, context, options, cms_base())

      def remove_active(entity, context, options \\ %{}), do: @cms_implementation.remove_active(entity, context, options, cms_base())
      def remove_active!(entity, context, options \\ %{}), do: @cms_implementation.remove_active!(entity, context, options, cms_base())

      #-------------------------
      # Query
      #-------------------------
      def expand_records(records, context, options \\ %{}), do: @cms_implementation.expand_records(records, context, options, cms_base())
      def expand_records!(records, context, options \\ %{}), do: @cms_implementation.expand_records!(records, context, options, cms_base())
      def match_records(filter, context, options \\ %{}), do: @cms_implementation.match_records(filter, context, options, cms_base())
      def match_records!(filter, context, options \\ %{}), do: @cms_implementation.match_records!(filter, context, options, cms_base())
      def filter_records(records, context, options \\ %{}), do: @cms_implementation.filter_records(records, context, options, cms_base())
      def query_by(field, value, context, options \\ %{}), do: @cms_implementation.query_by(field, value, context, options, cms_base())
      def query_by!(field, value, context, options \\ %{}), do: @cms_implementation.query_by!(field, value, context, options, cms_base())
      def filter_set(articles, context, options \\ %{}), do: @cms_implementation.filter_set(articles, context, options, cms_base())
      def filter_set!(articles, context, options \\ %{}), do: @cms_implementation.filter_set!(articles, context, options, cms_base())
      def by_created_on(from, to, context, options \\ %{}), do: @cms_implementation.by_created_on(from, to, context, options, cms_base())
      def by_created_on!(from, to, context, options \\ %{}), do: @cms_implementation.by_created_on!(from, to, context, options, cms_base())
      def by_modified_on(from, to, context, options \\ %{}), do: @cms_implementation.by_modified_on(from, to, context, options, cms_base())
      def by_modified_on!(from, to, context, options \\ %{}), do: @cms_implementation.by_modified_on!(from, to, context, options, cms_base())
      def update(entity, context, options \\ %{}), do: @cms_implementation.update(entity, context, options, cms_base())
      def update!(entity, context, options \\ %{}), do: @cms_implementation.update!(entity, context, options, cms_base())
      def delete(entity, context, options \\ %{}), do: @cms_implementation.delete(entity, context, options, cms_base())
      def delete!(entity, context, options \\ %{}), do: @cms_implementation.delete!(entity, context, options, cms_base())


      defoverridable [
        expand_records: 2,
        expand_records: 3,

        expand_records!: 2,
        expand_records!: 3,


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

        match_records: 2,
        match_records: 3,

        match_records!: 2,
        match_records!: 3,

        filter_records: 2,
        filter_records: 3,

        query_by: 3,
        query_by: 4,

        query_by!: 3,
        query_by!: 4,

        filter_set: 2,
        filter_set: 3,

        filter_set!: 2,
        filter_set!: 3,

        by_created_on: 3,
        by_created_on: 4,

        by_created_on!: 3,
        by_created_on!: 4,

        by_modified_on: 3,
        by_modified_on: 4,

        by_modified_on!: 3,
        by_modified_on!: 4,

        update: 2,
        update: 3,

        update!: 2,
        update!: 3,

        delete: 2,
        delete: 3,

        delete!: 2,
        delete!: 3,
      ]
    end
  end
end
