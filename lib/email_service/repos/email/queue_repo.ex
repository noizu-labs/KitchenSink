#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.QueueRepo do
  use Noizu.Scaffolding.RepoBehaviour,
      mnesia_table: Noizu.EmailService.Database.Email.QueueTable,
      override: [] #@TODO CRITICAL override audit engine, @TODO audit format protocol.
  require Logger
  alias Noizu.EmailService.Email.QueueEntity
  alias Noizu.ElixirCore.CallingContext
  alias Noizu.EmailService.Email.Binding

  #--------------------------
  # queue_failed!
  #--------------------------
  def queue_failed!(binding, _details, context) do
    %QueueEntity{
      recipient: binding.recipient,
      sender: binding.sender,
      state: :error,
      created_on: DateTime.utc_now(),
      retry_on: nil,
      template: Noizu.ERP.ref(binding.template),
      version: binding.template_version,
      binding: binding,
      email: nil,
    } |> create!(CallingContext.system(context))
  end # end queue_failed/3

  #--------------------------
  # queue!
  #--------------------------
  def queue!(%Binding{} = binding, context) do
    time = DateTime.utc_now()
    %QueueEntity{
      recipient: binding.recipient,
      sender: binding.sender,
      state: :queued,
      created_on: time,
      retry_on: Timex.shift(time, minutes: 30),
      template: Noizu.ERP.ref(binding.template),
      version: binding.template_version,
      binding: binding,
      email: nil,
    } |> create!(CallingContext.system(context))
  end # end queue/2

  #--------------------------
  # update_state!
  #--------------------------
  def update_state!(%QueueEntity{} = entity, :retrying, context) do
    retry_on = Timex.shift(DateTime.utc_now(), minutes: 30)
    %QueueEntity{entity| retry_on: retry_on, state: :retrying}
    |> update!(CallingContext.system(context))
  end # end update_state/2

  def update_state!(%QueueEntity{} = entity, new_state, context) do
    %QueueEntity{entity| retry_on: nil, state: new_state}
    |> update!(CallingContext.system(context))
  end # end update_state/2
end