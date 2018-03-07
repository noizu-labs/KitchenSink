#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.SendGrid.TransactionalEmail do
  alias Noizu.KitchenSink.Types, as: T
  alias Noizu.EmailService.Email.Binding
  alias Noizu.EmailService.Email.TemplateEntity
  alias Noizu.EmailService.Email.QueueRepo
  require Logger

  @vsn 1.00

  @type t :: %__MODULE__{
               template: T.entity_reference,
               recipient: T.entity_reference,
               recipient_email: :default | String.t,
               sender: :nil | T.entity_reference | any,

               body: String.t,
               subject: String.t,

               bindings: Map.t,
               attachments: Map.t,
               vsn: float
             }

  defstruct [
    template: nil,
    recipient: nil,
    recipient_email: :default,
    sender: nil,
    body: nil,
    subject: nil,
    bindings: %{},
    attachments: %{},
    vsn: @vsn
  ]

  #--------------------------
  # send!/1
  #--------------------------
  @doc """
  @TODO cleanup implementation get rid of nested case statements.
  """
  def send!(%__MODULE__{} = this, context) do
    template = Noizu.ERP.entity!(this.template) |> TemplateEntity.refresh!(context)
    case template do
      {:error, details} ->
        #QueueRepo.audit!(this, {:fetch, {:error, details}})
        Logger.error("extract template error: #{inspect details}")
        {:error, details}
      %TemplateEntity{} ->
        case Binding.bind_from_template(this, template, context) do
          {{:error, details}, %Binding{} = binding} ->
            QueueRepo.queue_failed!(binding, {:error, details}, context) #Todo save more information on bind failure.
            {:error, details}
          {:ok, %Binding{} = binding} ->
            queued_email = QueueRepo.queue!(binding, context)
            spawn(fn -> send_email!(queued_email, context) end)
            queued_email
        end # end case
    end # end case
  end # end send!/1

  #--------------------------
  # send_email!/2
  #--------------------------
  def send_email!(queued_email, context) do
    cond do
      simulate?() -> QueueRepo.update_state(queued_email, :delivered, context)
      restricted?(queued_email.binding.recipient_email) -> QueueRepo.update_state(queued_email, :restricted, context)
      true ->
        case queued_email.binding.template.external_template_identifier do
          {:sendgrid, sendgrid_template_id} ->
            email = build_email(sendgrid_template_id, queued_email.binding)
            case SendGrid.Mailer.send(email) do
              :ok -> QueueRepo.update_state!(queued_email, :delivered, context)
                :ok
              error ->
                QueueRepo.update_state!(queued_email, :retrying, context)
                #QueueRepo.audit!(queued_email, {:sengrid_error, error}, context)
                Logger.error("Mail Send Error: #{inspect error}")
                error
            end # end case Mailer.send
        end # end case template_record.template.external_template_identifier do
    end
  end # end send_email/3

  #--------------------------
  # build_email/2
  #--------------------------
  defp build_email(sendgrid_template_id, binding) do
    Logger.info "
    --------------------------------------
     Bindings: #{inspect binding, pretty: true, limit: :infinity}
    --------------------------------------
    "
    # Setup email
    email = SendGrid.Email.build()
    |> SendGrid.Email.put_template(sendgrid_template_id)
    |> SendGrid.Email.add_to(binding.recipient_email)
    |> SendGrid.Email.put_from(binding.sender_email)
    |> put_html(binding)
    |> put_subject(binding)
    |> put_substitions(binding)
    |> put_attachments(binding)

  end # end build_email/2

  #--------------------------
  # put_attachments
  #--------------------------
  def put_attachments(email, binding) do
    cond do
      is_map(binding.attachments) -> Enum.reduce(binding.attachments, email, fn({name, v}, acc) ->
        cond do
          is_function(v, 0) ->
            case v.() do
              {:ok, attachment} -> SendGrid.Email.add_attachment(email, attachment)
              _ -> email
            end

          is_function(v, 2) ->
            case v.(name, binding) do
              {:ok, attachment} -> SendGrid.Email.add_attachment(email, attachment)
              _ -> email
            end
          is_map(v) -> SendGrid.Email.add_attachment(email, v)
          true-> email
        end
      end)
      true -> email
    end
  end

  #--------------------------
  # put_html/2
  #--------------------------
  defp put_html(email, binding) do
    binding.body && Email.put_html(email, binding.body) || email
  end # end put_html/2

  #--------------------------
  # put_subject/2
  #--------------------------
  defp put_subject(email, binding) do
    binding.subject && Email.put_subject(email, binding.subject) || email
  end # end put_subject

  #--------------------------
  # put_substitions/2
  #--------------------------
  defp put_substitions(email, binding) do
    List.foldl(binding.substitutions, email, fn({substition_key, substition_value}, acc) -> Email.add_substitution(acc, "-{#{substition_key}}-", substition_value) end)
  end # end put_substitions/2

  #--------------------------
  # restricted?/1
  #--------------------------
  defp restricted?(email) do
    r = Application.get_env(:sendgrid, :restricted)
    cond do
      r != nil && r != false ->
        regex = Application.get_env(:sendgrid, :restricted_regex) || ~r/@(#{r})$/
        !(Regex.match?(regex, email))
      true -> false
    end
  end # end restricted?/1

  #--------------------------
  # put_html/2
  #--------------------------
  defp simulate?() do
    Application.get_env(:sendgrid, :simulate)
  end

end # end defmodule
