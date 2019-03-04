#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Article.Info do
  @vsn 1.0
  @type t :: %__MODULE__{
               article: tuple,
               created_on: DateTime.t,
               modified_on: DateTime.t,
               status: atom,
               type: atom,
               editor: any,
               name: String.t,
               description: Noizu.MarkdownField.t | nil,
               note: Noizu.MarkdownField.t | nil,
               version: any,
               parent_version: any,
               tags: MapSet.t,
               vsn: float
             }

  defstruct [
    article: nil,
    created_on: nil,
    modified_on: nil,
    status: nil,
    type: nil,
    editor: nil,
    name: nil,
    description: nil,
    note: nil,
    version: nil,
    parent_version: nil,
    tags: nil,
    vsn: @vsn
  ]

end # end defmodule