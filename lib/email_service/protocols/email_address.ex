defprotocol Noizu.Proto.EmailAddress do
  @fallback_to_any true
  @doc "Format bound paramater into expected string representation for passing to sendgrid."
  def email_details(reference)
end # end defprotocol

if (Application.get_env(:noizu_email_service, :protocols, true)) do
  defimpl Noizu.Proto.EmailAddress, for: Any do
    def email_details("ref." <> _mr = reference) do
      Noizu.Proto.EmailAddress.email_details(Noizu.ERP.entity!(reference))
    end
    def email_details({:ref, _m, _d} = reference) do
      Noizu.Proto.EmailAddress.email_details(Noizu.ERP.entity!(reference))
    end
    def email_details(%{ref: _ref, name: _name, email: _email} = reference) do
      reference
    end
    def email_details(nil) do
      nil
    end
    def email_details(reference) do
      {:error, {:unsupported, reference}}
    end
  end # end defimpl

  defimpl Noizu.Proto.EmailAddress, for: Noizu.KitchenSink.Support.UserEntity do
    def email_details(reference) do
      %{ref: Noizu.KitchenSink.Support.UserEntity.ref(reference), name: reference.name, email: reference.email}
    end
  end # end defimpl
end

