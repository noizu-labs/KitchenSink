#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.Post.VersionEntity do
  @vsn 1.0

  @type t :: %__MODULE__{
               identifier: integer,
               post: tuple,
               version: integer,
               created_on: DateTime.t,
               modified_on: DateTime.t,
               editor: any,
               status: atom,
               name: String.t,
               description: String.t,
               note: String.t | atom,
               tags: MapSet.t,
               record: any,
               vsn: float
             }

  defstruct [
    identifier: nil,
    post: nil,
    version: nil,
    created_on: nil,
    modified_on: nil,
    editor: nil,
    status: :pending,
    name: nil,
    description: nil,
    note: nil,
    tags: MapSet.new([]),
    record: nil,
    vsn: @vsn
  ]

  use Noizu.Cms.Database
  use Noizu.Scaffolding.EntityBehaviour,
      sref_module: "cms-version",
      mnesia_table: Noizu.Cms.Database.Post.VersionTable,
      as_record_options: %{additional_fields: [:post, :version, :created_on, :editor]},
      override: []

end # end defmodule SolaceBackend.Cms.PostEntity