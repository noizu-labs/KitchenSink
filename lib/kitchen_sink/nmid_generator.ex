defmodule Noizu.KitchenSink.NmidGenerator do
  @behaviour Noizu.Scaffolding.NmidBehaviour

  def generate(_seq, _opts \\ nil) do
    (:os.system_time(:millisecond) * 10_000) + :rand.uniform(5000)
  end

  def generate!(seq, opts \\ nil) do
    generate(seq, opts)
  end
end
