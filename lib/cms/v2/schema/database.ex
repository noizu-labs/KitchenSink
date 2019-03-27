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

  #=============================================================================
  #=============================================================================
  # Versioning
  #=============================================================================
  #=============================================================================

  #-----------------------------------------------------------------------------
  # @VersionSequencerTable
  #-----------------------------------------------------------------------------
  deftable VersionSequencerTable, [:identifier, :sequence], type: :set, index: [] do
    @type t :: %VersionSequencerTable{
                 identifier: any, # version ref
                 sequence: any,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @VersionTable
  #-----------------------------------------------------------------------------
  deftable VersionTable, [:identifier, :created_on, :editor, :entity], type: :set, index: [:created_on, :editor] do
    @type t :: %VersionTable{
                 identifier: any, # {article ref, path tuple}
                 created_on: integer,
                 editor: tuple,
                 entity: any, # VersionEntity
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @VersionEditTable
  #-----------------------------------------------------------------------------
  deftable VersionEditTable, [:identifier, :entity], type: :set, index: [] do
    @type t :: %VersionEditTable{
                 identifier: any, # {version hash, edit}
                 entity: any,
               }
  end # end deftable

end