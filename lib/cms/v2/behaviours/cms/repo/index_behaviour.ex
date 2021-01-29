defmodule Noizu.Cms.V2.Cms.IndexRepoBehaviour do

  @callback new(options :: any) :: any
  @callback change_set(entity :: any, options :: any) :: any
  @callback by_created_on(from :: any, to :: any, context :: any, options :: any) :: any
  @callback by_created_on!(from :: any, to :: any, context :: any, options :: any) :: any
  @callback by_modified_on(from :: any, to :: any, context :: any, options :: any) :: any
  @callback by_modified_on!(from :: any, to :: any, context :: any, options :: any) :: any

  @callback mnesia_delete(identifier :: any) :: any
  @callback mnesia_delete!(identifier :: any) :: any
  @callback mnesia_read(identifier :: any) :: any
  @callback mnesia_read!(identifier :: any) :: any
  @callback mnesia_write(identifier :: any) :: any
  @callback mnesia_write!(identifier :: any) :: any
  @callback mnesia_match(m :: any) :: any
  @callback mnesia_match!(m :: any) :: any
end
