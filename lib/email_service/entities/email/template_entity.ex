#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.TemplateEntity do
  @vsn 1.0
  alias Noizu.KitchenSink.Types, as: T
  alias Noizu.EmailService.Email.TemplateRepo
  alias Noizu.EmailService.Email.Binding

  @type t :: %__MODULE__{
               identifier: T.nmid,
               synched_on: DateTime.t,
               cached: any,
               name: String.t,
               description: String.t,
               external_template_identifier: T.entity_reference,
               binding_defaults: [{atom|String.t,any}], # TODO revisit data structure
               kind: module,
               vsn: T.vsn
             }

  defstruct [
    identifier: nil,
    synched_on: nil,
    cached: nil,

    name: nil,
    description: nil,
    external_template_identifier: nil,
    binding_defaults: [],
    kind: __MODULE__,
    vsn: @vsn
  ]

  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "email-template",
      mnesia_table: Noizu.EmailService.Database.Email.TemplateTable,
      as_record_options: %{additional_fields: [:synched_on]},
      dirty_default: true

  #--------------------------
  # refresh!
  #--------------------------
  def refresh!(%__MODULE__{} = this, context) do
    cond do
      simulate?() ->
        this
      (this.synched_on == nil || DateTime.compare(DateTime.utc_now, Timex.shift(this.synched_on, minutes: 30)) == :gt ) ->
        this.external_template_identifier
        |> internal_refresh!(this)
        |> TemplateRepo.update!(context)
      true -> this
    end
  end # end refresh/1

  defp internal_refresh__cache(%SendGrid.LegacyTemplate{} = template) do
    # Grab Active Version
    version = Enum.find(template.versions, &(&1.active))

    # Grab Substitutions
    Noizu.EmailService.Email.Binding.Substitution.Legacy.extract(version)
  end

  defp internal_refresh__cache(%SendGrid.DynamicTemplate{} = template) do
    # Grab Active Version
    version = Enum.find(template.versions, &(&1.active))

    # Grab Substitutions
    Noizu.EmailService.Email.Binding.Substitution.Dynamic.extract(version)
  end

  #--------------------------
  # internal_refresh/2
  #--------------------------
  defp internal_refresh!({:sendgrid, identifier}, this) do
    # Load Template from SendGrid
    template = SendGrid.Templates.get(identifier)
    cached = internal_refresh__cache(template)

    # Return updated record
    %__MODULE__{this| cached: cached, synched_on: DateTime.utc_now()}
  end # end refresh/2

  #--------------------------
  # effective_binding
  #--------------------------
  def effective_binding(template, binding_input, context, options) do
    case template.cached do
      v =  %Noizu.EmailService.Email.Binding.Substitution.Dynamic{} ->
        Noizu.EmailService.Email.Binding.Substitution.Dynamic.effective_bindings(v, binding_input, context, options)

      v =  %Noizu.EmailService.Email.Binding.Substitution.Legacy{binding: substitutions} ->
        Noizu.EmailService.Email.Binding.Substitution.Legacy.effective_bindings(v, binding_input, context, options)

      _ -> {:error, :not_supported}
    end
  end

  #--------------------------
  # refresh/1
  #--------------------------
  defp simulate?() do
    Application.get_env(:sendgrid, :simulate)
  end
end

defimpl Noizu.ERP, for: [Noizu.EmailService.Email.TemplateEntity, Noizu.EmailService.Database.Email.TemplateTable] do
  defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
end

defimpl Noizu.Proto.EmailServiceTemplate, for: Noizu.EmailService.Email.TemplateEntity do
  defdelegate refresh!(template, context), to: Noizu.EmailService.Email.TemplateEntity
end