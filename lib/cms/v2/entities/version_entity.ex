#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersionEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: tuple,
               article: Noizu.KitchenSink.Types.entity_reference,
               parent: Noizu.KitchenSink.Types.entity_reference,
               created_on: DateTime.t,
               modified_on: DateTime.t,
               editor: Noizu.KitchenSink.Types.entity_reference,
               status: any,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    article: nil,
    parent: nil,
    created_on: nil,
    modified_on: nil,
    editor: nil,
    status: nil,
    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "cms-version-v2",
      mnesia_table: Noizu.Cms.V2.Database.VersionTable,
      as_record_options: %{
        additional_fields: [:editor, :status,  :created_on, :modified_on]
      }

  #------------
  #
  #------------
  def id(nil), do: nil
  def id({:ref, __MODULE__, identifier} = _ref), do: identifier
  def id(%{__struct__: __MODULE__, identifier: identifier}), do: identifier
  def id(%{entity: %{__struct__: __MODULE__, identifier: identifier}}), do: identifier
  def id({{:ref, _article_type, _article_id}, version_path} = ref) when is_tuple(version_path), do: ref
  def id("ref.cms-version-v2." <> ref), do: id(ref)
  def id(ref) when is_bitstring(ref) do
    case string_to_id(ref) do
      {:ok, v} -> v
      {:error, _} -> nil
      v -> v
    end
  end
  def id(_ref), do: nil

  #------------
  #
  #------------
  def string_to_id("ref.cms-version-v2." <> identifier), do: string_to_id(identifier)
  def string_to_id(identifier) do
    case Regex.run(~r/^\[(.*)\]@([0-9\.]*)$/, identifier) do
      [_,sref,version] ->
        if ref = Noizu.ERP.ref(sref) do
          version = String.split(version, ".") |> Enum.map(&(elem(Integer.parse(&1), 0))) |> List.to_tuple()
          {ref, version}
        else
          {:error, {:inner_ref, sref, identifier}}
        end
      _ -> {:error, {:format, identifier}}
    end
  end

  #------------
  #
  #------------
  def id_to_string({{:ref, _m, _i} = ref, path}) do
    sref = Noizu.ERP.sref(ref)
    path = Tuple.to_list(path) |> Enum.join(".")
    {:ok, "[#{sref}]@#{path}"}
  end

  def id_to_string(ref) do
    {:error, ref}
  end

  def is_cms_entity?(_, _context, _options), do: false
  def is_cms_entity!(_, _context, _options), do: false

  def is_versioning_record?(_, _context, _options), do: true
  def is_versioning_record!(_, _context, _options), do: true

  def is_revision_record?(_, _context, _options), do: false
  def is_revision_record!(_, _context, _options), do: false

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule


#=====================================================
#
#=====================================================
defimpl Noizu.Cms.V2.Proto, for: [Noizu.Cms.V2.VersionEntity] do
  #----------------------
  #
  #----------------------
  def tags(ref, _context, _options), do: ref.article_info.tags
  def tags!(ref, _context, _options), do: ref.article_info.tags

  #----------------------
  #
  #----------------------
  def type(ref, _context, _options), do: ref.article_info.type
  def type!(ref, _context, _options), do: ref.article_info.type

  #----------------------
  #
  #----------------------
  def is_cms_entity?(_ref, _context, _options), do: false
  def is_cms_entity!(_ref, _context, _options), do: false

  #----------------------
  #
  #----------------------
  def is_versioning_record?(_ref, _context, _options), do: true
  def is_versioning_record!(_ref, _context, _options), do: true

  #----------------------
  #
  #----------------------
  def is_revision_record?(_ref, _context, _options), do: false
  def is_revision_record!(_ref, _context, _options), do: false

  #----------------------
  #
  #----------------------
  def versioned_identifier(_ref, _context, _options), do: throw :not_supported
  def versioned_identifier!(_ref, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def update_article_identifier(_ref, _context, _options), do: throw :not_supported
  def update_article_identifier!(_ref, _context, _options), do: throw :not_supported


  #----------------------
  #
  #----------------------
  def article_identifier(_ref, _context, _options), do: throw :not_supported
  def article_identifier!(_ref, _context, _options), do: throw :not_supported

  def versioned_ref(_ref, _context, _options), do: throw :not_supported
  def versioned_ref!(_ref, _context, _options), do: throw :not_supported

  def article_ref(_ref, _context, _options), do: throw :not_supported
  def article_ref!(_ref, _context, _options), do: throw :not_supported
  #----------------------
  #
  #----------------------
  def compress_archive(ref, context, options) do
    # obtain revision, and call compress on it.
    if entity = Noizu.ERP.entity(ref.revision) do
      Noizu.Cms.V2.Proto.compress_archive(entity, context, options)
    end
  end

  def compress_archive!(ref, context, options) do
    # obtain revision, and call compress on it.
    if entity = Noizu.ERP.entity!(ref.revision) do
      Noizu.Cms.V2.Proto.compress_archive!(entity, context, options)
    end
  end

  #----------------------
  #
  #----------------------
  def get_article(ref, _context, _options), do: ref.article
  def get_article!(ref, _context, _options), do: ref.article

  #----------------------
  #
  #----------------------
  def set_version(_ref, _version, _context, _options), do: throw :not_supported
  def set_version!(_ref, _version, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_version(ref, _context, _options), do: ref
  def get_version!(ref, _context, _options), do: ref

  #----------------------
  #
  #----------------------
  def set_revision(_ref, _revision, _context, _options), do: throw :not_supported
  def set_revision!(_ref, _revision, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_revision(ref, _context, _options), do: ref.revision
  def get_revision!(ref, _context, _options), do: ref.revision

  #----------------------
  #
  #----------------------
  def set_parent(_ref, _version, _context, _options), do: throw :not_supported
  def set_parent!(_ref, _version, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def get_parent(ref, _context, _options), do: ref.parent
  def get_parent!(ref, _context, _options), do: ref.parent

  #----------------------
  #
  #----------------------
  def get_article_info(_ref, _context, _options), do: throw :not_supported
  def get_article_info!(_ref, _context, _options), do: throw :not_supported


  #--------------------------------
  # @init_article_info
  #--------------------------------
  def init_article_info(_ref, _context, _options), do: throw :not_supported
  def init_article_info!(_ref, _context, _options), do: throw :not_supported

  #--------------------------------
  # @update_article_info
  #--------------------------------
  def update_article_info(_ref, _context, _options), do: throw :not_supported
  def update_article_info!(_ref, _context, _options), do: throw :not_supported

  #----------------------
  #
  #----------------------
  def set_article_info(_ref, _article_info, _context, _options), do: throw :not_supported
  def set_article_info!(_ref, _article_info, _context, _options), do: throw :not_supported
end
