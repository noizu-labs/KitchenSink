defprotocol Noizu.Proto.EmailAddress do
  @fallback_to_any true
  @doc "Format bound paramater into expected string representation for passing to sendgrid."
  def email_details(reference)
end # end defprotocol
