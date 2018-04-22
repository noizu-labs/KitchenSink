defmodule Noizu.KitchenSink.AuditEngine do
  @behaviour Noizu.Scaffolding.AuditEngineBehaviour
  def audit(_event, _details, _entity, %Noizu.ElixirCore.CallingContext{} = _context, _options \\ nil, _note \\ nil) do
    :ok
  end

  def audit!(_event, _details, _entity, %Noizu.ElixirCore.CallingContext{} = _context, _options \\ nil, _note \\ nil) do
    :ok
  end
end