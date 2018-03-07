#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.EmailService.Database do
  #-----------------------------------------------------------------------------
  # @Email.Template
  #-----------------------------------------------------------------------------
  # 1. Email Template
  deftable Email.TemplateTable, [:identifier, :synched_on, :entity], type: :ordered_set, index: [:handle, :synched_on] do
    @moduledoc """
    Email Template
    """
    @type t :: %Email.TemplateTable{
                 identifier: any,
                 synched_on: nil | integer,
                 entity: Noizu.EmailService.Email.TemplateEntity.t
               }

  end # end deftable Email.Templates

  #-----------------------------------------------------------------------------
  # @Email.Queue
  #-----------------------------------------------------------------------------
  # 2. Email Queue
  deftable Email.QueueTable,
           [:identifier, :recipient, :sender, :state, :created_on, :retry_on, :entity],
           type: :set,
           index: [:recipient, :sender, :state, :created_on, :retry_on] do
    @moduledoc """
    Email Queue
    """
    @type t :: %Email.QueueTable{
                 identifier: any,
                 recipient: Noizu.KitchenSink.Types.entity_reference,
                 sender: Noizu.KitchenSink.Types.entity_reference,
                 state: :queued | :delivered | :undeliverable | :retrying | :error,
                 created_on: integer,
                 retry_on: nil | integer,
                 entity: Noizu.EmailService.Email.QueueEntity.t
               }
  end # end deftable Email.Queue
end