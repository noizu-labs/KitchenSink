#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2021 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Proto.DynamicBind do
  @fallback_to_any true
  @doc "Format bound parameter into expected string representation for passing to sendgrid."
  def bind_value(reference)
end # end defprotocol

defimpl Noizu.Proto.DynamicBind, for: Any do
  def bind_value(reference) do
    reference
  end # end format/1
end # end defimpl

defimpl Noizu.Proto.DynamicBind, for: Noizu.SmartToken.TokenEntity do
  def bind_value(reference) do
    case Noizu.SmartToken.TokenEntity.encoded_key(reference) do
      {:error, _details} -> "invalid_token"
      v -> v
    end
  end # end format/1
end # end defimpl