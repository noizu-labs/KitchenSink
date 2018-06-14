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
  # append/4
  #--------------------------------------------
  def append(%__MODULE__{} = a, nil, _path_prefix, _weight_offset), do: a
  def append(nil, %__MODULE__{} = b, path_prefix, weight_offset) do
    stack = if weight_offset != 0 do
      Enum.reduce(b.stack, %{}, fn({k,v}, acc) ->
        m_k = path_prefix ++ k
        m_e = Enum.map(v, fn(e) -> update_in(e, [:weight], &((&1 || 0) + weight_offset)) end)
        put_in(acc, [m_k], m_e)
      end)
    else
      Enum.reduce(b.stack, %{}, fn({k,v}, acc) ->
        m_k = path_prefix ++ k
        put_in(acc, [m_k], v)
      end)
    end
    %__MODULE__{setting: b.setting, stack: stack}
  end
  def append(%__MODULE__{} = a, %__MODULE__{} = b, path_prefix, weight_offset) do
    m_b = append(nil, b, path_prefix, weight_offset)
    merge(a, m_b)
  end

  #--------------------------------------------
  # merge/2
  #--------------------------------------------
  def merge(%__MODULE__{} = a, nil), do: a
  def merge(nil, %__MODULE__{} = b), do: b
  def merge(%__MODULE__{} = a, %__MODULE__{} = b) do
    stack = (Map.keys(a.stack) ++ Map.keys(b.stack))
            |> Enum.reduce(%{},
                 fn(path, acc) ->
                   put_in(acc, [path], ((a.stack[path] || []) ++ (b.stack[path] || [])))
                 end)
    %__MODULE__{a| stack: stack}
  end

  #--------------------------------------------
  # pull/3
  #--------------------------------------------
  @doc """
    Return new Setting struct.
  """
  def new(setting, value, path, weight), do: %__MODULE__{setting: setting,  stack: %{path => [%{weight: weight, value: value}]}}

  #--------------------------------------------
  # insert/5
  #--------------------------------------------
  @doc """
    Insert a new entry at given path with specified weight.
  """
  def insert(this, setting, value, path, weight \\ :auto)
  def insert(nil, setting, value, path, weight), do: new(setting, value, path, weight)
  def insert(%__MODULE__{} = this, _setting, value, path, weight), do: update_in(this, [Access.key(:stack), path], fn(entry) -> (entry || []) ++ [%{weight: weight, value: value}] end)

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