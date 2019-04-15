#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.VersioningProviderBehaviour do
  @callback initialize_versioning_records(any, any, any) :: any
  @callback populate_versioning_records(any, any, any) :: any

  @callback get_versions(any, any, any) :: any
  @callback get_versions!(any, any, any) :: any

  @callback get_revisions(any, any, any) :: any
  @callback get_revisions!(any, any, any) :: any

  @callback create_version(any, any, any) :: any
  @callback create_version!(any, any, any) :: any

  @callback update_version(any, any, any) :: any
  @callback update_version!(any, any, any) :: any

  @callback delete_version(any, any, any) :: any
  @callback delete_version!(any, any, any) :: any

  @callback create_revision(any, any, any) :: any
  @callback create_revision!(any, any, any) :: any

  @callback update_revision(any, any, any) :: any
  @callback update_revision!(any, any, any) :: any

  @callback delete_revision(any, any, any) :: any
  @callback delete_revision!(any, any, any) :: any
end