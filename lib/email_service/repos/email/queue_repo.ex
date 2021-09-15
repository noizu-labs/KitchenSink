#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.QueueRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
      mnesia_table: Noizu.EmailService.Database.Email.QueueTable

  require Logger
  alias Noizu.EmailService.Email.QueueEntity
  alias Noizu.ElixirCore.CallingContext
  alias Noizu.EmailService.Email.Binding

  #----------------------------
  # post_get_callback/3
  #----------------------------
  def post_get_callback(%{vsn: 1.1} = entity, _context, _options) do
     entity
  end
  def post_get_callback(%{vsn: vsn} = entity, context, options) do
    entity = update_version(entity, context, options)
    cond do
      entity.vsn != vsn -> update!(entity, Noizu.ElixirCore.CallingContext.system(context), options)
      :else -> entity
    end
  end
  def post_get_callback(entity, _context, _options) do
    entity
  end

  #----------------------------
  # update_version/3
  #----------------------------
  def update_version(%{vsn: 1.0} = entity, context, options) do
    entity
    |> put_in([Access.key(:binding)], Noizu.EmailService.Email.Binding.update_version(entity.binding, context, options))
    |> put_in([Access.key(:vsn)], 1.1)
  end

  def update_version(%{vsn: 1.1} = entity, _context, _options) do
    entity
  end

  #--------------------------
  # queue_failed!
  #--------------------------
  def queue_failed!(binding, details, context) do
    queue_entry = %QueueEntity{
      recipient: binding.recipient,
      sender: binding.sender,
      state: {:error, details || :unknown},
      created_on: DateTime.utc_now(),
      retry_on: nil,
      template: Noizu.ERP.ref(binding.template),
      version: binding.template_version,
      binding: binding,
      email: nil,
    } |> create!(CallingContext.system(context))

    ref = Noizu.ERP.ref(queue_entry)
    %Noizu.EmailService.Email.Queue.EventEntity{
      queue_item: ref,
      event: :failure,
      event_time: queue_entry.created_on,
      details: {:error, details || :unknown},
    } |> Noizu.EmailService.Email.Queue.EventRepo.create!(Noizu.ElixirCore.CallingContext.system(context))

    queue_entry

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
  # update_state_and_history!
  #--------------------------
  def update_state_and_history!(%QueueEntity{} = entity, :retrying, {event, details}, context) do
    retry_on = Timex.shift(DateTime.utc_now(), minutes: 30)
    queue_entry = %QueueEntity{entity| retry_on: retry_on, state: :retrying}
                  |> update!(CallingContext.system(context))


    ref = Noizu.ERP.ref(queue_entry)
    %Noizu.EmailService.Email.Queue.EventEntity{
      queue_item: ref,
      event: event,
      event_time: DateTime.utc_now(),
      details: details,
    } |> Noizu.EmailService.Email.Queue.EventRepo.create!(Noizu.ElixirCore.CallingContext.system(context))

    queue_entry
  end # end update_state/2

  def update_state_and_history!(%QueueEntity{} = entity, new_state, {event, details}, context) do
    queue_entry = %QueueEntity{entity| retry_on: nil, state: new_state}
                  |> update!(CallingContext.system(context))

    ref = Noizu.ERP.ref(queue_entry)
    %Noizu.EmailService.Email.Queue.EventEntity{
      queue_item: ref,
      event: event,
      event_time: DateTime.utc_now(),
      details: details,
    } |> Noizu.EmailService.Email.Queue.EventRepo.create!(Noizu.ElixirCore.CallingContext.system(context))

    queue_entry
  end # end update_state/2
end