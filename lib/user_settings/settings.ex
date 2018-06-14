#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.UserSettings.Settings do
  @type t :: %__MODULE__{
               settings: Map.t,
             }

  defstruct [
    settings: %{}
  ]

  #--------------------------------------------
  # append/4
  #--------------------------------------------
  def append(a, b, path_prefix \\ [], weight_offset \\ 0)
  def append(%__MODULE__{} = a, nil, _path_prefix, _weight_offset), do: a
  def append(nil, %__MODULE__{} = b, _path_prefix, _weight_offset), do: b
  def append(%__MODULE__{} = a, %__MODULE__{} = b, path_prefix, weight_offset) do
    Enum.reduce(Map.keys(a.settings) ++ Map.keys(b.settings), a,
      fn(setting, acc) ->
        put_in(acc, [Access.key(:settings), setting], Noizu.UserSettings.Setting.append(a.settings[setting], b.settings[setting], path_prefix, weight_offset))
      end)
  end

  #--------------------------------------------
  # merge/2
  #--------------------------------------------
  def merge(%__MODULE__{} = a, nil), do: a
  def merge(nil, %__MODULE__{} = b), do: b
  def merge(%__MODULE__{} = a, %__MODULE__{} = b) do
    Enum.reduce(Map.keys(a.settings) ++ Map.keys(b.settings), a,
      fn(setting, acc) ->
        put_in(acc, [Access.key(:settings), setting], Noizu.UserSettings.Setting.merge(a.settings[setting], b.settings[setting]))
      end)
  end

  #--------------------------------------------
  # insert/4
  #--------------------------------------------
  @doc """
    Insert new value for a setting at top level/global default.
  """
  def insert(%__MODULE__{} = this, setting, value, weight) do
    update_in(this, [Access.key(:settings), setting], &(Noizu.UserSettings.Setting.insert(&1, setting, value, [], weight)))
  end

  #--------------------------------------------
  # insert/5
  #--------------------------------------------
  @doc """
    Insert new value for a setting at a given path and weight.
  """
  def insert(%__MODULE__{} = this, setting, value, path, weight) do
    update_in(this, [Access.key(:settings), setting], &(Noizu.UserSettings.Setting.insert(&1, setting, value, path, weight)))
  end

  #--------------------------------------------
  # effective/2
  #--------------------------------------------
  @doc """
    Determine the effective global setting
  """
  def effective(%__MODULE__{} = this, setting) do
    Noizu.UserSettings.Setting.effective(this.settings[setting], [])
  end

  #--------------------------------------------
  # effective/3
  #--------------------------------------------
  @doc """
    Determine the effective setting at the given path.
    This will return the entry at the given path or it's parents [top, parent, parents_parent] with
    the highest weight.
  """
  def effective(%__MODULE__{} = this, setting, path) do
    Noizu.UserSettings.Setting.effective(this.settings[setting], path)
  end

  #--------------------------------------------
  # effective_for/3
  #--------------------------------------------
  @doc """
    Determine the effective global setting
  """
  def effective_for(%__MODULE__{} = this, setting, paths) do
    Noizu.UserSettings.Setting.effective_for(this.settings[setting], paths)
  end

end

#-----------------------------------------------------------------------------
# Inspect Protocol
#-----------------------------------------------------------------------------
defimpl Inspect, for: Noizu.UserSettings.Settings do
  import Inspect.Algebra

  def inspect(entity, opts) do
    settings = Map.values(entity.settings)
    concat ["#Settings<", to_doc(settings, opts), ">"]
  end
end  # end Inspect