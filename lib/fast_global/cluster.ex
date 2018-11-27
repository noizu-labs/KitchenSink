#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.FastGlobal.Cluster do
  @vsn 1.0
  alias Noizu.FastGlobal.Record

  #-------------------
  # get
  #-------------------
  def get(identifier), do: get(identifier, nil, %{})
  def get(identifier, default), do: get(identifier, default, %{})
  def get(identifier, default, options) do
    case FastGlobal.get(identifier, :no_match) do
      %Record{value: v} -> v
      error -> error
    end
  end

  #-------------------
  # get_record/1
  #-------------------
  def get_record(identifier), do: FastGlobal.get(identifier)

  #-------------------
  # put/3
  #-------------------
  def put(identifier, value, options \\ %{})
  def put(identifier, %Record{} = record, _options) do
    FastGlobal.put(identifier, record)
  end
  def put(identifier, value, options) do
    settings = get(:fast_global_settings)
    origin = options[:origin] || settings[:origin]
    cond do
      origin == node() -> coordinate_put(identifier, value, options)
      origin == nil -> :error
      true -> :rpc.cast(origin, Noizu.SimplePool.FastGlobal.Cluster, :coordinate_put, [identifier, value, settings, options])
    end
  end

  #-------------------
  # coordinate_put
  #-------------------
  def coordinate_put(identifier, value, settings, options) do
    update = case get_record(identifier) do
      %Record{} = record ->
        pool = options[:pool] || settings[:pool] || []
        pool = ([node()] ++ pool) |> Enum.uniq()
        %Record{record| origin: node(), pool: pool, value: value, revision: record.revision + 1, ts: :os.system_time(:millisecond)}
      nil ->
        pool = options[:pool] || settings[:pool] || []
        pool = ([node()] ++ pool) |> Enum.uniq()
        %Record{identifier: identifier, origin: node(), pool: pool, value: value, revision: 1, ts: :os.system_time(:millisecond)}
    end

    Semaphore.call({:fg_update_record, identifier}, 1,
      fn() ->
        Enum.map(update.pool,
          fn(n) ->
            if n == node() do
              put(identifier, update, options)
            else
              :rpc.cast(n, Noizu.SimplePool.FastGlobal.Cluster, :put, [identifier, update, options])
            end
          end)
      end)
    :ok
  end
end
