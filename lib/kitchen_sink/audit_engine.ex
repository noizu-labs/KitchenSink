defmodule Noizu.KitchenSink.AuditEngine do
  @behaviour Noizu.Scaffolding.AuditEngineBehaviour
  def audit(event, details, entity, %Noizu.ElixirCore.CallingContext{} = context, _options \\ nil, note \\ nil) do
    :ok
  end

  def audit!(event, details, entity, %Noizu.ElixirCore.CallingContext{} = context, options \\ nil, note \\ nil) do
    :ok
  end
end