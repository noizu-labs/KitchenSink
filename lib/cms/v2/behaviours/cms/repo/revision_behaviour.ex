defmodule Noizu.Cms.V2.Cms.RevisionRepoBehaviour do
  @callback entity_revisions(entity :: any, context :: any, options :: any) :: any
  @callback active(ref :: any, context :: any, options :: any) :: any
  @callback delete_active(entity :: any, context :: any, options :: any) :: any
  @callback set_active(revision_ref :: any, version_ref :: any, context :: any, options :: any) :: any
  @callback version_revisions(version :: any, context :: any, options :: any) :: any
  @callback change_set(entity :: any, options :: any) :: any
  @callback new(options :: any) :: any
  @callback is_revision(ref :: any) :: any

  @callback revision_create(article :: any, version :: any, context :: any, options :: any, cms :: any) :: any


  @callback mnesia_delete(identifier :: any) :: any
  @callback mnesia_delete!(identifier :: any) :: any
  @callback mnesia_read(identifier :: any) :: any
  @callback mnesia_read!(identifier :: any) :: any
  @callback mnesia_write(identifier :: any) :: any
  @callback mnesia_write!(identifier :: any) :: any
  @callback mnesia_match(m :: any) :: any
  @callback mnesia_match!(m :: any) :: any
end
