#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------
defmodule Noizu.Cms.V2.Article.Info do
  @vsn 1.0
  @type t :: %__MODULE__{
               article: tuple,

               created_on: DateTime.t,
               modified_on: DateTime.t,

               status: atom,

               type: atom,
               module: module,

               editor: any,

               name: String.t,
               description: Noizu.MarkdownField.t | nil,
               note: Noizu.MarkdownField.t | nil,

               version: any,
               parent: any,
               revision: any,

               tags: MapSet.t,

               vsn: float
             }

  defstruct [
    article: nil,

    created_on: nil,
    modified_on: nil,

    status: nil,

    type: nil,
    module: nil,

    editor: nil,

    name: nil,
    description: nil,
    note: nil,

    version: nil,
    parent: nil,
    revision: nil,

    tags: nil,

    vsn: @vsn
  ]

  def init(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> put_in([Access.key(:article)], Noizu.ERP.ref(entity))
                   |> update_in([Access.key(:created_on)], &(&1 || current_time))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> update_in([Access.key(:type)], &(&1 || Noizu.Cms.V2.Proto.type(entity, context, options)))
    entity
    |> Noizu.Cms.V2.Proto.set_article_info(article_info, context, options)
  end

  def init!(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_info = (Noizu.Cms.V2.Proto.get_article_info!(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> put_in([Access.key(:article)], Noizu.ERP.ref(entity))
                   |> update_in([Access.key(:created_on)], &(&1 || current_time))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> update_in([Access.key(:type)], &(&1 || Noizu.Cms.V2.Proto.type!(entity, context, options)))
    entity
    |> Noizu.Cms.V2.Proto.set_article_info!(article_info, context, options)
  end


  def update(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_ref = Noizu.Cms.V2.Proto.article_ref(entity, context, options)
    article_info = (Noizu.Cms.V2.Proto.get_article_info(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> update_in([Access.key(:article)], &(&1 || article_ref))
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
    entity
    |> Noizu.Cms.V2.Proto.set_article_info(article_info, context, options)
  end


  def update!(entity, context, options) do
    current_time = options[:current_time] || DateTime.utc_now()
    article_ref = Noizu.Cms.V2.Proto.article_ref!(entity, context, options)
    article_info = (Noizu.Cms.V2.Proto.get_article_info!(entity, context, options) || %Noizu.Cms.V2.Article.Info{})
    editor = options[:editor] || article_info.editor || context.caller
    status = options[:status] || article_info.status || :pending
    article_info = article_info
                   |> update_in([Access.key(:article)], &(&1 || article_ref))
                   |> update_in([Access.key(:module)], &(&1 || entity.__struct__))
                   |> put_in([Access.key(:modified_on)], current_time)
                   |> put_in([Access.key(:editor)], editor)
                   |> put_in([Access.key(:status)], status)
    entity
    |> Noizu.Cms.V2.Proto.set_article_info!(article_info, context, options)
  end


end # end defmodule
