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

  def article_tags(entity, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    _existing_tags = case caller.cms_tag_repo().mnesia_read(ref) do
      v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
      nil -> []
      v -> {:error, v}
    end
  end
  def article_tags!(entity, context, options, caller) do
    ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    _existing_tags = case caller.cms_tag_repo().mnesia_read!(ref) do
      v when is_list(v) -> Enum.map(v, &(&1.tag)) |> Enum.uniq() |> Enum.sort()
      nil -> []
      v -> {:error, v}
    end
  end

  def update_article_tags(entity, tags, context, options, caller) do
    caller.cms_tags().save_tags(entity, tags, context, options)
  end
  def update_article_tags!(entity, tags, context, options, caller) do
    caller.cms_tags().save_tags!(entity, tags, context, options)
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
