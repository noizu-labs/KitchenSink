defmodule Noizu.Cms.V2.Cms.VersionRepoBehaviour do

  @callback entity_versions(entity :: any, context :: any, options :: any) :: any
  @callback change_set(entity :: any, options :: any) :: any

  @callback new(options :: any) :: any
  @callback is_version(ref :: any) :: any

  @callback version_create(article :: any,  current_version :: any, context :: any, options :: any, cms :: any) :: any

  @callback mnesia_delete(identifier :: any) :: any
  @callback mnesia_delete!(identifier :: any) :: any
  @callback mnesia_read(identifier :: any) :: any
  @callback mnesia_read!(identifier :: any) :: any
  @callback mnesia_write(identifier :: any) :: any
  @callback mnesia_write!(identifier :: any) :: any
  @callback mnesia_match(m :: any) :: any
  @callback mnesia_match!(m :: any) :: any
end
