#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.TagRepo do
  alias Noizu.Cms.V2.Database.TagTable
  use Noizu.Cms.V2.Database.TagTable
  use Amnesia

  def new(options) do
      %TagTable{
        article: options[:article],
        tag: options[:tag]
      }
  end

  def delete(identifier), do: TagTable.delete(identifier)
  def delete!(identifier), do: TagTable.delete!(identifier)
  def read(identifier), do: TagTable.read(identifier)
  def read!(identifier), do: TagTable.read!(identifier)
  def write(e), do: TagTable.write(e)
  def write!(e), do: TagTable.write!(e)

end
