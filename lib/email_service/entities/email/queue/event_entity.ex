#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Queue.EventEntity do
  @vsn 1.0

  @type t :: %__MODULE__{
               identifier: any,
               queue_item: any,
               event: any,
               event_time: DateTime.t,
               details: Map.t,
               meta: Map.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    queue_item: nil,
    event: nil,
    event_time: nil,
    details: %{},
    meta: %{},
    vsn: @vsn
  ]

  use Noizu.Scaffolding.V2.EntityBehaviour,
      sref_module: "queued-email-event",
      mnesia_table: Noizu.EmailService.Database.Email.Queue.EventTable,
      as_record_options: %{additional_fields: [:queue_item, :event, :event_time]},
      dirty_default: true

end


defimpl Noizu.ERP, for: [Noizu.EmailService.Email.Queue.EventEntity, Noizu.EmailService.Database.Email.Queue.EventTable] do
  defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
end