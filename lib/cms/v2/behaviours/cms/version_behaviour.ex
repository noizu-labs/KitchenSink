#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Cms.VersionBehaviour.Default do
  use Amnesia

  alias Noizu.ElixirCore.OptionSettings
  alias Noizu.ElixirCore.OptionValue
  #alias Noizu.ElixirCore.OptionList

  @revision_format ~r/^(.*)@([0-9a-zA-Z][0-9a-zA-Z\.]*)-([0-9a-zA-Z]+)$/
  @version_format ~r/^(.*)@([0-9a-zA-Z][0-9a-zA-Z\.]*)$/


  def prepare_options(options) do
    settings = %OptionSettings{
      option_settings: %{
        verbose: %OptionValue{option: :verbose, default: false},
      }
    }
    OptionSettings.expand(settings, options)
  end


  #------------------------------
  # string_to_id
  #------------------------------
  def string_to_id(nil, _caller), do: nil
  def string_to_id(identifier, caller) when is_bitstring(identifier) do
    case identifier do
      "ref." <> _ -> {:error, {:unsupported, identifier}}
      _ ->
        cond do
          Regex.match?(@revision_format, identifier) ->
            case Regex.run(@revision_format, identifier) do
              [_, identifier, version, revision] ->
                case caller.article_string_to_id(identifier) do
                  {:ok, i} ->
                    version_path = String.split(version, ".")
                                   |> Enum.map(
                                        fn(x) ->
                                          case Integer.parse(x) do
                                            {v, ""} -> v
                                            _ -> x
                                          end
                                        end)
                                   |> List.to_tuple()
                    revision = case Integer.parse(revision) do
                      {v, ""} -> v
                      _ -> revision
                    end
                    {:revision, {i, version_path, revision}}
                  _ -> {:error, {:unsupported, identifier}}
                end
              _ ->  {:error, {:unsupported, identifier}}
            end

          Regex.match?(@version_format, identifier) ->
            case Regex.run(@version_format, identifier) do
              [_, identifier, version] ->
                case caller.article_string_to_id(identifier) do
                  {:ok, i} ->
                    version_path = String.split(version, ".")
                                   |> Enum.map(
                                        fn(x) ->
                                          case Integer.parse(x) do
                                            {v, ""} -> v
                                            _ -> x
                                          end
                                        end)
                                   |> List.to_tuple()
                    {:version, {i, version_path}}
                  _ -> {:error, {:unsupported, identifier}}
                end
              _ ->  {:error, {:unsupported, identifier}}
            end

          true -> caller.article_string_to_id(identifier)
        end
    end
  end
  def string_to_id(i, _caller), do: {:error, {:unsupported, i}}

  #------------------------------
  # id_to_string
  #------------------------------
  def id_to_string(identifier, caller) do
    case identifier do
      nil -> nil
      {:revision, {i,v,r}} ->
        cond do
          i == nil -> {:error, {:unsupported, identifier}}
          !is_tuple(v) -> {:error, {:unsupported, identifier}}
          r == nil -> {:error, {:unsupported, identifier}}
          !(is_integer(r) || is_bitstring(r) || is_atom(r)) -> {:error, {:unsupported, identifier}}
          String.contains?("#{r}", ["-", "@"]) -> {:error, {:unsupported, identifier}}
          vp = caller.version_path_to_string(v) ->
            case caller.article_id_to_string(i) do
              {:ok, id} -> {:ok, "#{id}@#{vp}-#{r}"}
              _ -> {:error, {:unsupported, identifier}}
            end
          true -> {:error, {:unsupported, identifier}}
        end
      {:version, {i,v}} ->
        cond do
          i == nil -> {:error, {:unsupported, identifier}}
          !is_tuple(v) -> {:error, {:unsupported, identifier}}
          vp = caller.version_path_to_string(v) ->
            case caller.article_id_to_string(i) do
              {:ok, id} -> {:ok, "#{id}@#{vp}"}
              _ -> {:error, {:unsupported, identifier}}
            end
          true -> {:error, {:unsupported, identifier}}
        end
      _ -> caller.article_id_to_string(identifier)
    end
  end

  #------------------------------
  # version_path_to_string/2
  #------------------------------
  def version_path_to_string(version_path, _caller) do
    v_l = Tuple.to_list(version_path)
    v_err = Enum.any?(v_l, fn(x) ->
      cond do
        x == nil -> true
        !(is_bitstring(x) || is_integer(x) || is_atom(x)) -> true
        String.contains?("#{x}", [".", "-", "@"]) -> true
        true -> false
      end
    end)
    cond do
      length(v_l) == 0 -> nil
      v_err -> nil
      true -> Enum.map(v_l, &("#{&1}")) |> Enum.join(".")
    end
  end


  #------------------------------
  # article_string_to_id
  #------------------------------
  @doc """
    override this if your entity type uses string values, nested refs, etc. for it's identifier.
  """
  def article_string_to_id(nil, _caller), do: nil
  def article_string_to_id(identifier, _caller) when is_bitstring(identifier) do
    case identifier do
      "ref." <> _ -> {:error, {:unsupported, identifier}}
      _ ->
        case Integer.parse(identifier) do
          {id, ""} -> {:ok, id}
          v -> {:error, {:parse, v}}
        end
    end
  end
  def article_string_to_id(i, _caller), do: {:error, {:unsupported, i}}

  #------------------------------
  # article_id_to_string
  #------------------------------
  @doc """
    override this if your entity type uses string values, nested refs, etc. for it's identifier.
  """
  def article_id_to_string(identifier, _caller) do
    cond do
      is_integer(identifier) -> {:ok, "#{identifier}"}
      is_atom(identifier) -> {:ok, "#{identifier}"}
      is_bitstring(identifier) -> {:ok, "#{identifier}"}
      true -> {:error, {:unsupported, identifier}}
    end
  end

  #------------------------------
  # new/4
  #------------------------------
  def new(entity, context, options, caller) do
    options_a = put_in(options, [:active_revision], true)
    case caller.cms_version().create(entity, context, options_a) do
      {:ok, {version, revision}} ->
        version_ref = caller.cms_version_entity().ref(version)
        revision_ref = caller.cms_revision().ref(revision)
        options_b = put_in(options_a, [:nested_versioning], true)
        entity
        |> Noizu.Cms.V2.Proto.set_revision(revision_ref, context, options_b)
        |> Noizu.Cms.V2.Proto.set_version(version_ref, context, options_b)
        |> Noizu.Cms.V2.Proto.set_parent(version.parent, context, options_b)
        |> caller.update(context, options_a)
      {:error, e} -> throw {:error, {:creating_revision, e}}
      e -> throw {:error, {:creating_revision, {:unknown, e}}}
    end
  end

  #------------------------------
  #
  #------------------------------
  def new!(entity, context, options, caller) do
    Amnesia.Fragment.async(fn -> caller.cms_version().new(entity, context, options) end)
  end


  #------------------------------
  #
  #------------------------------
  def initialize(entity, context, options, caller) do
    options = put_in(options, [:active_revision], true)
    case caller.cms_version().create(entity, context, options) do
      {:ok, {version, revision}} ->
        entity = entity
                 |> Noizu.Cms.V2.Proto.set_version(caller.cms_version_entity().ref(version), context, options)
                 |> Noizu.Cms.V2.Proto.set_revision(caller.cms_revision().ref(revision), context, options)
                 |> Noizu.Cms.V2.Proto.set_parent(caller.cms_version_entity().ref(version.parent), context, options)
        v_id = Noizu.Cms.V2.Proto.versioned_identifier(entity, context, options)
        entity = entity
                 |> put_in([Access.key(:identifier)], v_id)

        caller.cms_tags().update(entity, context, options)
        caller.cms_index().update(entity, context, options)

        entity
      e -> throw "initialize_versioning_records error: #{inspect e}"
    end
  end

  #------------------------------
  #
  #------------------------------
  def populate(entity, context, options, caller) do
    if options[:nested_versioning] do
      entity
    else
      caller.cms_revision().populate(entity, context, options)
    end
  end

  #------------------------
  #
  #------------------------
  def versions(entity, context, options, caller) do
    article_ref = Noizu.Cms.V2.Proto.get_article(entity, context, options)
                  |> Noizu.ERP.ref()
    cond do
      article_ref ->
        caller.cms_version_repo().match([identifier: {article_ref, :_}], context, options)
      true -> {:error, :article_unknown}
    end
  end

  #------------------------------
  #
  #------------------------------
  def versions!(entity, context, options, caller) do
    Amnesia.Fragment.async(fn -> caller.cms_version().versions(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def create(entity, context, options, caller) do
    article = Noizu.Cms.V2.Proto.get_article(entity, context, options)
    article_ref =  Noizu.Cms.V2.Proto.article_ref(article, context, options)

    # 1. get current version.
    current_version = Noizu.Cms.V2.Proto.get_version(article, context, options)
    current_version_ref = caller.cms_version_entity().ref(current_version)

    # 2. Determine version path we will be creating
    new_version_path = cond do
      current_version == nil ->
        {caller.cms_version().version_sequencer({article_ref, {}})}
      true ->
        {:ref, _, {_article, path}} = current_version_ref
        List.to_tuple(Tuple.to_list(path) ++ [caller.cms_version().version_sequencer({article_ref, path})])
    end

    # 3. Create Version Stub
    new_version_key = {article_ref, new_version_path}
    # new_version_ref = VersionEntity.ref(new_version_key)

    article = article
              |> Noizu.Cms.V2.Proto.set_version(new_version_key, context, options)
              |> Noizu.Cms.V2.Proto.set_parent(current_version_ref, context, options)
              |> Noizu.Cms.V2.Proto.set_revision(nil, context, options)

    case caller.cms_revision().create(article, context, options) do
      {:ok, revision} ->
        # Create Version Record
        version = caller.cms_version_repo().new(
                    %{
                      identifier: new_version_key,
                      article: article_ref,
                      parent: current_version_ref,
                      created_on: revision.created_on,
                      modified_on: revision.modified_on,
                      editor: revision.editor,
                      status: revision.status,
                    }) |> caller.cms_version_repo().create(context, options)
        {:ok, {version, revision}}

      {:error, e} -> {:error, {:creating_revision, e}}
      e -> {:error, {:creating_revision, {:unknown, e}}}
    end
  end

  #------------------------------
  #
  #------------------------------
  def create!(entity, context, options, caller) do
    Amnesia.Fragment.async(fn -> caller.cms_version().create(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def update(entity, context, options, caller) do
    # 1. get current version.
    current_version = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                      |> caller.cms_version_entity().entity()

    cond do
      current_version == nil -> {:error, :invalid_version}
      true ->
        case caller.cms_revision().update(entity, context, options) do
          {:ok, revision} ->
            version = caller.cms_version_repo().change_set(current_version,
                        %{
                          modified_on: revision.modified_on,
                          editor: revision.editor,
                          status: revision.status,
                        }) |> caller.cms_version_repo().update(context, options)
            {:ok, {version, revision}}
          _ -> {:error, :update_revision}
        end
    end
  end

  #------------------------------
  #
  #------------------------------
  def update!(entity, context, options, caller) do
    Amnesia.Fragment.async(fn -> caller.cms_version().update(entity, context, options) end)
  end

  #------------------------
  #
  #------------------------
  def delete(entity, context, options, caller) do
    version_ref = Noizu.Cms.V2.Proto.get_version(entity, context, options)
                  |> Noizu.ERP.ref()

    # Active Revision Check
    if options[:bookkeeping] != :disabled do
      #if cms_provider = Noizu.Cms.V2.Proto.cms_provider(entity, context, options) do
      if active_revision = caller.cms_index().active_version(entity, context, options) do
        active_version = Noizu.Cms.V2.Proto.get_version(active_revision, context, options)
                         |> Noizu.ERP.ref()
        if (active_version && active_version == version_ref), do: throw :cannot_delete_active
      end
      #end
    end

    cond do
      version_ref ->
        # Get revisions,
        case caller.cms_revision().revisions(entity, context, options) do
          revisions when is_list(revisions) ->
            caller.cms_revision().delete_active(version_ref, context, options)

            # Delete Revisions
            Enum.map(revisions, fn(revision) ->
              caller.cms_revision().delete(revision, context, options)
            end)

            # Delete Version
            identifier = Noizu.ERP.id(version_ref)
            caller.cms_version_repo().delete(identifier, context, options)

            :ok
          _ -> {:error, :revision_lookup}
        end
      true -> {:error, :revision_not_set}
    end
  end

  #------------------------
  #
  #------------------------
  def delete!(entity, context, options, caller) do
    Amnesia.Fragment.async(fn -> caller.cms_version().delete(entity, context, options) end)
  end

  #===========================================================
  # Supporting
  #===========================================================

  #------------
  # ref
  #------------
  def ref({:version, {i, v}}, caller) do
    caller.cms_version_entity().ref({caller.entity_module().ref(i), v})
  end

  def ref(entity, caller), do: caller.cms_version_entity().ref(entity)
end


defmodule Noizu.Cms.V2.Cms.VersionBehaviour do



  defmacro __using__(opts) do
    cms_implementation = Keyword.get(opts || [], :implementation, Noizu.Cms.V2.Cms.VersionBehaviour.Default)
    cms_option_settings = cms_implementation.prepare_options(opts)
    quote do
      import unquote(__MODULE__)
      require Logger
      @cms_implementation unquote(cms_implementation)
      use Noizu.Cms.V2.SettingsBehaviour.InheritedSettings, unquote([option_settings: cms_option_settings])

      def new(entity, context, options \\ %{}), do: @cms_implementation.new(entity, context, options, cms_base())
      def new!(entity, context, options \\ %{}), do: @cms_implementation.new!(entity, context, options, cms_base())

      def initialize(entity, context, options \\ %{}), do: @cms_implementation.initialize(entity, context, options, cms_base())
      def populate(entity, context, options \\ %{}), do: @cms_implementation.populate(entity, context, options, cms_base())

      def versions(entity, context, options \\ %{}), do: @cms_implementation.versions(entity, context, options, cms_base())
      def versions!(entity, context, options \\ %{}), do: @cms_implementation.versions!(entity, context, options, cms_base())

      def create(entity, context, options \\ %{}), do: @cms_implementation.create(entity, context, options, cms_base())
      def create!(entity, context, options \\ %{}), do: @cms_implementation.create!(entity, context, options, cms_base())

      def update(entity, context, options \\ %{}), do: @cms_implementation.update(entity, context, options, cms_base())
      def update!(entity, context, options \\ %{}), do: @cms_implementation.update!(entity, context, options, cms_base())

      def delete(entity, context, options \\ %{}), do: @cms_implementation.delete(entity, context, options, cms_base())
      def delete!(entity, context, options \\ %{}), do: @cms_implementation.delete!(entity, context, options, cms_base())

      def ref(entity), do: @cms_implementation.ref(entity, cms_base())

      def version_sequencer(key), do: cms_version_sequencer().sequencer(key)
      def version_sequencer!(key), do: cms_version_sequencer().sequencer!(key)

      def version_path_to_string(version_path), do: @cms_implementation.version_path_to_string(version_path, cms_base())
      def string_to_id(identifier), do: @cms_implementation.string_to_id(identifier, cms_base())
      def id_to_string(identifier), do: @cms_implementation.id_to_string(identifier, cms_base())
      def article_string_to_id(identifier), do: @cms_implementation.article_string_to_id(identifier, cms_base())
      def article_id_to_string(identifier), do: @cms_implementation.article_id_to_string(identifier, cms_base())


      defoverridable [
        new: 2,
        new!: 2,

        new: 3,
        new!: 3,

        initialize: 2,
        initialize: 3,

        populate: 2,
        populate: 3,

        versions: 2,
        versions!: 2,

        versions: 3,
        versions!: 3,

        create: 2,
        create!: 2,

        create: 3,
        create!: 3,

        update: 2,
        update!: 2,

        update: 3,
        update!: 3,

        delete: 2,
        delete!: 2,

        delete: 3,
        delete!: 3,

        ref: 1,

        version_path_to_string: 1,
        string_to_id: 1,
        id_to_string: 1,
        article_string_to_id: 1,
        article_id_to_string: 1,

        version_sequencer: 1,
        version_sequencer!: 1,
      ]
    end
  end
end
