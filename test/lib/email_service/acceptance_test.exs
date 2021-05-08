#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.AcceptanceTest do
  use ExUnit.Case, async: false
  require Logger

  @context Noizu.ElixirCore.CallingContext.admin()


  def assert_eventually(msg, lambda, timeout \\ 5_000) do
    timeout = cond do
                timeout < 100_000 -> :os.system_time(:millisecond) + timeout
                :else -> timeout
              end

      cond do
        :os.system_time(:millisecond) < timeout ->
          cond do
            v = lambda.() -> v
            :else ->
              Process.sleep(100)
              assert_eventually(msg, lambda, timeout)
          end
        :else ->
          cond do
            v = lambda.() -> v
            :else -> assert :timeout == msg
          end
      end
  end

  @tag :email
  @tag :legacy_email
  test "Send Transactional Email (Legacy)" do
    template = Noizu.EmailService.Email.TemplateRepo.get!(:test_template, @context)
               |> Noizu.Proto.EmailServiceTemplate.refresh!(@context)
    template_ref = Noizu.EmailService.Email.TemplateEntity.ref(template)
    recipient = %Noizu.KitchenSink.Support.UserEntity{name: "Recipient Name", email: "keith.brings+recipient@noizu.com"}
                |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    sender = %Noizu.KitchenSink.Support.UserEntity{name: "Sender Name", email: "keith.brings+sender@noizu.com"}
             |> Noizu.KitchenSink.Support.UserRepo.create!(@context)

    email = %Noizu.EmailService.SendGrid.TransactionalEmail{
      template: template_ref,
      recipient: recipient,
      recipient_email: nil,
      sender: sender,
      body: "Email Body",
      html_body: "HTML Email Body",
      subject: "Email Subject",
      bindings: %{"foo" => %{"bar" => "foo-bizz"}},
    }
    sut = Noizu.EmailService.SendGrid.TransactionalEmail.send!(email, @context, %{persist_email: true})
    assert sut.__struct__ == Noizu.EmailService.Email.QueueEntity
    assert sut.binding.effective_binding.outcome == :ok
    assert sut.binding.effective_binding.outcome == :ok
    assert sut.binding.effective_binding.bound == %{"default_field" => "default_value", "foo.bar" => "foo-bizz", "site" => "https://github.com/noizu/KitchenSink"}
    assert sut.binding.recipient_email == "keith.brings+recipient@noizu.com"
    assert sut.binding.body == "Email Body"
    assert sut.binding.html_body == "HTML Email Body"
    # Delay to allow send to complete.
    Process.sleep(1000)

    assert_eventually(:email_delivered, fn() ->
      queue_entry = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier)
      Enum.member?([:delivered], queue_entry.state)
    end)

    # Verify email settings
    sut = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier).entity
    assert sut.email != nil
    assert sut.email.to == [%{email: "keith.brings+recipient@noizu.com", name: "Recipient Name"}]
    assert sut.email.from == %{email: "keith.brings+sender@noizu.com", name: "Sender Name"}
    assert sut.email.reply_to == nil

    queue_entry_ref = Noizu.ERP.ref(sut)
    history = Noizu.EmailService.Database.Email.Queue.EventTable.match!(queue_item: queue_entry_ref) |> Amnesia.Selection.values
    assert length(history) == 1
    [h] = history
    assert h.entity.event == :delivered
    assert h.entity.details == :first_attempt
  end


  @tag :email
  @tag :legacy_email
  test "Send Transactional Email (Legacy) email overrides and raw email persistence" do
    template = Noizu.EmailService.Email.TemplateRepo.get!(:test_template, @context)
               |> Noizu.Proto.EmailServiceTemplate.refresh!(@context)
    template_ref = Noizu.EmailService.Email.TemplateEntity.ref(template)
    recipient = %Noizu.KitchenSink.Support.UserEntity{name: "Recipient Name", email: "keith.brings+recipient@noizu.com"}
                |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    sender = %Noizu.KitchenSink.Support.UserEntity{name: "Sender Name", email: "keith.brings+sender@noizu.com"}
             |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
             |> Noizu.ERP.ref()

    reply_to = %Noizu.KitchenSink.Support.UserEntity{name: "Reply To Name", email: "keith.brings+reply@noizu.com"}

    email = %Noizu.EmailService.SendGrid.TransactionalEmail{
      template: template_ref,
      recipient: recipient,
      recipient_email: "keith.brings+override@noizu.com",
      sender: sender,
      reply_to: reply_to,
      body: "Email Body",
      html_body: "HTML Email Body",
      subject: "Email Subject",
      bindings: %{"foo" => %{"bar" => "foo-bizz"}},
    }
    sut = Noizu.EmailService.SendGrid.TransactionalEmail.send!(email, @context, %{persist_email: true, simulate_email: true})

    assert_eventually(:email_delivered, fn() ->
      queue_entry = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier)
      Enum.member?([:delivered], queue_entry.state)
    end)

    # Verify email override and reply to
    sut = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier).entity
    assert sut.email != nil
    assert sut.email.to == [%{email: "keith.brings+override@noizu.com", name: "Recipient Name"}]
    assert sut.email.from == %{email: "keith.brings+sender@noizu.com", name: "Sender Name"}
    assert sut.email.reply_to == %{email: "keith.brings+reply@noizu.com", name: "Reply To Name"}

    # Verify simulated send
    queue_entry_ref = Noizu.ERP.ref(sut)
    history = Noizu.EmailService.Database.Email.Queue.EventTable.match!(queue_item: queue_entry_ref) |> Amnesia.Selection.values
    assert length(history) == 1
    [h] = history
    assert h.entity.event == :delivered
    assert h.entity.details == :simulated
  end

  @tag :email
  @tag :legacy_email
  test "Send Transactional Email Failure (Legacy)" do
    template = Noizu.EmailService.Email.TemplateRepo.get!(:test_template, @context)
               |> Noizu.Proto.EmailServiceTemplate.refresh!(@context)
    template_ref = Noizu.EmailService.Email.TemplateEntity.ref(template)
    recipient = %Noizu.KitchenSink.Support.UserEntity{name: "Recipient Name", email: "keith.brings+recipient@noizu.com"}
                |> Noizu.KitchenSink.Support.UserRepo.create!(@context)
    sender = %Noizu.KitchenSink.Support.UserEntity{name: "Sender Name", email: "keith.brings+sender@noizu.com"}
             |> Noizu.KitchenSink.Support.UserRepo.create!(@context)

    email = %Noizu.EmailService.SendGrid.TransactionalEmail{
      template: template_ref,
      recipient: recipient,
      recipient_email: nil,
      sender: sender,
      body: "Email Body",
      html_body: "HTML Email Body",
      subject: "Email Subject",
      bindings: %{"foo" => %{}},
    }
    sut = Noizu.EmailService.SendGrid.TransactionalEmail.send!(email, @context)
    assert sut.__struct__ == Noizu.EmailService.Email.QueueEntity
    assert sut.binding.effective_binding.outcome == {:error, :unbound_fields}
    assert sut.state == {:error, :unbound_fields}

    queue_entry_ref = Noizu.ERP.ref(sut)
    history = Noizu.EmailService.Database.Email.Queue.EventTable.match!(queue_item: queue_entry_ref) |> Amnesia.Selection.values
    assert length(history) == 1
    [h] = history
    assert h.entity.event == :failure
    assert h.entity.details == {:error, :unbound_fields}
  end


  @tag :email
  @tag :dynamic_email
  test "Send Transactional Email (Dynamic)" do
    template = Noizu.EmailService.Email.TemplateRepo.get!(:test_dynamic_template, @context)
               |> Noizu.Proto.EmailServiceTemplate.refresh!(@context)
    template_ref = Noizu.EmailService.Email.TemplateEntity.ref(template)

    recipient = %Noizu.KitchenSink.Support.UserEntity{name: "Recipient Name", email: "keith.brings+recipient@noizu.com"}
                |> Noizu.KitchenSink.Support.UserRepo.create!(@context)

    sender = %Noizu.KitchenSink.Support.UserEntity{name: "Sender Name", email: "keith.brings+sender@noizu.com"}
             |> Noizu.KitchenSink.Support.UserRepo.create!(@context)

    email = %Noizu.EmailService.SendGrid.TransactionalEmail{
      template: template_ref,
      recipient: recipient,
      recipient_email: nil,
      sender: sender,
      body: nil,
      html_body: nil,
      subject: nil, # Note setting a subject for dynamic template will result in an error state, and email will be sent with out subject line. @todo detect for this.
      bindings: %{alert: %{language: %{"French" => true, "German" => false}, devices: "37001", temperature: %{low: %{unit: :celsius, value: 3.23}, current: %{unit: :celsius, value: 3.23}}, name: :wip}},
    }
    sut = Noizu.EmailService.SendGrid.TransactionalEmail.send!(email, @context)
    assert sut.state == :queued
    assert sut.__struct__ == Noizu.EmailService.Email.QueueEntity
    assert sut.binding.state == :ok
    assert sut.binding.effective_binding.outcome == :ok
    assert sut.binding.effective_binding.bound == %{"alert" => %{"language" => %{"French" => true, "German" => false}, "name" => :wip, "temperature" => %{"low" => %{"unit" => :celsius, "value" => 3.23}}}}
    assert sut.binding.recipient_email == "keith.brings+recipient@noizu.com"
    assert sut.binding.body == nil
    assert sut.binding.html_body == nil
    # Delay to allow send to complete.

    assert_eventually(:email_delivered, fn() ->
      queue_entry = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier)
      Enum.member?([:delivered], queue_entry.state)
    end)

    queue_entry_ref = Noizu.ERP.ref(sut)
    history = Noizu.EmailService.Database.Email.Queue.EventTable.match!(queue_item: queue_entry_ref) |> Amnesia.Selection.values
    assert length(history) == 1
    [h] = history
    assert h.entity.event == :delivered
    assert h.entity.details == :first_attempt
  end

  @tag :email
  @tag :dynamic_email
  test "Send Transactional Email Failure (Dynamic)" do
    template = Noizu.EmailService.Email.TemplateRepo.get!(:test_dynamic_template, @context)
               |> Noizu.Proto.EmailServiceTemplate.refresh!(@context)
    template_ref = Noizu.EmailService.Email.TemplateEntity.ref(template)

    recipient = %Noizu.KitchenSink.Support.UserEntity{name: "Recipient Name", email: "keith.brings+recipient@noizu.com"}
                |> Noizu.KitchenSink.Support.UserRepo.create!(@context)

    sender = %Noizu.KitchenSink.Support.UserEntity{name: "Sender Name", email: "keith.brings+sender@noizu.com"}
             |> Noizu.KitchenSink.Support.UserRepo.create!(@context)

    email = %Noizu.EmailService.SendGrid.TransactionalEmail{
      template: template_ref,
      recipient: recipient,
      recipient_email: nil,
      sender: sender,
      body: nil,
      html_body: nil,
      subject: nil,
      bindings: %{alert: %{language: %{"German" => true}}},
    }
    sut = Noizu.EmailService.SendGrid.TransactionalEmail.send!(email, @context)
    assert sut.__struct__ == Noizu.EmailService.Email.QueueEntity
    assert sut.state == {:error, :unbound_fields}
    assert sut.binding.effective_binding.outcome == {:error, :unbound_fields}
    assert sut.binding.state == {:error, :unbound_fields}

    queue_entry_ref = Noizu.ERP.ref(sut)
    history = Noizu.EmailService.Database.Email.Queue.EventTable.match!(queue_item: queue_entry_ref) |> Amnesia.Selection.values
    assert length(history) == 1
    [h] = history
    assert h.entity.event == :failure
    assert h.entity.details == {:error, :unbound_fields}
  end
end