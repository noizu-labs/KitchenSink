#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.RepoBehaviour do
  defmodule Default do
    use Amnesia


    #alias Noizu.Cms.V2.Database.VersionTable
    #alias Noizu.Cms.V2.Database.TagTable


    use Noizu.Cms.V2.Database.VersionTable
    use Noizu.Cms.V2.Database.TagTable


    alias Noizu.ElixirCore.OptionSettings
    alias Noizu.ElixirCore.OptionValue
    #alias Noizu.ElixirCore.OptionList

    def prepare_options(options) do
      settings = %OptionSettings{
        option_settings: %{
          verbose: %OptionValue{option: :verbose, default: false},
          cms_module: %OptionValue{option: :cms_module, default: Noizu.Cms.V2.CmsBehaviour},
          cms_module_options: %OptionValue{option: :cms_module_options, default: []},
          tag_repo: %OptionValue{option: :tag_repo, default: Noizu.Cms.V2.TagRepo},
          index_repo: %OptionValue{option: :index_repo, default: Noizu.Cms.V2.IndexRepo},
          version_entity: %OptionValue{option: :version_entity, default: Noizu.Cms.V2.VersionEntity},
          version_repo: %OptionValue{option: :version_repo, default: Noizu.Cms.V2.VersionRepo},
          revision_entity: %OptionValue{option: :revision_entity, default: Noizu.Cms.V2.Version.RevisionEntity},
          revision_repo: %OptionValue{option: :revision_repo, default: Noizu.Cms.V2.Version.RevisionRepo},
          # Tag Provider
          # Index Provider
          # Version Provider
        }
      }
      OptionSettings.expand(settings, options)
    end

    #------------------
    # Repo Overrides
    #------------------

    #-----------------------------
    # create/4
    #-----------------------------
    def create(entity, context, options, caller) do
      try do
        # @todo conditional logic to insure only revision records persisted.
        entity
        |> caller.pre_create_callback(context, options)
        |> caller.cms_pre_create_callback(context, options)
        |> caller.inner_create_callback(context, options)
        |> caller.cms_post_create_callback(context, options)
        |> caller.post_create_callback(context, options)
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # cms_pre_create_callback/4
    #-----------------------------
    def cms_pre_create_callback(entity, context, options, caller) do
      is_versioning_record? = Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)
      options_a = put_in(options, [:nested_create], true)

      # AutoGenerate Identifier if not set, check for already existing record.
      entity = cond do
        #1. AutoIncrement
        entity.identifier == nil -> %{entity| identifier: caller.generate_identifier()}

        #2. Recursion Check
        options[:nested_create] -> entity

        #3. Check for existing records.
        true ->
          # @todo if !is_version_record? we should specifically scan for any matching revisions.
          if caller.get(entity.identifier, Noizu.ElixirCore.CallingContext.system(context), options_a) do
            throw "[Create Exception] Record Exists: #{Noizu.ERP.sref(entity)}"
          else
            entity
          end
      end

      if is_versioning_record? do
        entity
        |> caller.cms().update_article_info(context, options)
        |> caller.cms_version().populate(context, options_a)
      else
        # 5. Prepare Version and Revision, modify identifier.
        entity
        |> caller.cms().init_article_info(context, options)
        |> caller.cms_version().initialize(context, options_a)
      end
    end

    #-----------------------------
    # post_create_callback/4
    #-----------------------------
    def cms_post_create_callback(entity, _context, _options, _caller) do
      entity
    end


    def revision_to_id(revision, caller) do
      case caller.cms_revision_entity().id(revision) do
        {{:ref, _version_entity, {{:ref, _entity, id}, version_path}}, revision_id} -> {:revision, {id, version_path, revision_id}}
        _ -> nil
      end
    end

    #-----------------------------
    # get/4
    #-----------------------------
    def get(identifier, context, options, caller) do
      try do
        identifier = cond do
          Kernel.match?({:revision, {_id, _version_path, _revision_id}}, identifier) ->
            identifier
          Kernel.match?({:version, {_id, _version_path}}, identifier) ->
            {:version, {id, version_path}} = identifier
            version = caller.cms_version_entity().ref({caller.entity_module().ref(id), version_path})
            active_revision = caller.cms_revision_repo().active(version, context, options)
            caller.revision_to_id(active_revision)
          true ->
            ref = caller.entity_module().ref(identifier)
            active_revision = caller.cms_index().get_active(ref, context, options)
            caller.revision_to_id(active_revision)
        end

        if identifier do
          caller.inner_get_callback(identifier, context, options)
          |> caller.cms_post_get_callback(context, options)
          |> caller.post_get_callback(context, options)
        end
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # cms_post_get_callback/4
    #-----------------------------
    def cms_post_get_callback(entity, _context, _options, _caller) do
      entity
    end

    #-----------------------------
    # update/4
    #-----------------------------
    def update(entity, context, options, caller) do
      try do
        entity
        |>  caller.pre_update_callback(context, options)
        |>  caller.cms_pre_update_callback(context, options)
        |>  caller.inner_update_callback(context, options)
        |>  caller.cms_post_update_callback(context, options)
        |>  caller.post_update_callback(context, options)
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # cms_pre_update_callback/4
    #-----------------------------
    def cms_pre_update_callback(entity, context, options, caller) do
      if (entity.identifier == nil), do: throw "Identifier not set"
      if (!Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)), do: throw "#{entity.__struct__} entities may only be persisted using cms revision ids"

      options_a = put_in(options, [:nested_update], true)

      entity
      |> caller.cms().update_article_info(context, options)
      |> caller.cms_version().populate(context, options_a)
    end

    #-----------------------------
    # cms_post_update_callback/4
    #-----------------------------
    def cms_post_update_callback(entity, _context, _options, _caller) do
      entity
    end

    #-----------------------------
    # delete/4
    #-----------------------------
    def delete(entity, context, options, caller) do
      # @todo conditional logic to insure only revision records persisted.
      try do
        entity
        |>  caller.pre_delete_callback(context, options)
        |>  caller.cms_pre_delete_callback(context, options)
        |>  caller.inner_delete_callback(context, options)
        |>  caller.cms_post_delete_callback(context, options)
        |>  caller.post_delete_callback(context, options)
        true
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # cms_pre_delete_callback/4
    #-----------------------------
    def cms_pre_delete_callback(entity, context, options, caller) do
      if entity.identifier == nil, do: throw(:identifier_not_set)
      # Active Revision Check
      if options[:bookkeeping] != :disabled do
        # @todo this module should not have such specific knowledge of versioning formats.
        # setup an active version check in version provider.
        article_revision = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
                           |> caller.cms_revision_entity().ref()

        if article_revision do
          if article_revision == caller.cms_index().get_active(entity, context, options) do
            throw :active_version
          end

          case article_revision do
            {:ref, _, {article_version, _revision}} ->
              active_revision = caller.cms_revision_repo().active(article_version, context, options)
              if (active_revision == article_revision), do: throw(:active_revision), else: entity
            _ -> entity
          end
        end
      else
        entity
      end
    end

    #-----------------------------
    # cms_post_delete_callback/4
    #-----------------------------
    def cms_post_delete_callback(entity, _context, _options, _caller) do
      entity
    end
  end

  defmacro __using__(options) do
    cms_implementation = Keyword.get(options || [], :implementation, Noizu.Cms.V2.RepoBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(options)
    cms_options = cms_option_settings.effective_options
    cms_module = cms_options.cms_module

    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.RepoSettings, unquote([option_settings: cms_option_settings])

      if (unquote(cms_module)) do
        defmodule CMS do
          use unquote(cms_module), unquote(cms_options.cms_module_options)
        end
      end

      def version_path_to_string(version_path), do: cms_version().version_path_to_string(version_path)
      def string_to_id(identifier), do: cms_version().string_to_id(identifier)
      def id_to_string(identifier), do: cms_version().id_to_string(identifier)
      def article_string_to_id(identifier), do: cms_version().article_string_to_id(identifier)
      def article_id_to_string(identifier), do: cms_version().article_id_to_string(identifier)

      #----------------------------------
      # Repo Overrides
      #----------------------------------
      def create(entity, context, options \\ %{}), do: @cms_implementation.create(entity, context, options, cms_base())
      def cms_pre_create_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_pre_create_callback(entity, context, options, cms_base())
      def cms_post_create_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_post_create_callback(entity, context, options, cms_base())

      def get(entity, context, options \\ %{}), do: @cms_implementation.get(entity, context, options, cms_base())
      def cms_post_get_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_post_get_callback(entity, context, options, cms_base())

      def update(entity, context, options \\ %{}), do: @cms_implementation.update(entity, context, options, cms_base())
      def cms_pre_update_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_pre_update_callback(entity, context, options, cms_base())
      def cms_post_update_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_post_update_callback(entity, context, options, cms_base())

      def delete(entity, context, options \\ %{}), do: @cms_implementation.delete(entity, context, options, cms_base())
      def cms_pre_delete_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_pre_delete_callback(entity, context, options, cms_base())
      def cms_post_delete_callback(entity, context, options \\ %{}), do: @cms_implementation.cms_post_delete_callback(entity, context, options, cms_base())

      def revision_to_id(ref), do: @cms_implementation.revision_to_id(ref, cms_base())

      defoverridable [

        #------------------
        # Transplanted entity behavior methods.
        #------------------
        version_path_to_string: 1,
        string_to_id: 1,
        id_to_string: 1,
        article_string_to_id: 1,
        article_id_to_string: 1,

        #------------------
        # Repo Behaviour
        #------------------
        create: 2,
        create: 3,

        cms_pre_create_callback: 2,
        cms_pre_create_callback: 3,

        cms_post_create_callback: 2,
        cms_post_create_callback: 3,

        get: 2,
        get: 3,

        cms_post_get_callback: 2,
        cms_post_get_callback: 3,

        update: 2,
        update: 3,

        cms_pre_update_callback: 2,
        cms_pre_update_callback: 3,

        cms_post_update_callback: 2,
        cms_post_update_callback: 3,

        delete: 2,
        delete: 3,

        cms_pre_delete_callback: 2,
        cms_pre_delete_callback: 3,

        cms_post_delete_callback: 2,
        cms_post_delete_callback: 3,
      ]
    end
  end
end
