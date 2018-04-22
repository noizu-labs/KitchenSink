#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.Post.Article do
  @type t :: %__MODULE__{
               title: String.t,
               body: String.t,
               attributes: Map.t,
             }

  defstruct [
    title: nil,
    body: nil,
    attributes: %{},
  ]
end # end defmodule