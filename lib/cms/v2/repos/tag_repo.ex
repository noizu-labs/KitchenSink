#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.TagRepo do
  @behaviour Noizu.Cms.V2.Cms.TagRepoBehaviour

  alias Noizu.Cms.V2.Database.TagTable
  use Noizu.Cms.V2.Database.TagTable
  use Amnesia

  def new(options) do
      %TagTable{
        article: options[:article],
        tag: options[:tag]
      }
  end

  def mnesia_delete(identifier), do: TagTable.delete(identifier)
  def mnesia_delete!(identifier), do: TagTable.delete!(identifier)
  def mnesia_read(identifier), do: TagTable.read(identifier)
  def mnesia_read!(identifier), do: TagTable.read!(identifier)
  def mnesia_write(identifier), do: TagTable.write(identifier)
  def mnesia_write!(identifier), do: TagTable.write!(identifier)
  def mnesia_match(m), do: TagTable.match(m)
  def mnesia_match!(m), do: TagTable.match!(m)

end
