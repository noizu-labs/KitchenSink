#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.Cms.V2.Database do
  #-----------------------------------------------------------------------------
  # @ArticleTable
  #-----------------------------------------------------------------------------
  deftable ArticleTable, [:article, :status, :type, :editor, :created_on, :modified_on], type: :set, index: [:status, :type, :editor, :created_on, :modified_on] do
    @type t :: %ArticleTable{
                 identifier: Noizu.KitchenSink.Types.entity_reference,
                 status: :approved | :pending | :disabled | atom,
                 type: :post | :file | :image | atom | module,
                 editor: Noizu.KitchenSink.Types.entity_reference,
                 created_on: integer,
                 modified_on: integer,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Article.TagTable
  #-----------------------------------------------------------------------------
  deftable Article.TagTable, [:article, :tag], type: :bag, index: [:tag] do
    @type t :: %Article.TagTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 tag: atom,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Article.VersionTable
  #-----------------------------------------------------------------------------
  deftable Article.VersionTable, [:identifier, :entity], type: :set, index: [] do
    @type t :: %Article.VersionTable{
                 identifier: integer, # {article, version}
                 entity: any,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Article.VersionHistoryTable
  #-----------------------------------------------------------------------------
  deftable Article.VersionHistoryTable, [:article, :version, :full_copy, :created_on, :article_version], type: :bag, index: [:version, :full_copy, :created_on, :editior] do
    @type t :: %Article.VersionHistoryTable{
                 article: Noizu.KitchenSink.Types.entity_reference,
                 version: integer,
                 full_copy: boolean,
                 created_on: integer,
                 editor: Noizu.KitchenSink.Types.entity_reference,
               }
  end # end deftable
end