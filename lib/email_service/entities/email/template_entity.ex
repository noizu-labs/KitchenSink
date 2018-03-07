#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.TemplateEntity do
  @vsn 1.0
  alias Noizu.KitchenSink.Types, as: T
  Noizu.EmailService.Email.TemplateRepo

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

  use Noizu.Scaffolding.EntityBehaviour,
      sref_module: "email-template",
      mnesia_table: Noizu.EmailService.Database.Email.TemplateTable,
      as_record_options: %{additional_fields: [:synched_on]},
      dirty_default: true

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)


  #--------------------------
  # refresh!
  #--------------------------
  def refresh(%__MODULE__{} = this, context) do
    cond do
      simulate?() -> this
      (this.synched_on == nil || DateTime.compare(DateTime.utc_now, Timex.shift(this.synched_on, minutes: 30)) == :gt ) ->
                       refresh(this.template.external_template_identifier, this)
                       |> TemplateRepo.update!(update, context)
      true -> this
    end
  end # end refresh/1

  #--------------------------
  # refresh/2
  #--------------------------
  def refresh({:sendgrid, identifier}, this) do
    # Load Template from SendGrid
    template = SendGrid.Templates.get(identifier)

    # Grab Active Version
    version = Enum.find(template.versions, &(&1.active))

    # Grab Substitutions
    substitutions = Template.extract_substitutions(version)

    cached = %{version: version.id, substitutions: substitutions}

    # Return updated record
    %__MODULE__{this| cached: cached, synched_on: DateTime.utc_now()}
  end # end refresh/2

  #--------------------------
  # refresh/1
  #--------------------------
  defp simulate?() do
    Application.get_env(:sendgrid, :simulate)
  end
end