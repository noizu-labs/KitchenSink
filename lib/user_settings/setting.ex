#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.UserSettings.Setting do
  @type t :: %__MODULE__{
               setting: atom,
               stack: Map.t,
             }

  defstruct [
    setting: nil,
    stack: %{}
  ]

  #--------------------------------------------
  # pull/3
  #--------------------------------------------
  @doc """
    Return new Setting struct.
  """
  def new(setting, path, value, weight), do: %__MODULE__{setting: setting,  stack: %{path => [%{weight: weight, value: value}]}}

  #--------------------------------------------
  # insert/5
  #--------------------------------------------
  @doc """
    Insert a new entry at given path with specified weight.
  """
  def insert(this, setting, path, value, weight \\ :auto)
  def insert(nil, setting, path, value, weight ), do: new(setting, path, value, weight)
  def insert(%__MODULE__{} = this, _setting, path, value, weight), do: update_in(this, [Access.key(:stack), path], fn(entry) -> (entry || []) ++ [%{weight: weight, value: value}] end)

  #--------------------------------------------
  # effective/2
  #--------------------------------------------
  @doc """
    Determine effective setting given nesting path. Pull all entries at pull level or lower, order by weight and return
    the entry with the highest value.
  """
  def effective(nil, _path), do: {:error, :no_entry}
  def effective(%__MODULE__{} = this, path) do
    case pull(this, path) do
      [] -> {:error, :no_entry}
      stack when is_list(stack) -> (stack |> Enum.sort(&(&1.weight > &2.weight)) |> List.first()).value
    end
  end

  #--------------------------------------------
  # effective_for/2
  #--------------------------------------------
  @doc """
    Determine effective setting given nesting paths. Pull all entries at pull level or lower for all paths, order by weight and return
    the entry with the highest value.
  """
  def effective_for(nil, _paths), do: {:error, :no_entry}
  def effective_for(%__MODULE__{} = this, paths) do
    entries = Enum.map(paths, fn(path) -> pull(this, path) end) |> List.flatten()
    case entries do
      [] -> {:error, :no_entry}
      stack when is_list(stack) -> (stack |> Enum.sort(&(&1.weight > &2.weight)) |> List.first()).value
    end
  end


  #--------------------------------------------
  # pull/3
  #--------------------------------------------
  @doc """
    Grab all entries for a path and it's parents. [path, parent, parents_parent]
  """
  def pull(this, path, acc \\ [])
  def pull(%__MODULE__{} = this, [], acc), do: acc ++ (this.stack[[]] || [])
  def pull(%__MODULE__{} = this, [_h|t] = path, acc), do: pull(this, t, acc ++ (this.stack[path] || []))
end

#-----------------------------------------------------------------------------
# Inspect Protocol
#-----------------------------------------------------------------------------
defimpl Inspect, for: Noizu.UserSettings.Setting do
  import Inspect.Algebra

  def inspect(entity, opts) do
    cond do
      opts.limit == :infinity ->
        concat ["#Setting(", to_doc(entity.setting, opts), ")<", to_doc(entity.stack, opts), ">"]

      opts.limit >= 499 ->
        stack = Enum.reduce(entity.stack, %{}, fn({k, v}, acc) ->
          put_in(acc, [k], %{effective: Noizu.UserSettings.Setting.effective(entity, k), entries: length(v)})
        end)
        concat ["#Setting(", to_doc(entity.setting, opts), ")<", to_doc(stack, opts), ">"]

      opts.limit >= 99 ->
        stack = Enum.reduce(entity.stack, %{}, fn({k, v}, acc) ->
          put_in(acc, [k], length(v))
        end)
        concat ["#Setting(", to_doc(entity.setting, opts), ")<", to_doc(stack, opts), ">"]

      true ->
        stack = length(Map.keys(entity.stack))
        concat ["#Setting(", to_doc(entity.setting, opts), ")<", to_doc(stack, opts), ">"]
    end
  end
end  # end Inspect