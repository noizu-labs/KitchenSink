#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2022 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defimpl Poison.Encoder, for: [
                          Noizu.EmailService.Email.Binding.Substitution.Dynamic.Section,
                          Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen,
                          Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.Each
] do
  def encode(value, options) do
      value = put_in(Map.from_struct(value), [:kind], value.__struct__)
      Poison.Encoder.encode(value, options)
  end
end