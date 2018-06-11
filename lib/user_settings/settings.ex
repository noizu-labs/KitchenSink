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
  # insert/4
  #--------------------------------------------
  @doc """
    Insert new value for a setting at top level/global default.
  """
  def insert(%__MODULE__{} = this, setting, value, weight) do
    update_in(this, [Access.key(:settings), setting], &(Noizu.UserSettings.Setting.insert(&1, setting, [], value, weight)))
  end

  #--------------------------------------------
  # insert/5
  #--------------------------------------------
  @doc """
    Insert new value for a setting at a given path and weight.
  """
  def insert(%__MODULE__{} = this, setting, path, value, weight) do
    update_in(this, [Access.key(:settings), setting], &(Noizu.UserSettings.Setting.insert(&1, setting, path, value, weight)))
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