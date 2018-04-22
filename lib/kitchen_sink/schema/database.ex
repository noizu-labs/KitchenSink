#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.KitchenSink.Database do
  #-----------------------------------------------------------------------------
  # @Support.UserTable
  #-----------------------------------------------------------------------------
  deftable Support.UserTable, [:identifier, :entity], type: :set, index: [] do
    @moduledoc """
    Test User Table
    """
    @type t :: %__MODULE__{identifier: integer, entity: any}
  end # end deftable
end