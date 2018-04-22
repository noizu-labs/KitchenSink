#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Proto.EmailBind do
  @fallback_to_any true
  @doc "Format bound paramater into expected string representation for passing to sendgrid."
  def format(reference)
end # end defprotocol

if (Application.get_env(:noizu_email_service, :protocols, true)) do
  defimpl Noizu.Proto.EmailBind, for: Any do
    def format(reference) do
      case Poison.encode(reference) do
        {:ok, json} -> json
        _ -> "#{inspect reference}"
      end
    end # end format/1
  end # end defimpl

  defimpl Noizu.Proto.EmailBind, for: [Atom, Integer, Float, BitString] do
    def format(reference) do
      case Poison.encode(reference) do
        {:ok, json} -> json
        _ -> "#{inspect reference}"
      end
    end # end format/1
  end # end defimpl

  defimpl Noizu.Proto.EmailBind, for: Tuple do
    def format(reference) do
      case reference do
        # 1. Convert internal reference structs into string format.
        {:ref, _m, _i} -> Noizu.ERP.sref(reference)
        {:ext_ref, _m, _i} -> Noizu.ERP.sref(reference)
        # 3. unknown tuples.
        _ ->
          case Poison.encode(reference) do
            {:ok, json} -> json
            _ -> "#{inspect reference}"
          end
      end
    end # end format/1
  end # end defimpl

  defimpl Noizu.Proto.EmailBind, for: List do
    def format(reference) do
      p = for entry <- reference do
        Noizu.Proto.EmailBind.format(entry)
      end
      case Poison.encode(p) do
        {:ok, json} -> json
        _ -> "#{inspect p}"
      end
    end # end format/1
  end # end defimpl

  defimpl Noizu.Proto.EmailBind, for: Noizu.SmartToken.TokenEntity do
    def format(reference) do
      case Noizu.SmartToken.TokenEntity.encoded_key(reference) do
        {:error, _details} -> "invalid_token"
        v -> v
      end
    end # end format/1
  end # end defimpl

end

