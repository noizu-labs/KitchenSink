#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
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

               body: String.t,
               html_body: String.t,
               subject: String.t,

               template: any,
               template_version: any, # Exact version being used {:sendgrid, template, version}

               state: :valid | {:error| any},

               substitutions: Map.t, # Injected variables.
               unbound: Map.t, # Template variables we were unable to bind to values.
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

    body: nil,
    html_body: nil,
    subject: nil,

    template: nil,
    template_version: nil,

    state: nil,

    substitutions: nil,
    unbound: nil,
    attachments: nil,
    meta: %{},
    vsn: @vsn
  ]


  #--------------------------
  # bind_from_template/1
  #--------------------------
  @doc """

  """
  def bind_from_template(%TransactionalEmail{} = email, %TemplateEntity{} = template, context, options) do
    #-------------------------------
    # 1. Update Bindings & Extract final recipient/sender values in reference format.
    #-------------------------------------
    bindings = apply_template_bindings(email, template, context, options)

    #-------------------------------------
    # 2. Track bindings required for template
    #-------------------------------------
    {bound, unbound} = extract_bindings(bindings, template.cached, context)
    outcome = (map_size(unbound) != 0) && {:error, :unbound_fields} || :ok

    #-------------------------------
    # 3. Return Binding Structure
    #-------------------------------------

    recipient = Noizu.Proto.EmailAddress.email_details(bindings.recipient)
    sender = Noizu.Proto.EmailAddress.email_details(bindings.sender)

    binding = %__MODULE__{
      recipient: recipient.ref,
      recipient_name: bindings[:recipient_name] || recipient.name,
      recipient_email: bindings[:recipient_email] || recipient.email,

      sender: sender.ref,
      sender_name: bindings[:sender_name] || sender.name,
      sender_email: bindings[:sender_email] ||  sender.email,

      subject: bindings.subject,
      body: bindings.body,
      html_body: bindings.html_body,

      template: template,
      template_version: %{template: template.external_template_identifier, version: template.cached_details[:version]},

      state: outcome,
      substitutions: bound,
      unbound: unbound,

      attachments: bindings.attachments,
    }

    {outcome, binding}
  end # end bind/2


  #-------------------------
  # extract_bindings/3
  #-------------------------
  def extract_bindings(bindings, cached_details, context) do
    case cached_details[:substitutions] do
      nil -> {%{}, %{}}
      %MapSet{} = substitutions ->
        List.foldl(
          MapSet.to_list(substitutions),
          {%{}, %{}},
          fn(binding, {bound, unbound}) ->
            case extract_binding(binding, bindings, context) do
              {:error, details} ->
                {bound, Map.put(unbound, binding, {:error, details})}
              m ->
                {Map.put(bound, binding, m), unbound}
            end
          end
        )
    end
  end # end extract_bindings/2

  #-------------------------
  # extract_binding/3
  #-------------------------
  def extract_binding(binding, bindings, context) do
    value = if Map.has_key?(bindings, binding) do
      # Allow Overrides of fields otherwise yanked from EAV, Structs, etc.
      bindings[binding]
    else
      case String.split(binding, ".") do
        ["site"] -> extract_inner_site()
        ["EAV"| specifier] -> extract_inner_eav(specifier, context)
        path -> extract_inner_path(path, bindings, context)
      end
    end

    case value do
      {:error, details} -> {:error, details}
      _ -> Noizu.Proto.EmailBind.format(value)
    end
  end # end extract_binding/2

  #-------------------------
  # extract_inner_site/0
  #-------------------------
  defp extract_inner_site() do
    case Application.get_env(:sendgrid, :email_site_url) do
      nil -> {:error, :email_sit_url_not_set}
      m -> m
    end
  end # end extract_inner/1

  #-------------------------
  # extract_inner_eav/1
  #-------------------------
  defp extract_inner_eav(_path, _context) do
    #@TODO _path ->  ref.type.id|attribute
    #@TODO pending EAV table implementation.
    {:error, :eav_lookup_nyi}
  end # end extract_inner/2

  #-------------------------
  # extract_inner_path/3
  #-------------------------
  defp extract_inner_path([] = _path, current, _context) do
    current
  end # end extract_inner/3

  defp extract_inner_path([h|t] = _path, %{} = current, context) do
    matching_key = Map.keys(current)
                   |> Enum.find(&("#{&1}" == h))
    cond do
      matching_key == nil && h == "EAV" ->
        # @TODO Noizu.ERP.ref(current) -> EAV fetch
        {:error, :eav_lookup_nyi}
      matching_key == nil -> {:error, "#{h} key not found."}
        true -> extract_inner_path(t, Map.get(current, matching_key), context)
    end
  end # end extract_inner/3

  #----------------------------
  # apply_template_bindings/4
  #----------------------------
  def apply_template_bindings(%TransactionalEmail{} = email, %TemplateEntity{} = template, context, options) do
    # 1. Expand email bindings, ensure :sender and :recipient set.
    initial_bindings = prep_email_bindings(email)

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
  # prep_email_bindings/1
  #----------------------------
  defp prep_email_bindings(%TransactionalEmail{} = email) do
    # 1. Expand Recipient & Sender (Either may be null)
    recipient = Noizu.ERP.entity!(email.recipient)
    sender = Noizu.ERP.entity!(email.sender)

    # 2. Append recipient, sender fields to simplify downstream logic.
    (is_map(email.bindings) && email.bindings || %{})
      |> Map.put(:recipient, recipient)
      |> Map.put(:sender, sender)
      |> Map.put(:body, email.body)
      |> Map.put(:html_body, email.html_body)
      |> Map.put(:subject, email.subject)
      |> Map.put(:attachments, email.attachments)
  end # end prep_email_bindings/1



  #----------------------------
  # apply_template_binding/5
  #----------------------------
  defp apply_template_binding(key, default, bindings, context, options) do
    # Process if entry does not exist or is set to :nil (use :undefined if you specifically do not want another value)
    # @NOTE logic may change in the future based on usage patterns/needs.
    cond do
      (bindings[key] == nil) -> bindings |> Map.put(key, calculate_binding(default, bindings, context, options))
      true -> bindings
    end
  end # end apply_template_binding/5

  #----------------------------
  # calculate_binding/3
  #----------------------------
  defp calculate_binding({:literal, value}, _bindings, _context, _options) do
    value
  end # end calculate_binding/2

  defp calculate_binding({:bind, field}, bindings, _context, _options) do
    bindings[field]
  end # end calculate_binding/2

  defp calculate_binding({:entity_reference, reference}, _bindings, _context, _options) do
    Noizu.ERP.entity!(reference)
  end # end calculate_binding/2

  defp calculate_binding(%Noizu.SmartToken.TokenEntity{} = smart_token, bindings, context, options) do
    smart_token
    |> Noizu.SmartToken.TokenEntity.bind(bindings, options)
    |> Noizu.SmartToken.TokenRepo.create!(Noizu.ElixirCore.CallingContext.system(context))
  end # end calculate_binding/2


  #----------------------------
  # extract_substitutions/1
  #----------------------------
  def extract_substitutions(%SendGrid.Template.Version{} = version) do
    extract_field_substitutions(version, :subject)
    |> MapSet.union(extract_field_substitutions(version, :html_content))
    |> MapSet.union(extract_field_substitutions(version, :plain_content))
  end # end extract_substitutions/1

  #----------------------------
  # extract_field_substitutions/2
  #----------------------------
  defp extract_field_substitutions(subject, field) do
    case Map.get(subject, field) do
      :nil -> MapSet.new
      value when is_bitstring(value) ->
        case Regex.scan(~r/-\{([a-zA-Z0-9\._\[\]]+)\}-/, value, capture: :all_but_first) do
          :nil -> MapSet.new()
          matches when is_list(matches) ->
            matches
            |> List.flatten
            |> MapSet.new
        end
    end # end case
  end # end extract_field_substitions/2

end # end defmodule
