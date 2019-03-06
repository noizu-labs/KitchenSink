#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
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
  # @IndexTable
  #-----------------------------------------------------------------------------
  deftable IndexTable,
           [:article, :status, :module, :type, :editor, :created_on, :modified_on, :active_version],
           type: :set,
           index: [:status, :module, :type, :editor, :created_on, :modified_on] do
    @type t :: %IndexTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 status: :approved | :pending | :disabled | atom,
                 module: module,
                 type: :post | :file | :image | atom | module,
                 editor: Noizu.KitchenSink.Types.entity_reference,
                 created_on: integer,
                 modified_on: integer,
                 active_version: any,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @TagTable
  #-----------------------------------------------------------------------------
  deftable TagTable, [:article, :tag], type: :bag, index: [:tag] do
    @type t :: %TagTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 tag: atom,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @VersionTable
  #-----------------------------------------------------------------------------
  deftable VersionTable, [:identifier, :entity], type: :set, index: [] do
    @type t :: %VersionTable{
                 identifier: integer, # {article, version}
                 entity: any,
               }
  end # end deftable


  #-----------------------------------------------------------------------------
  # @VersionSequencerTable
  #-----------------------------------------------------------------------------
  deftable VersionSequenceTable, [:identifier, :next_in_sequence], type: :set, index: [] do
    @type t :: %VersionSequenceTable{
                 identifier: integer, # {article, version}
                 next_in_sequence: any,
               }
  end # end deftable


  #-----------------------------------------------------------------------------
  # @VersionSequencerTable
  #-----------------------------------------------------------------------------
  deftable VersionTreeTable, [:article, :tree], type: :set, index: [] do
    @type t :: %VersionTreeTable{
                 article: integer, # {article, version}
                 tree: any,
               }
  end # end deftable


  #-----------------------------------------------------------------------------
  # @VersionHistoryTable
  #-----------------------------------------------------------------------------
  deftable VersionHistoryTable, [:article, :version, :parent_version, :full_copy, :created_on, :editor],
           type: :bag,
           index: [:version, :parent_version, :full_copy, :created_on, :editor] do
    @type t :: %VersionHistoryTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 version: String.t,
                 parent_version: String.t | nil,
                 full_copy: boolean,
                 created_on: integer,
                 editor: any,
               }
  end # end deftable
end