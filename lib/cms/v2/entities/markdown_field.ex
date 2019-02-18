#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.MarkdownField do
  @type t :: %__MODULE__{
               markdown: String.t,
               render: String.t | nil,
             }

  defstruct [
    markdown: nil,
    render: nil,
  ]

  def compress(%__MODULE__{} = entity), do: {:markdown, entity.markdown}
  def expand({:markdown, markdown}), do: %__MODULE__{markdown: markdown, render: nil}
  def render(%__MODULE__{} = entity, _restrictions) do
    # TODO render & tweak data structure.
    %__MODULE__{enity| render: entity.markdown}
  end

end # end defmodule Noizu.MarkdownField