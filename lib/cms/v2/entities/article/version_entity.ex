#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Article.VersionEntity do
  @vsn 1.0

  @type t :: %__MODULE__{
               identifier: integer,

               created_on: DateTime.t,
               modified_on: DateTime.t,

               editor: any,
               status: any,

               name: String.t | nil,
               description: Noizu.MarkdownField.t | nil,
               note: Noizu.MarkdownField.t | nil,

               handler: module,
               record: Map.t | any,

               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    created_on: DateTime.t,
    modified_on: DateTime.t,

    editor: nil,
    status: nil,

    name: nil,
    description: nil,
    note: nil,

    handler: nil,
    record: nil,

    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Cms.V2.Database
  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "cms-v2-version",
      mnesia_table: Noizu.Cms.V2.Database.Article.VersionTable

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end # end defmodule SolaceBackend.Cms.PostEntity