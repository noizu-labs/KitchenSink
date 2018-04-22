#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

Application.load(:tzdata)
{:ok, _} = Application.ensure_all_started(:tzdata)

# Schema Setup
#Amnesia.Schema.destroy()
Amnesia.Schema.create()

# Start Amnesia
Amnesia.start()

# Support Records
Noizu.KitchenSink.Database.Support.UserTable.create(memory: [node()])

# Email Service
Noizu.EmailService.Database.Email.TemplateTable.create(memory: [node()])
Noizu.EmailService.Database.Email.QueueTable.create(memory: [node()])

# Setup Template
%Noizu.EmailService.Email.TemplateEntity{
  identifier: :test_template,
  name: "Test Template",
  description: "Template Description",
  external_template_identifier: {:sendgrid, "ccbe9d68-59ab-4639-87a8-07ab73a8dcc1"}, # todo standardize ref
  binding_defaults: [{:default_field, {:literal,  "default_value"}}],
} |> Noizu.EmailService.Email.TemplateRepo.create!(Noizu.ElixirCore.CallingContext.admin())

# Cms
Noizu.Cms.Database.PostTable.create(memory: [node()])
Noizu.Cms.Database.Post.TagTable.create(memory: [node()])
Noizu.Cms.Database.Post.VersionTable.create(memory: [node()])
Noizu.Cms.Database.Post.VersionHistoryTable.create(memory: [node()])

# Smart Token
Noizu.SmartToken.Database.TokenTable.create(memory: [node()])

ExUnit.start()