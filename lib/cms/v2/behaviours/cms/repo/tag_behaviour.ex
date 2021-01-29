defmodule Noizu.Cms.V2.Cms.TagRepoBehaviour do
  @callback new(options :: any) :: any

  @callback mnesia_delete(identifier :: any) :: any
  @callback mnesia_delete!(identifier :: any) :: any
  @callback mnesia_read(identifier :: any) :: any
  @callback mnesia_read!(identifier :: any) :: any
  @callback mnesia_write(identifier :: any) :: any
  @callback mnesia_write!(identifier :: any) :: any
  @callback mnesia_match(m :: any) :: any
  @callback mnesia_match!(m :: any) :: any
end
