# Default unlimited access.

defimpl Noizu.RestrictedProtocol, for: Any do
  def restricted_view(%{__struct__: kind} = entity, _context, _options), do: put_in(Map.from_struct(entity), [:kind], kind)
  def restricted_view(entity, _context, _options), do: entity
  def restricted_update(entity, _current, _context, _options), do: entity
  def restricted_create(entity, _context, _options), do: entity
end