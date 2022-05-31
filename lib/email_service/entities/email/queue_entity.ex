#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.QueueEntity do
  @vsn 1.1

  @type t :: %__MODULE__{
               identifier: any,
               recipient: any,
               sender: any,
               state: any,
               created_on: any,
               retry_on: any,

               template: any, # template.ref
               version: any, # template version or time stamp.
               binding: any, # effective binding.

               email: any, # actual email as sent or what is to be sent . . . @TODO details.

               kind: any,
               vsn: float
             }

  defstruct [
    identifier: nil,
    recipient: nil,
    sender: nil,
    state: nil,
    created_on: nil,
    retry_on: nil,

    template: nil,
    version: nil,
    binding: nil,

    email: nil,

    kind: __MODULE__,
    vsn: @vsn
  ]

  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "queued-email",
      mnesia_table: Noizu.EmailService.Database.Email.QueueTable,
      as_record_options: %{additional_fields: [:recipient, :sender, :state, :created_on, :retry_on]},
      dirty_default: true

end


defimpl Noizu.ERP, for: [Noizu.EmailService.Email.QueueEntity, Noizu.EmailService.Database.Email.QueueTable] do
  defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver

  def id_ok(o) do
    r = id(o)
    r && {:ok, r} || {:error, o}
  end
  def ref_ok(o) do
    r = ref(o)
    r && {:ok, r} || {:error, o}
  end
  def sref_ok(o) do
    r = sref(o)
    r && {:ok, r} || {:error, o}
  end
  def entity_ok(o, options \\ %{}) do
    r = entity(o, options)
    r && {:ok, r} || {:error, o}
  end
  def entity_ok!(o, options \\ %{}) do
    r = entity!(o, options)
    r && {:ok, r} || {:error, o}
  end
end