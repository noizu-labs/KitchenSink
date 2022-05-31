defmodule Noizu.Testing.Mnesia do
  defmodule Emulator do
    use Agent
    @initial_state  %{tables: %{}, event: 0, history: []}
    @blank_table %{records: %{}, history: []}
    @blank_record %{record: nil, history: []}
    #-----------------------------
    # Handle
    #-----------------------------
    defp emulator_handle(nil), do: __MODULE__
    defp emulator_handle(:default), do: __MODULE__
    defp emulator_handle(instance), do: :"#{__MODULE__}.#{instance}"

    #-----------------------------
    # Start Agent
    #-----------------------------
    def start_link(instance \\ :default), do: Agent.start_link(fn() -> @initial_state end, name: emulator_handle(instance))

    #-----------------------------
    # Internal State Manipulation
    #-----------------------------
    def __emulator__(instance \\ :default), do: Agent.get(emulator_handle(instance), &(&1))
    def __table__(table, instance \\ :default), do: Agent.get(emulator_handle(instance), &(&1.tables[table]))
    def __record__(table, key, instance \\ :default), do: Agent.get(emulator_handle(instance), &(&1.tables[table][key]))
    def __history__(instance \\ :default), do: Agent.get(emulator_handle(instance), &(&1.history))
    def __table_history__(table, instance \\ :default), do: Agent.get(emulator_handle(instance), &(&1.tables[table][:history]))
    def __record_history__(table, key, instance \\ :default), do: Agent.get(emulator_handle(instance), &(&1.tables[table][key][:history]))

    #-----------------------------
    #
    #-----------------------------
    def write(table, key, record, instance \\ :default) do
      Agent.update(emulator_handle(instance), fn(state) ->
        event = state.event + 1
        state
        |> put_in([:event], event)
        |> update_in([:history], &(&1 ++ [{event, {:write, {table, key}}}]))
        |> update_in([:tables, table], &(&1 || @blank_table))
        |> update_in([:tables, table, :records, key], &(&1 || @blank_record))
        |> update_in([:tables, table, :history], &(&1 ++ [{event, {:write, key}}]))
        |> update_in([:tables, table, :records, key, :history], &(&1 ++ [{event, {:write, record}}]))
        |> put_in([:tables, table, :records, key, :record], record)
      end)
      record
    end

    #-----------------------------
    #
    #-----------------------------
    def write_bag(table, key, record, instance \\ :default) do
      Agent.update(emulator_handle(instance), fn(state) ->
        event = state.event + 1
        state
        |> put_in([:event], event)
        |> update_in([:history], &(&1 ++ [{event, {:write, {table, key}}}]))
        |> update_in([:tables, table], &(&1 || @blank_table))
        |> update_in([:tables, table, :records, key], &(&1 || @blank_record))
        |> update_in([:tables, table, :history], &(&1 ++ [{event, {:write, key}}]))
        |> update_in([:tables, table, :records, key, :history], &(&1 ++ [{event, {:write, record}}]))
        |> update_in([:tables, table, :records, key, :record], &(Enum.uniq((&1 || []) ++ [record])))
      end)
      record
    end

    #-----------------------------
    #
    #-----------------------------
    def delete(table, key, instance \\ :default) do
      Agent.update(emulator_handle(instance), fn(state) ->
        event = state.event + 1
        state
        |> put_in([:event], event)
        |> update_in([:history], &(&1 ++ [{event, {:delete, {table, key}}}]))
        |> update_in([:tables, table], &(&1 || @blank_table))
        |> update_in([:tables, table, :records, key], &(&1 || @blank_record))
        |> update_in([:tables, table, :history], &(&1 ++ [{event, {:delete, key}}]))
        |> update_in([:tables, table, :records, key, :history], &(&1 ++ [{event, :delete}]))
        |> put_in([:tables, table, :records, key, :record], nil)
      end)
    end

    #-----------------------------
    #
    #-----------------------------
    def reset(instance \\ :default), do: Agent.update(emulator_handle(instance), fn(_) -> @initial_state end)

    #-----------------------------
    #
    #-----------------------------
    def get(table, key, default, instance \\ :default) do
      Agent.get(emulator_handle(instance), fn(state) ->
        cond do
          state.tables[table][:records][key] -> state.tables[table][:records][key].record
          :else ->
            case default do
              {:mock, v} -> v
              {:mock_mfa, {m,f,a}} when is_list(a) -> apply(m, f, [key, {table, {instance, nil}}] ++ a)
              {:mock_mfa, {m,f,a}} -> apply(m, f, [key, {table, {instance, nil}}, a])
              {:mock_mfa, {m,f}} -> apply(m, f, [key, {table, {instance, nil}}])
              v when is_list(v) -> v
              v when is_function(v, 0) -> v.()
              v when is_function(v, 1) -> v.(key)
              v when is_function(v, 2) -> v.(key, {table, {instance, nil}})
              v -> v
            end
        end
      end)
    end

    #-----------------------------
    #
    #-----------------------------
    def match(table, pattern, instance \\ :default) do
      values = Agent.get(emulator_handle(instance), fn(state) ->
        (state.tables[table][:records] || [])
        |> Enum.filter(&( partial_compare( elem(&1, 1).record, pattern)))
        |> Enum.map(&(table.coerce(elem(&1,1).record)))
      end)
      %Amnesia.Table.Select{values: values, coerce: table}
    end

    #-----------------------------
    #
    #-----------------------------
    def partial_compare(_, :_), do: true
    def partial_compare(v, p) when is_atom(p) do
      cond do
        v == p -> true
        String.starts_with?(Atom.to_string(p), "$") -> true
        :else -> false
      end
    end
    def partial_compare(v, p) when is_tuple(p) do
      cond do
        v == p -> true
        !is_tuple(v) -> false
        tuple_size(v) != tuple_size(p) -> false
        :else ->
          vl = Tuple.to_list(v)
          pl = Tuple.to_list(p)
          Enum.reduce(1..tuple_size(v), true, fn(i,a) ->
            a && partial_compare(Enum.at(vl, i), Enum.at(pl, i))
          end)
      end
    end
    def partial_compare(v, p) when is_list(p) and is_list(v) do
      cond do
        length(v) != length(p) -> false
        v == p -> true
        :else ->
          Enum.reduce(1..length(v), true, fn(i,a) ->
            a && partial_compare(Enum.at(v, i), Enum.at(p, i))
          end)
      end
    end
    def partial_compare(v, p) when is_list(p) and is_map(v) do
      Enum.reduce(p, true, fn({f,fp},a) ->
        cond do
          !a -> a
          !Map.has_key?(v, f) -> false
          v = partial_compare(Map.get(v, f), fp) -> v
          :else -> false
        end
      end)
    end
    def partial_compare(v, p) when is_map(p) and is_map(v) do
      Enum.reduce(p, true, fn({f,fp},a) ->
        cond do
          !a -> a
          !Map.has_key?(v, f) -> false
          v = partial_compare(Map.get(v, f), fp) -> v
          :else -> false
        end
      end)
    end
    def partial_compare(v, p) do
      v == p
    end
  end

  defmodule TableMocker do
    alias Noizu.Testing.Mnesia.Emulator, as: MockDB

    #--------------------
    #
    #--------------------
    def config(table, scenario \\ :default, settings \\ []) do
      mock_configuration = {table, {scenario, settings}}
      [
        read: fn(key) -> read(mock_configuration, key) end,
        read!: fn(key) -> read!(mock_configuration, key) end,
        write: fn(record) -> write(mock_configuration, record) end,
        write!: fn(record) -> write!(mock_configuration, record) end,
        delete: fn(record) -> delete(mock_configuration, record) end,
        delete!: fn(record) -> delete!(mock_configuration, record) end,
        match: fn(selector) -> match(mock_configuration, selector) end,
        match!: fn(selector) -> match!(mock_configuration, selector) end,
      ]
    end

    #--------------------
    #
    #--------------------
    def __mock_stubbed__(selector, {_table, {scenario, settings}} = _mock_configuration) do
      cond do
        Map.has_key?(settings[:scenario][scenario][:stubbed] || %{}, selector) -> settings[:scenario][scenario][:stubbed][selector]
        Map.has_key?(settings[:stubbed] || %{}, selector) -> settings[:stubbed][selector]
        settings[:catch_all][:stubbed] -> settings[:catch_all][:stubbed]
        settings[:bypass][:stubbed] -> nil
        provider = settings[:extended] -> &provider.__mock_stubbed__/2
        :else -> nil
      end
    end

    #--------------------
    #
    #--------------------
    def __mock_override_match__(selector, {_table, {scenario, settings}} = _mock_configuration) do
      cond do
        Map.has_key?(settings[:scenario][scenario][:override_match] || %{}, selector) -> settings[:scenario][scenario][:override_match][selector]
        Map.has_key?(settings[:override_match] || %{}, selector) -> settings[:override_match][selector]
        settings[:catch_all][:override_match] -> settings[:catch_all][:override_match]
        settings[:bypass][:override_match] -> nil
        provider = settings[:extended] -> &provider.__mock_override_match__/2
        :else -> nil
      end
    end

    #--------------------
    #
    #--------------------
    def read(mock_configuration, key), do: read!(mock_configuration, key)
    def read!({table, {scenario, _settings}} = mock_configuration, key) do
      default_value = __mock_stubbed__(key, mock_configuration)
      MockDB.get(table, key, default_value, scenario)
    end

    #--------------------
    #
    #--------------------
    def write(mock_configuration, record) do
      write!(mock_configuration, record)
    end
    def write!({table, {scenario, settings}} = _mock_configuration, record) do
      key_field = (settings[:key] || List.first(table.info(:attributes)))
      key = get_in(record, [Access.key(key_field)])
      cond do
        settings[:type] == :bag -> MockDB.write_bag(table, key, record, scenario)
        settings[:type] in [:set, :ordered_set] -> MockDB.write(table, key, record, scenario)
        table.properties()[:type] == :bag -> MockDB.write_bag(table, key, record, scenario)
        :else -> MockDB.write(table, key, record, scenario)
      end
    end

    #--------------------
    #
    #--------------------
    def delete(mock_configuration, record) do
      delete!(mock_configuration, record)
    end
    def delete!({table, {scenario, _settings}} = _mock_configuration, key) do
      MockDB.delete(table, key, scenario)
    end

    #--------------------
    #
    #--------------------
    def match(mock_configuration, selector) do
      match!(mock_configuration, selector)
    end
    def match!({table, {scenario, _settings}} = mock_configuration, selector) do
      response = case __mock_override_match__(selector, mock_configuration) do
                   nil -> MockDB.match(table, selector, scenario)
                   false -> MockDB.match(table, selector, scenario)
                   :auto -> MockDB.match(table, selector, scenario)
                   {:filter, v} -> Enum.filter(v, &(MockDB.partial_compare(&1.record, selector)))
                   {:mock, v} -> v
                   {:mock_mfa, {m,f,a}} when is_list(a) -> apply(m, f, [selector, mock_configuration] ++ a) || MockDB.match(table, selector, scenario)
                   {:mock_mfa, {m,f,a}} -> apply(m, f, [selector, mock_configuration, a]) || MockDB.match(table, selector, scenario)
                   {:mock_mfa, {m,f}} -> apply(m, f, [selector, mock_configuration]) || MockDB.match(table, selector, scenario)
                   v when is_list(v) -> v
                   v when is_function(v, 0) -> v.() || MockDB.match(table, selector, scenario)
                   v when is_function(v, 1) -> v.(selector) || MockDB.match(table, selector, scenario)
                   v when is_function(v, 2) -> v.(selector, mock_configuration) || MockDB.match(table, selector, scenario)
                   v -> v
                 end

      cond do
        is_list(response) -> %Amnesia.Table.Select{values: Enum.map(response, &(table.coerce(&1))), coerce: table}
        :else -> response
      end
    end



    #=====================================================================
    #
    #=====================================================================
    defmacro customize(options \\ [], [do: block]) do
      options = Macro.expand(options, __ENV__)
      quote do
        alias Noizu.Testing.Mnesia.TableMocker, as: MockDBTable
        #--------------------
        #
        #--------------------
        def config(scenario \\ :default, settings \\ nil) do
          settings = settings || __mock_option__(:default_config_settings)
          settings = cond do
                       settings[:extended] == nil -> put_in(settings, [:extended], __MODULE__)
                       :else -> settings
                     end
          mock_configuration = {__mock_option__(:table), {scenario, settings}}
          [
            read: fn(key) -> read(mock_configuration, key) end,
            read!: fn(key) -> read!(mock_configuration, key) end,
            write: fn(record) -> write(mock_configuration, record) end,
            write!: fn(record) -> write!(mock_configuration, record) end,
            delete: fn(record) -> delete(mock_configuration, record) end,
            delete!: fn(record) -> delete!(mock_configuration, record) end,
            match: fn(selector) -> match(mock_configuration, selector) end,
            match!: fn(selector) -> match!(mock_configuration, selector) end,
          ]
        end

        def write(mock_configuration, record), do: MockDBTable.write(mock_configuration, record)
        def write!(mock_configuration, record), do: MockDBTable.write!(mock_configuration, record)

        def read(mock_configuration, key), do: MockDBTable.read(mock_configuration, key)
        def read!(mock_configuration, key), do: MockDBTable.read!(mock_configuration, key)

        def delete(mock_configuration, key), do: MockDBTable.delete(mock_configuration, key)
        def delete!(mock_configuration, key), do: MockDBTable.delete!(mock_configuration, key)

        def match(mock_configuration, selector), do: MockDBTable.match(mock_configuration, selector)
        def match!(mock_configuration, selector), do: MockDBTable.match!(mock_configuration, selector)

        defoverridable [
          config: 0,
          config: 1,
          config: 2,
          write: 2,
          write!: 2,
          read: 2,
          read!: 2,
          delete: 2,
          delete!: 2,
          match: 2,
          match!: 2
        ]

        #===========================================================
        #===========================================================
        # inject user's inner logic/annotations.
        #===========================================================
        #===========================================================
        unquote(block)


        #===========================================================
        # annotation dependend methods, can be overriden by caller by adding overrides after Noizu.Testing.Mnesia.mock_table() do .. end section
        #===========================================================
        base = Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat()
        base_open = Module.open?(base)
        mock_table = cond do
                       o = unquote(options[:table]) -> o
                       Module.has_attribute?(__MODULE__, :table) -> Module.get_attribute(__MODULE__, :table)
                       base_open && Module.has_attribute?(base, :table) -> Module.get_attribute(base, :table)
                       !base_open && Kernel.function_exported?(base, :__mock_option__, 1) -> base.__mock_option__(:table)
                       :else -> raise "#{__MODULE__} must specify @table attribute or pass in table being mocked"
                     end
        stubbed = cond do
                    o = unquote(options[:stubbed]) -> o
                    Module.has_attribute?(__MODULE__, :stubbed) -> Module.get_attribute(__MODULE__, :stubbed)
                    base_open && Module.has_attribute?(base, :stubbed) -> Module.get_attribute(base, :stubbed)
                    !base_open && Kernel.function_exported?(base, :__mock_option__, 1) -> base.__mock_option__(:stubbed)
                    :else -> %{}
                  end
        override_match = cond do
                           o = unquote(options[:override_match]) -> o
                           Module.has_attribute?(__MODULE__, :override_match) -> Module.get_attribute(__MODULE__, :override_match)
                           base_open && Module.has_attribute?(base, :override_match) -> Module.get_attribute(base, :override_match)
                           !base_open && Kernel.function_exported?(base, :__mock_option__, 1) -> base.__mock_option__(:override_match)
                           :else -> %{}
                         end
        default_config_settings = cond do
                           o = unquote(options[:default_config_settings]) -> o
                           Module.has_attribute?(__MODULE__, :default_config_settings) -> Module.get_attribute(__MODULE__, :default_config_settings)
                           base_open && Module.has_attribute?(base, :default_config_settings) -> Module.get_attribute(base, :default_config_settings)
                           !base_open && Kernel.function_exported?(base, :__mock_option__, 1) -> base.__mock_option__(:default_config_settings)
                           :else -> []
                         end || []

        @mock_table mock_table
        @stubbed stubbed
        @override_match override_match
        @default_config_settings default_config_settings

        #--------------------
        #
        #--------------------
        def __mock_option__(:table), do: @mock_table
        def __mock_option__(:stubbed), do: @stubbed
        def __mock_option__(:override_match), do: @override_match
        def __mock_option__(:default_config_settings), do: @default_config_settings

        #--------------------
        #
        #--------------------
        def __mock_stubbed__(selector, _mock_configuration), do: __mock_option__(:stubbed)[selector]

        #--------------------
        #
        #--------------------
        def __mock_override_match__(selector, _mock_configuration), do: __mock_option__(:override_match)[selector]

        defoverridable [
          __mock_option__: 1,
          __mock_stubbed__: 2,
          __mock_override_match__: 2,
        ]
      end
    end
  end
end
