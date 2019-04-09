#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersioningProviderBehaviour do
  @callback assign_new_version(any, any, any) :: any
  @callback assign_new_version!(any, any, any) :: any

  @callback assign_new_revision(any, any, any) :: any
  @callback assign_new_revision!(any, any, any) :: any

  @callback overwrite_revision(any, any, any) :: any
  @callback overwrite_revision!(any, any, any) :: any

  # change active revision . . .
  # change active version . . .

  @callback create_version(any, any, any) :: any
  @callback create_version!(any, any, any) :: any

  @callback update_version(any, any, any, any) :: any
  @callback update_version!(any, any, any, any) :: any

  @callback delete_version(any, any, any) :: any
  @callback delete_version!(any, any, any) :: any

  @callback create_revision(any, any, any, any) :: any
  @callback create_revision!(any, any, any, any) :: any

  @callback update_revision(any, any, any, any) :: any
  @callback update_revision!(any, any, any, any) :: any

  @callback delete_revision(any, any, any) :: any
  @callback delete_revision!(any, any, any) :: any

  @doc """
    Get versions for an entity.
  """
  @callback get_versions(any, any, any) :: any

  @doc """
    Get versions for an entity.
  """
  @callback get_versions!(any, any, any) :: any

  @doc """
    Get Revisions for an entity.
  """
  @callback get_revisions(any, any, any) :: any

  @doc """
    Get Revisions for an entity.
  """
  @callback get_revisions!(any, any, any) :: any

end