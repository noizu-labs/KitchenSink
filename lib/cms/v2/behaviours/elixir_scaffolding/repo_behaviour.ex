#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.RepoBehaviour do
  defmodule Default do
    use Amnesia

    alias Noizu.Cms.V2.Database.IndexTable
    #alias Noizu.Cms.V2.Database.VersionTable
    #alias Noizu.Cms.V2.Database.TagTable

    use Noizu.Cms.V2.Database.IndexTable
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
        |> caller.inner_create_callback(context, options)
        |> caller.post_create_callback(context, options)
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # pre_create_callback/4
    #-----------------------------
    def pre_create_callback(entity, context, options, caller) do
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
          {:revision, {_i, _v, _r}} -> identifier
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
    def update(entity, context, options, caller) do
      try do
        entity
        |>  caller.pre_update_callback(context, options)
        |>  caller.inner_update_callback(context, options)
        |>  caller.post_update_callback(context, options)
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # pre_update_callback/4
    #-----------------------------
    def pre_update_callback(entity, context, options, caller) do
      if (entity.identifier == nil), do: throw "Identifier not set"
      if (!Noizu.Cms.V2.Proto.is_versioning_record?(entity, context, options)), do: throw "#{entity.__struct__} entities may only be persisted using cms revision ids"

      options_a = put_in(options, [:nested_update], true)

      entity
      |> caller.cms().update_article_info(context, options)
      |> caller.cms_version().populate(context, options_a)
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
    def delete(entity, context, options, caller) do
      # @todo conditional logic to insure only revision records persisted.
      try do
        entity
        |>  caller.pre_delete_callback(context, options)
        |>  caller.inner_delete_callback(context, options)
        |>  caller.post_delete_callback(context, options)
        true
      rescue e -> {:error, e}
      catch e -> {:error, e}
      end
    end

    #-----------------------------
    # pre_delete_callback/4
    #-----------------------------
    def pre_delete_callback(entity, context, options, caller) do
      if entity.identifier == nil, do: throw :identifier_not_set
      # Active Revision Check
      if options[:bookkeeping] != :disabled do

        # @todo this module should not have such specific knowledge of versioning formats.
        # setup an active version check in version provider.
        article_revision = Noizu.Cms.V2.Proto.get_revision(entity, context, options)
                           |> Noizu.Cms.V2.Version.RevisionEntity.ref()

        if article_revision do
          if article_revision == caller.cms_index().get_active(entity, context, options) do
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
      entity
    end

    #-----------------------------
    # post_delete_callback/4
    #-----------------------------
    def post_delete_callback(entity, _context, _options, _caller) do
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

      #----------------------------------
      # Repo Overrides
      #----------------------------------
      def create(entity, context, options \\ %{}), do: @cms_implementation.create(entity, context, options, cms_base())
      def pre_create_callback(entity, context, options \\ %{}), do: @cms_implementation.pre_create_callback(entity, context, options, cms_base())
      def post_create_callback(entity, context, options \\ %{}), do: @cms_implementation.post_create_callback(entity, context, options, cms_base())

      def get(entity, context, options \\ %{}), do: @cms_implementation.get(entity, context, options, cms_base())
      def post_get_callback(entity, context, options \\ %{}), do: @cms_implementation.post_get_callback(entity, context, options, cms_base())

      def update(entity, context, options \\ %{}), do: @cms_implementation.update(entity, context, options, cms_base())
      def pre_update_callback(entity, context, options \\ %{}), do: @cms_implementation.pre_update_callback(entity, context, options, cms_base())
      def post_update_callback(entity, context, options \\ %{}), do: @cms_implementation.post_update_callback(entity, context, options, cms_base())

      def delete(entity, context, options \\ %{}), do: @cms_implementation.delete(entity, context, options, cms_base())
      def pre_delete_callback(entity, context, options \\ %{}), do: @cms_implementation.pre_delete_callback(entity, context, options, cms_base())
      def post_delete_callback(entity, context, options \\ %{}), do: @cms_implementation.post_delete_callback(entity, context, options, cms_base())

      defoverridable [
        #------------------
        # Repo Behaviour
        #------------------
        create: 2,
        create: 3,

        pre_create_callback: 2,
        pre_create_callback: 3,

        post_create_callback: 2,
        post_create_callback: 3,

        get: 2,
        get: 3,

        post_get_callback: 2,
        post_get_callback: 3,

        update: 2,
        update: 3,

        pre_update_callback: 2,
        pre_update_callback: 3,

        post_update_callback: 2,
        post_update_callback: 3,

        delete: 2,
        delete: 3,

        pre_delete_callback: 2,
        pre_delete_callback: 3,

        post_delete_callback: 2,
        post_delete_callback: 3,
      ]
    end
  end
end
