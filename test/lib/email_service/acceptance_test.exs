#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.AcceptanceTest do
  use ExUnit.Case, async: false
  require Logger

  @context Noizu.ElixirCore.CallingContext.admin()

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
    sut = Noizu.EmailService.SendGrid.TransactionalEmail.send!(email, @context)
    assert sut.__struct__ == Noizu.EmailService.Email.QueueEntity
    assert sut.binding.effective_binding.outcome == :ok
    assert sut.binding.effective_binding.outcome == :ok
    assert sut.binding.effective_binding.bound == %{"default_field" => "default_value", "foo.bar" => "foo-bizz", "site" => "https://github.com/noizu/KitchenSink"}
    assert sut.binding.recipient_email == "keith.brings+recipient@noizu.com"
    assert sut.binding.body == "Email Body"
    assert sut.binding.html_body == "HTML Email Body"
    # Delay to allow send to complete.
    Process.sleep(1000)
    queue_entry = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier)
    assert Enum.member?([:delivered, :queued], queue_entry.state)
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
    Process.sleep(1000)
    queue_entry = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier)
    assert Enum.member?([:delivered, :queued], queue_entry.state)
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
  end
end