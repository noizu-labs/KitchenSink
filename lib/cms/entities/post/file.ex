#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.Post.File do
  @type t :: %__MODULE__{
               title: String.t,
               alt: String.t,
               file: String.t,
               attributes: Map.t,
             }

  defstruct [
    title: nil,
    alt: nil,
    file: nil,
    attributes: %{},
  ]
end # end defmodule