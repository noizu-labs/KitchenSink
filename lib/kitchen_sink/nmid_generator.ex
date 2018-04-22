defmodule Noizu.KitchenSink.NmidGenerator do
  @behaviour Noizu.Scaffolding.NmidBehaviour

  def generate(seq, opts \\ nil) do
    :os.system_time(:millisecond)
  end

  def generate!(seq, opts \\ nil) do
    :os.system_time(:millisecond)
  end
end
