#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.QueueEntity do
  @vsn 1.0
  alias Noizu.KitchenSink.Types, as: T

  @type t :: %__MODULE__{
               identifier: any,
               recipient: any,
               sender: any,
               state: any,
               created_on: any,
               retry_on: any,

               template: any, # template.ref
               version: any, # template version or time stamp.
               binding: any, # binding provided.

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

  use Noizu.Scaffolding.EntityBehaviour,
      sref_module: "queued-email",
      mnesia_table: Noizu.EmailService.Database.Email.QueueTable,
      as_record_options: %{additional_fields: [:recipient, :sender, :state, :Created_on, :retry_on]},
      dirty_default: true

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)

end