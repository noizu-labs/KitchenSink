#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

use Amnesia

defdatabase Noizu.Cms.Database do
  #-----------------------------------------------------------------------------
  # @PostTable
  #-----------------------------------------------------------------------------
  deftable PostTable, [:identifier, :status, :type, :editor, :entity], type: :set, index: [:status, :type, :editor] do
    @moduledoc """
    Cms
    """
    @type t :: %PostTable{
                 identifier: integer,
                 status: :approved | :pending | :disabled,
                 type: :post | :file | :image | any,
                 editor: Noizu.KitchenSink.Types.entity_reference,
                 entity: Noizu.Cms.PostEntity.t
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Post.TagTable
  #-----------------------------------------------------------------------------
  deftable Post.TagTable, [:post, :tag], type: :bag, index: [:tag] do
    @moduledoc """
    Cms Tag
    """
    @type t :: %Post.TagTable{
                 post: Noizu.KitchenSink.Types.entity_reference,
                 tag: atom,
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Post.VersionTable
  #-----------------------------------------------------------------------------
  deftable Post.VersionTable, [:identifier, :post, :version, :created_on, :editor, :entity], type: :set, index: [:post, :version, :created_on, :editor] do
    @moduledoc """
    Versions
    """
    @type t :: %Post.VersionTable{
                 identifier: integer,
                 post: Noizu.KitchenSink.Types.entity_reference,
                 version: integer,
                 created_on: Types.unix_epoch,
                 editor: Types.entity_reference,
                 entity: Noizu.Cms.Post.VersionEntity.t
               }
  end # end deftable

  #-----------------------------------------------------------------------------
  # @Post.VersionHistoryTable
  #-----------------------------------------------------------------------------
  deftable Post.VersionHistoryTable, [:identifier, :version, :created_on, :editor, :note, :post_version], type: :bag, index: [:version, :created_on, :editor, :note, :post_version] do
    @moduledoc """
    Version History
    """
    @type t :: %Post.VersionHistoryTable{
                 identifier: Noizu.KitchenSink.Types.entity_reference,
                 version: integer,
                 created_on: integer,
                 editor: Noizu.KitchenSink.Types.entity_reference,
                 note: String.t,
                 post_version: Noizu.KitchenSink.Types.entity_reference
               }
  end # end deftable
end