defprotocol Noizu.Proto.EmailAddress do
  @fallback_to_any true
  @doc "Format bound paramater into expected string representation for passing to sendgrid."
  def email_details(reference)
end # end defprotocol

if (Application.get_env(:noizu_email_service, :protocols, true)) do
  defimpl Noizu.Proto.EmailAddress, for: Any do
    def email_details(%{ref: ref, name: name, email: email} = reference) do
      reference
    end # end format/1

    def email_details(reference) do
      {:error, {:unsupported, reference}}
    end # end format/1
  end # end defimpl


  defimpl Noizu.Proto.EmailAddress, for: Noizu.KitchenSink.Support.UserEntity do
    def email_details(reference) do
      %{ref: Noizu.KitchenSink.Support.UserEntity.ref(reference), name: reference.name, email: reference.email}
    end # end format/1
  end # end defimpl
end

