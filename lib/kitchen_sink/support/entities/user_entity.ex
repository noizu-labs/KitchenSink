#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.KitchenSink.Support.UserEntity do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: integer,
               name: String.t,
               vsn: float
             }

  defstruct [
    identifier: nil,
    name: "Test User",
    vsn: @vsn
  ]

  use Noizu.Scaffolding.EntityBehaviour,
      sref_module: "test-user",
      mnesia_table: Noizu.KitchenSink.Database.Support.UserTable

  #=============================================================================
  # has_permission - cast|info
  #=============================================================================
  def has_permission(_ref, _permission, context, _options), do: context.auth[:permissions][:admin] || context.auth[:permissions][:system] || false
  def has_permission!(ref, permission, context, options), do: has_permission(ref, permission, context, options)
end # end defmodule SolaceBackend.Cms.PostEntity