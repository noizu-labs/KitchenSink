#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding do
  @vsn 1.1
  alias Noizu.KitchenSink.Types, as: T

  alias Noizu.EmailService.SendGrid.TransactionalEmail
  alias Noizu.EmailService.Email.TemplateEntity

  @type t :: %__MODULE__{
               recipient: T.entity_reference,
               recipient_name: :default | String.t,
               recipient_email: :default | String.t,

               sender: T.entity_reference,
               sender_name: :default | String.t,
               sender_email: :default | String.t,

               reply_to: T.entity_reference,
               reply_to_name: :default | String.t,
               reply_to_email: :default | String.t,

               bcc: list | nil,

               body: String.t,
               html_body: String.t,
               subject: String.t,

               template: any,
               template_version: any, # Exact version being used {:sendgrid, template, version}

               state: :ok | {:error| any},

               effective_binding: any,

               attachments: Map.t,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    recipient: nil,
    recipient_name: :default,
    recipient_email: :default,

    sender: nil,
    sender_name: :default,
    sender_email: :default,

    reply_to: nil,
    reply_to_name: :default,
    reply_to_email: :default,

    bcc: nil,

    body: nil,
    html_body: nil,
    subject: nil,

    template: nil,
    template_version: nil,

    state: nil,

    effective_binding: nil,

    attachments: nil,
    meta: %{},
    vsn: @vsn
  ]

  def update_version(%{vsn: 1.0} = entity, _context, _options) do
    bind = Map.keys(entity.substitutions || %{}) ++ Map.keys(entity.unbound || %{})
    bound = entity.substitutions
    unbound = Enum.map(entity.unbound || %{}, &(&1))
    effective_binding = %Noizu.EmailService.Email.Binding.Substitution.Legacy.Effective{
      bind: bind,
      bound: bound,
      unbound: %{:optional => [], :required => unbound},
      outcome: length(unbound) > 0 && {:error, :unbound_fields} || :ok
    }
    entity
    |> Map.delete(:substitutions)
    |> Map.delete(:unbound)
    |> Map.put(:reply_to, nil)
    |> Map.put(:reply_to_name, nil)
    |> Map.put(:reply_to_email, nil)
    |> Map.put(:bcc, nil)
    |> Map.put(:effective_binding, effective_binding)
    |> Map.put(:template, Noizu.ERP.ref(entity.template))
    |> Map.put(:state, effective_binding.outcome)
    |> Map.put(:vsn, @vsn)
  end

  def update_version(%{vsn: 1.1} = entity, _context, _options) do
    entity
  end

  #--------------------------
  # bind_from_template/1
  #--------------------------
  @doc """

  """
  def bind_from_template(%TransactionalEmail{} = txn_email, %TemplateEntity{} = template, context, options) do
    #-------------------------------
    # 1. Update Bindings & Extract final recipient/sender values in reference format.
    #-------------------------------------
    binding_input = prepare_binding_inputs(txn_email, template, context, options)

    #-------------------------------------
    # 2. Track bindings required for template
    #-------------------------------------
    effective_binding = TemplateEntity.effective_binding(template, binding_input, context, options)

    #-------------------------------
    # 3. Return Binding Structure
    #-------------------------------------
    recipient = Noizu.Proto.EmailAddress.email_details(txn_email.recipient)
    sender = Noizu.Proto.EmailAddress.email_details(txn_email.sender)
    reply_to = Noizu.Proto.EmailAddress.email_details(txn_email.reply_to)

    outcome = effective_binding.outcome
    {bcc, outcome} = Enum.map_reduce(txn_email.bcc || [], outcome, fn(bcc, o) ->
      case Noizu.Proto.EmailAddress.email_details(bcc) do
        {:error, details} ->
          cond do
            o != :ok -> {nil, o}
            :else -> {nil, {:error, details}}
          end
        nil ->
          cond do
            o != :ok -> {nil, o}
            :else -> {nil, {:error, :invalid_bcc}}
          end
        v -> {v, o}
      end
    end)
    bcc = Enum.filter(bcc || [], &(&1))

    outcome = cond do
                outcome != :ok -> outcome
                Kernel.match?({:error, :_}, recipient) -> recipient
                (recipient == nil || recipient.email == nil) && binding_input[:recipient_email] == nil && (txn_email.recipient_email == nil || txn_email.recipient_email == :default) -> {:error, :recipient_required}
                :else -> outcome
              end
    outcome = cond do
                outcome != :ok -> outcome
                Kernel.match?({:error, :_}, sender) -> sender
                (sender == nil || sender.email == nil) && binding_input[:sender_email] == nil -> {:error, :sender_required}
                :else -> outcome
              end
    outcome = cond do
                outcome != :ok -> outcome
                Kernel.match?({:error, :_}, reply_to) -> reply_to
                (reply_to && reply_to.email == nil) && binding_input[:reply_to_email] == nil -> {:error, :invalid_reply_to}
                :else -> outcome # not required field, no need for nil check
              end

    # strip error tuples
    recipient = is_map(recipient) && recipient || nil
    sender = is_map(sender) && sender || nil
    reply_to = is_map(reply_to) && reply_to || nil

    # prepare response
    _this = %__MODULE__{
      recipient: recipient[:ref],
      recipient_name: binding_input[:recipient_name] || recipient[:name],
      recipient_email: (txn_email.recipient_email != :default && txn_email.recipient_email) || binding_input[:recipient_email] || recipient[:email],

      sender: sender[:ref],
      sender_name: binding_input[:sender_name] || sender[:name],
      sender_email: binding_input[:sender_email] || sender[:email],

      reply_to: reply_to[:ref],
      reply_to_name: binding_input[:reply_to_name] || reply_to[:name],
      reply_to_email: binding_input[:reply_to_email] || reply_to[:email],

      bcc: bcc,

      subject: txn_email.subject,
      body: txn_email.body,
      html_body: txn_email.html_body,

      # TODO collapse to a unique version identifier
      template: Noizu.ERP.ref(template),
      template_version: %{template: template.external_template_identifier, version: template.cached.version},

      state: outcome,

      effective_binding: effective_binding,


      attachments: txn_email.attachments,
    }
  end # end bind/2

  #----------------------------
  # prepare_binding_inputs/4
  #----------------------------
  def prepare_binding_inputs(%TransactionalEmail{} = email, %TemplateEntity{} = template, context, options) do
    # 1. Expand email bindings, ensure :sender and :recipient set.
    initial_bindings = is_map(email.bindings) && email.bindings || %{}

    if template.binding_defaults == nil do
      initial_bindings
    else
      List.foldl(
        template.binding_defaults,
        initial_bindings,
        fn({key, default}, updated) ->
          apply_template_binding(key, default, updated, context, options)
        end # end lambda
      ) # end foldl
    end # end if/else
  end # end apply_template_bindings/2

  #----------------------------
  # apply_template_binding/5
  #----------------------------
  defp apply_template_binding(key, default, bindings, context, options) do
    # Process if entry does not exist or is set to :nil (use :undefined if you specifically do not want another value)
    # @NOTE logic may change in the future based on usage patterns/needs.
    case key do
      {:path, path} ->
        cond do
          path_valid?(path, bindings) ->
            v = calculate_binding(default, bindings, context, options)
            update_in(bindings, path, &(&1 || v))
          :else -> bindings
        end
      key ->
        cond do
          (bindings[key] == nil) -> bindings |> Map.put(key, calculate_binding(default, bindings, context, options))
          :else -> bindings
        end
    end
  end # end apply_template_binding/5

  #----------------------------
  #
  #----------------------------
  defp path_valid?([_h], nil), do: false
  defp path_valid?([h], blob) do
    try do
      get_in(blob, [h])
      true
    rescue _ -> false
    catch _ -> false
    end
  end
  defp path_valid?([h|t], blob) do
    try do
      b = get_in(blob, [h])
      path_valid?(t, b)
    rescue _ -> false
    catch _ -> false
    end
  end

  #----------------------------
  # calculate_binding/3
  #----------------------------
  defp calculate_binding({:literal, value}, _bindings, _context, _options) do
    value
  end # end calculate_binding/2

  defp calculate_binding({:bind, field}, bindings, _context, _options) do
    case field do
      {:path, path} ->
        cond do
          path_valid?(path, bindings) -> get_in(bindings, path)
          :else -> nil
        end
      _other -> bindings[field]
    end
  end # end calculate_binding/2

  defp calculate_binding({:entity_reference, reference}, _bindings, _context, _options) do
    Noizu.ERP.entity!(reference)
  end # end calculate_binding/2

  defp calculate_binding(%Noizu.SmartToken.TokenEntity{} = smart_token, bindings, context, options) do
    smart_token
    |> Noizu.SmartToken.TokenEntity.bind(bindings, options)
    |> Noizu.SmartToken.TokenRepo.create!(Noizu.ElixirCore.CallingContext.system(context))
  end # end calculate_binding/2

end # end defmodule
