#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.TemplateRepo do
  use Noizu.Scaffolding.V2.RepoBehaviour,
      mnesia_table: Noizu.EmailService.Database.Email.TemplateTable

  require Logger


  #----------------------------
  # post_get_callback/3
  #----------------------------
  def post_get_callback(%{vsn: 1.1} = entity, _context, _options) do
    entity
  end
  def post_get_callback(%{vsn: vsn} = entity, context, options) do
    entity = update_version(entity, context, options)
    cond do
      entity.vsn != vsn -> update!(entity, Noizu.ElixirCore.Context.system(context), options)
      :else -> entity
    end
  end
  def post_get_callback(entity, _context, _options) do
    entity
  end

  #----------------------------
  # update_version/3
  #----------------------------
  def update_version(%{vsn: 1.0} = entity, _context, _options) do
    entity
    |> put_in([Access.key(:status)], :active)
    |> put_in([Access.key(:vsn)], 1.1)
  end

  def update_version(%{vsn: 1.1} = entity, _context, _options) do
    entity
  end

end