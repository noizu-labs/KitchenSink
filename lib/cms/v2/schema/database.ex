#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.Cms.V2.Database do


  #-----------------------------------------------------------------------------
  # @ArticleTable
  #-----------------------------------------------------------------------------
  deftable ArticleTable, [:identifier, :entity], type: :set, index: [] do
    @type t :: %ArticleTable{
                 identifier: integer,
                 entity: any
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @EntryTable
  #-----------------------------------------------------------------------------
  deftable EntryTable, [:article, :status, :type, :editor, :created_on, :modified_on], type: :set, index: [:status, :type, :editor, :created_on, :modified_on] do
    @type t :: %EntryTable{
                 identifier: Noizu.KitchenSink.Types.entity_reference,
                 status: :approved | :pending | :disabled | atom,
                 type: :post | :file | :image | atom | module,
                 editor: Noizu.KitchenSink.Types.entity_reference,
                 created_on: integer,
                 modified_on: integer,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Entry.TagTable
  #-----------------------------------------------------------------------------
  deftable Entry.TagTable, [:article, :tag], type: :bag, index: [:tag] do
    @type t :: %Entry.TagTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 tag: atom,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Entry.VersionTable
  #-----------------------------------------------------------------------------
  deftable Entry.VersionTable, [:identifier, :entity], type: :set, index: [] do
    @type t :: %Entry.VersionTable{
                 identifier: integer, # {article, version}
                 entity: any,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Entry.VersionHistoryTable
  #-----------------------------------------------------------------------------
  deftable Entry.VersionHistoryTable, [:article, :version, :full_copy, :created_on, :article_version], type: :bag, index: [:version, :full_copy, :created_on, :editior] do
    @type t :: %Entry.VersionHistoryTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 version: integer,
                 full_copy: boolean,
                 created_on: integer,
                 editor: Noizu.KitchenSink.Types.entity_reference,
               }
  end # end deftable
end