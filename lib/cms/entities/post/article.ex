#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.Post.Article do
  @type t :: %__MODULE__{
               title: String.t,
               body: String.t,
             }

  defstruct [
    title: nil,
    body: nil,
  ]
end # end defmodule