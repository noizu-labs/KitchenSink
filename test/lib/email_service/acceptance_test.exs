#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.AcceptanceTest do
  use ExUnit.Case, async: false
  require Logger

  @context Noizu.ElixirCore.CallingContext.admin()

  test "Send Transactional Email" do
    template = Noizu.EmailService.Email.TemplateRepo.get!(:test_template, @context)
               |> Noizu.EmailService.Email.TemplateEntity.refresh!(@context)

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
    assert sut.binding.substitutions == %{"default_field" => "default_value", "foo.bar" => "foo-bizz", "site" => "https://github.com/noizu/KitchenSink"}
    assert sut.binding.recipient_email == "keith.brings+recipient@noizu.com"
    assert sut.binding.body == "Email Body"
    assert sut.binding.html_body == "HTML Email Body"
    # Delay to allow send to complete.
    Process.sleep(1000)
    queue_entry = Noizu.EmailService.Database.Email.QueueTable.read!(sut.identifier)
    assert queue_entry.state == :delivered
  end

  #test "Send Standard Email" do
  #  assert true == false
  #end
end