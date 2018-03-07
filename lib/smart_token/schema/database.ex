#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia
defdatabase Noizu.SmartToken.Database do
  #-----------------------------------------------------------------------------
  # @SmartTokens
  #-----------------------------------------------------------------------------
  deftable TokenTable, [:identifier, :active, :token, :entity], type: :set, index: [:active, :token]  do
    @moduledoc """
    Smart Tokens
    """
    @type t :: %TokenTable{
                 identifier: integer,
                 active: true,
                 token: {String.t, String.t},
                 entity: any,
               }
  end # end deftable SmartTokens
end