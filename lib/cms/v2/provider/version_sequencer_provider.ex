#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersionSequencerProvider do



  use Amnesia

  def sequencer!(key) do
    Amnesia.async(fn -> sequencer(key) end)
  end

  #----------------------------------
  # sequencer/2
  #----------------------------------
  def sequencer(key) do
    case Noizu.Cms.V2.Database.VersionSequencerTable.read(key) do
      v = %Noizu.Cms.V2.Database.VersionSequencerTable{} ->
        %Noizu.Cms.V2.Database.VersionSequencerTable{v| sequence: v.sequence + 1}
        |> Noizu.Cms.V2.Database.VersionSequencerTable.write()
        v.sequence + 1
      nil ->
        %Noizu.Cms.V2.Database.VersionSequencerTable{identifier: key, sequence: 1}
        |> Noizu.Cms.V2.Database.VersionSequencerTable.write()
        1
    end
  end

end
