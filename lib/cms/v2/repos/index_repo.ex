#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.IndexRepo do
  @behaviour Noizu.Cms.V2.Cms.IndexRepoBehaviour
  alias Noizu.Cms.V2.Database.IndexTable
  use Noizu.Cms.V2.Database.IndexTable
  use Amnesia

  def new(options) do
    %IndexTable{
      article: options[:article],
      status: options[:status],
      module: options[:module],
      type: options[:type],
      editor: options[:editor],
      created_on: options[:created_on],
      modified_on: options[:modified_on],
      active_version: options[:active_version],
      active_revision: options[:active_revision],
    }
  end

  def change_set(entity, options) do
    Enum.reduce(options, entity, fn({k, v}, acc) ->
      put_in(acc, [Access.key(k)], v)
    end)
  end

  def update_active(entity, context, options, caller) do
    caller.cms_index().update_index_record(entity, context, options)
  end

  def update_active!(entity, context, options, caller) do
    caller.cms_index().update_index_record!(entity, context, options)
  end

  def mnesia_delete(identifier), do: IndexTable.delete(identifier)
  def mnesia_delete!(identifier), do: IndexTable.delete!(identifier)
  def mnesia_read(identifier), do: IndexTable.read(identifier)
  def mnesia_read!(identifier), do: IndexTable.read!(identifier)
  def mnesia_write(identifier), do: IndexTable.write(identifier)
  def mnesia_write!(identifier), do: IndexTable.write!(identifier)
  def mnesia_match(m), do: IndexTable.match(m)
  def mnesia_match!(m), do: IndexTable.match!(m)

  #----------------------------------
  # by_created_on/5
  #----------------------------------
  def by_created_on(from, to, _context, options) do
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    cond do
      Kernel.match?({:type, _}, options.filter) ->
        t = elem(options.filter, 1)
        IndexTable.where(type == t and created_on >= from_ts and created_on < to_ts)
      Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
        m = elem(options.filter, 1)
        IndexTable.where(module == m and created_on >= from_ts and created_on < to_ts)
      true -> IndexTable.where(created_on >= from_ts and created_on < to_ts)
    end
    |> Amnesia.Selection.values
  end

  #----------------------------------
  # by_created_on!/4
  #-----------------------5----------
  def by_created_on!(from, to, _context, options) do
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    Amnesia.Fragment.async(fn ->
      cond do
        Kernel.match?({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          IndexTable.where(type == t and created_on >= from_ts and created_on < to_ts)
        Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
          m = elem(options.filter, 1)
          IndexTable.where(module == m and created_on >= from_ts and created_on < to_ts)
        true -> IndexTable.where(created_on >= from_ts and created_on < to_ts)
      end
      |> Amnesia.Selection.values
    end)
  end

  #----------------------------------
  # by_modified_on/5
  #----------------------------------
  def by_modified_on(from, to, _context, options) do
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    cond do
      Kernel.match?({:type, _}, options.filter) ->
        t = elem(options.filter, 1)
        IndexTable.where(type == t and modified_on >= from_ts and modified_on < to_ts)
      Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
        m = elem(options.filter, 1)
        IndexTable.where(module == m and modified_on >= from_ts and modified_on < to_ts)
      true -> IndexTable.where(modified_on >= from_ts and modified_on < to_ts)
    end
    |> Amnesia.Selection.values
  end

  #----------------------------------
  # by_modified_on!/5
  #----------------------------------
  def by_modified_on!(from, to, _context, options) do
    from_ts = is_integer(from) && from || DateTime.to_unix(from)
    to_ts = is_integer(to) && to || DateTime.to_unix(to)
    Amnesia.Fragment.async(fn ->
      cond do
        Kernel.match?({:type, _}, options.filter) ->
          t = elem(options.filter, 1)
          IndexTable.where(type == t and modified_on >= from_ts and modified_on < to_ts)
        Kernel.match?({:module, _}, options.filter) || options.filter && is_atom(options.filter) ->
          m = elem(options.filter, 1)
          IndexTable.where(module == m and modified_on >= from_ts and modified_on < to_ts)
        true -> IndexTable.where(modified_on >= from_ts and modified_on < to_ts)
      end
      |> Amnesia.Selection.values
    end)
  end

end
