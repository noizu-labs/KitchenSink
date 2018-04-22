defprotocol Noizu.Proto.EmailAddress do
  @fallback_to_any true
  @doc "Format bound paramater into expected string representation for passing to sendgrid."
  def email_details(reference)
end # end defprotocol

if (Application.get_env(:noizu_email_service, :protocols, true)) do
  defimpl Noizu.Proto.EmailAddress, for: Any do
    def email_details(reference) do
      {:error, {:unsupported, reference}}
    end # end format/1
  end # end defimpl
end

