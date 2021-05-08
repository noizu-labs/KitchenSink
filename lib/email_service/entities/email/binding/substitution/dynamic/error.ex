#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------


defmodule Noizu.EmailService.Email.Binding.Substitution.Dynamic.Error do
  @vsn 1.0

  @type t :: %__MODULE__{
               error: any,
               token: any,
               vsn: float,
             }

  defstruct [
    error: nil,
    token: nil,
    vsn: @vsn
  ]
end
