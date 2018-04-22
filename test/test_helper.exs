#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

# Schema Setup
Amnesia.Schema.destroy()
Amnesia.Schema.create()

# Start Amnesia
Amnesia.start()

# Email Service
Noizu.EmailService.Database.Email.TemplateTable.create(memory: [node()])
Noizu.EmailService.Database.Email.QueueTable.create(memory: [node()])

# Cms
Noizu.Cms.Database.PostTable.create(memory: [node()])
Noizu.Cms.Database.Post.TagTable.create(memory: [node()])
Noizu.Cms.Database.Post.VersionTable.create(memory: [node()])
Noizu.Cms.Database.Post.VersionHistoryTable.create(memory: [node()])

# Smart Token
Noizu.SmartToken.Database.TokenTable.create(memory: [node()])

ExUnit.start()