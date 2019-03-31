defmodule Noizu.Support.Cms.V2.Database.MnesiaEmulator do
  use Agent

  def start_link() do
    initial_state = %{tables: %{}}
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get_state() do
    Agent.get(__MODULE__, fn(state) ->
      state
    end)
  end

  def get_state_table(table) do
    Agent.get(__MODULE__, fn(state) ->
      cond do
        state.tables[table] -> state.tables[table]
        true -> nil
      end
    end)
  end

  def get_state_record(table, key) do
    Agent.get(__MODULE__, fn(state) ->
      cond do
        state.tables[table][key] -> state.tables[table][key]
        true -> nil
      end
    end)
  end

  def write(table, key, record) do
    Agent.update(__MODULE__, fn(state) ->

      state = cond do
        state.tables[table][key] -> state
        state.tables[table] -> put_in(state, [:tables, table, key], %{history: [], record: nil})
        true ->
          state
          |> put_in([:tables, table], %{history: []})
          |> put_in([:tables, table, key], %{history: [], record: nil})
      end

      state
      |> update_in([:tables, table, :history], &(&1 ++ [{:write, key}]))
      |> update_in([:tables, table, key, :history], &(&1 ++ [{:write, record}]))
      |> put_in([:tables, table, key, :record], record)
    end)
    record
  end


  def write_bag(table, key, record) do
    Agent.update(__MODULE__, fn(state) ->

      state = cond do
        state.tables[table][key] -> state
        state.tables[table] -> put_in(state, [:tables, table, key], %{history: [], record: nil})
        true ->
          state
          |> put_in([:tables, table], %{history: []})
          |> put_in([:tables, table, key], %{history: [], record: nil})
      end

      state
      |> update_in([:tables, table, :history], &(&1 ++ [{:write, key}]))
      |> update_in([:tables, table, key, :history], &(&1 ++ [{:write, record}]))
      |> update_in([:tables, table, key, :record], &(Enum.uniq((&1 || []) ++ [record])))
    end)
    record
  end

  def delete(table, key) do
    Agent.update(__MODULE__, fn(state) ->

      state = cond do
        state.tables[table][key] -> state
        state.tables[table] -> put_in(state, [:tables, table, key], %{history: [], record: nil})
        true ->
          state
          |> put_in([:tables, table], %{history: []})
          |> put_in([:tables, table, key], %{history: [], record: nil})
      end

      state
      |> update_in([:tables, table, :history], &(&1 ++ [{:delete, key}]))
      |> update_in([:tables, table, key, :history], &(&1 ++ [:delete]))
      |> put_in([:tables, table, key, :record], nil)
    end)
  end

  def get(table, key, default) do
    Agent.get(__MODULE__, fn(state) ->
      cond do
        state.tables[table][key] -> state.tables[table][key].record
        true -> default
      end
    end)
  end

  def table_history(table) do
    Agent.get(__MODULE__, fn(state) ->
      cond do
        state.tables[table] -> state.tables[table].history
        true -> nil
      end
    end)
  end

  def record_history(table, key) do
    Agent.get(__MODULE__, fn(state) ->
      cond do
        state.tables[table][key] -> state.tables[table][key].history
        true -> nil
      end
    end)
  end

  def reset() do
    Agent.update(__MODULE__, fn(_) ->
      %{tables: %{}}
    end)
  end

end