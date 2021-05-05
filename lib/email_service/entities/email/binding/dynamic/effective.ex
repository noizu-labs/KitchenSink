#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Effective do
  @vsn 1.0
  alias Noizu.EmailService.Email.Binding.Dynamic.Selector
  alias Noizu.EmailService.Email.Binding.Dynamic.Section
  alias Noizu.EmailService.Email.Binding.Dynamic.Formula
  @type t :: %__MODULE__{
               bind: [Selector.t],
               bound: Map.t,
               unbound: %{:optional => [Selector.t], :required => [Selector.t]},
               meta: Map.t,
               vsn: float,
             }

  defstruct [
    bind: [],
    bound: %{},
    unbound: %{
      optional: [],
      required: []
    },
    meta: %{},
    vsn: @vsn
  ]



  def insert_path(blob, path, selector, acc \\ [])
  def insert_path(blob, [h], selector, p) do
    p = p ++ [h]
    block = update_in(blob, p, &(&1 || %{type: :trace, index_size: 0, selector: nil, children: %{}}))

    # Track indexes
    blob = case h do
             {:at, v} ->
               parent_index_size_path = Enum.slice(p, 0 .. -3) ++ [:index_size]
               index_size = get_in(blob, parent_index_size_path)
               cond do
                 v + 1 >= index_size -> put_in(blob, parent_index_size_path, v + 1)
                 :else -> blob
               end
             _else -> blob
           end

    # set to copy if terminal full value insert, or scalar if existence check value that doesnt require full body to be included in payload.
    type = get_in(block, p ++ [:type])
    scalar? = Selector.scalar?(selector)
    cond do
      type == :copy -> block
      scalar? ->
        block
        |> put_in(p ++ [:type], :scalar)
        |> put_in(p ++ [:selector], selector)
      :else ->
        block
        |> put_in(p ++ [:type], :copy)
        |> put_in(p ++ [:selector], selector)
    end
  end
  def insert_path(blob, [h|t], selector, p) do
    p = p ++ [h]
    blob = update_in(blob, p, &(&1 || %{type: :trace, index_size: 0, selector: nil, children: %{}}))

    # Track indexes
    blob = case h do
             {:at, v} ->
               parent_index_size_path = Enum.slice(p, 0 .. -3) ++ [:index_size]
               index_size = get_in(blob, parent_index_size_path)
               cond do
                 v + 1 >= index_size -> put_in(blob, parent_index_size_path, v + 1)
                 :else -> blob
               end
             _else -> blob
           end

    insert_path(blob, t, selector, p ++ [:children])
  end

  #----------------------
  # interstitial_map
  #----------------------
  def interstitial_map(%__MODULE__{} = this, state, context, options) do
    bind = this.bind
           |> Enum.uniq()
           |> Enum.sort_by(&(&1.selector < &1.selector))

    book_keeping = Enum.reduce(bind, %{}, fn(selector, acc) ->
      path = Selector.path(selector)
      insert_path(acc, path, selector)
    end)
  end

  def build_output(v = %{}, state, context, options) do
    Enum.reduce(v, {%{}, state}, fn({k,v}, {acc, s}) ->
      {snippet, s} = build_output_inner({k,v}, %{}, s, context, options)
      case snippet do
        {:value, value} ->
          case k do
            {:select, name} -> {put_in(acc, [name], value), s}
          end
        _else -> {acc, s}
      end
    end)
  end

  defp build_output_inner({k,v}, blob, state, context, options) do
    cond do
      v.type == :copy ->
        {value, s} = Noizu.RuleEngine.ScriptProtocol.execute!(v.selector, state, context, options)
        case value do
          {:value, nil} ->
            # consider a copy field a non-result to force required bind error.
            {nil, s}
          _ -> {value, s}
        end
      v.type == :scalar ->
        {value, s} = Noizu.RuleEngine.ScriptProtocol.execute!(v.selector, state, context, options)
        case value do
          {:value, value} ->
            cond do
              value == nil -> {{:value, value}, s} # path existed e.g. map.key but response was null, so we may include in result. If no value was returned we return nil to avoid improperly triggering
              # conditionals higher in the formula tree.
              is_integer(value) || is_float(value) || is_atom(value) -> {{:value, value}, s}
              is_map(value) || is_list(value) || is_tuple(value) -> {{:value, true}, s}
              :else -> {{:value, value}, s}
            end
          _else -> {nil, s}
        end
      v.type == :trace ->
        # Tentative mode
        cond do
          v.index_size == 0 ->
            snippet = %{}
            {snippet, state} = Enum.reduce(v.children, {snippet, state}, fn({k2,v2}, {acc_snippet, acc_state}) ->
              {sv, s} = build_output_inner({k2, v2}, acc_snippet, acc_state, context, options)
              case sv do
                {:value, value} ->
                  case k2 do
                    {:key, name} -> {put_in(acc_snippet, [name], value), s}
                    {:select, name} -> {put_in(acc_snippet, [name], value), s}
                  end
                _else -> {acc_snippet, s}
              end
            end)
            cond do
              snippet == %{} -> {nil, state} # value never reached, leave path barren (e.g. path ended in a scalar request that was nil)
              :else -> {{:value, snippet}, state}
            end
          :else ->
            snippet = Enum.map(0.. v.index_size - 1, fn(_) -> nil end)
            {hit?, snippet, state} = Enum.reduce(v.children, {false, snippet, state}, fn({k2,v2}, {acc_hit?, acc_snippet, acc_state}) ->
              {sv, s} = build_output_inner({k2, v2}, acc_snippet, acc_state, context, options)
              case sv do
                {:value, value} ->
                  case k2 do
                    {:at, index} -> {true, put_in(acc_snippet, [Access.at(index)], value), s}
                  end
                _else -> {acc_hit?, acc_snippet, s}
              end
            end)
            cond do
              !hit? -> {nil, state} # value never reached, leave path barren (e.g. path ended in a scalar request that was nil)
              :else -> {{:value, snippet}, state}
            end
        end
    end
  end

  #----------------------
  #
  #----------------------
  def finalize(%__MODULE__{} = this, state, context, options) do
    book_keeping = interstitial_map(this, state, context, options)
    {output, state} = build_output(book_keeping, state, context, options)
    this = %__MODULE__{this| bound: output}

    # now walk through binds to verify all non scalars are bound.
    this = Enum.reduce(this.bind, this, fn(selector,this) ->
      # only require non scalars.
      cond do
        Selector.is_bound?(selector, output, state, context, options) -> this
        Selector.scalar?(selector) -> update_in(this, [Access.key(:unbound), Access.key(:optional)], &((&1 || []) ++ [selector]))
        :else -> update_in(this, [Access.key(:unbound), Access.key(:required)], &((&1 || []) ++ [selector]))
      end
    end)

    {this, state}
  end

  #----------------------
  #
  #----------------------
  def new(%Section{} = section, state, context, options) do
    {%__MODULE__{bind:  Enum.uniq(section.bind)}, state}
  end

  def new(%Formula.IfThen{condition_clause: formula} = section, state, context, options) do
    selectors = Formula.selectors(formula)
                |> Enum.map(&(Selector.exists(&1)))
                |> Enum.uniq()
    {%__MODULE__{bind: selectors}, state}
  end

  def new(%Formula.Each{} = section, state, context, options) do
    {%__MODULE__{}, state}
  end

  def new(bind, state, context, options) when is_list(bind) do
    bind =  bind
            |> Enum.uniq()
    {%__MODULE__{bind: bind}, state}
  end

  def new(nil, state, context, options) do
    {%__MODULE__{bind: []}, state}
  end

  #----------------------
  #
  #----------------------
  def set_wildcard_hint(%__MODULE__{} = this, %Selector{} = selector, :list, {index, value}, state, context, options) do
    {r,s} = Noizu.RuleEngine.StateProtocol.get!(state, :wildcards, context)
    r = put_in(r || %{}, [selector.selector], %{index: index, value: value, type: :list})
    s = Noizu.RuleEngine.StateProtocol.put!(s, :wildcards, r, context)
    this = put_in(this, [Access.key(:meta), :wildcard], {selector.selector, Selector.set_wildcard_hint(selector, {:at, index})})
    {this, s}
  end

  #----------------------
  #
  #----------------------
  def set_wildcard_hint(%__MODULE__{} = this, %Selector{} = selector, :kv, {key, value}, state, context, options) do
    {r,s} = Noizu.RuleEngine.StateProtocol.get!(state, :wildcards, context)
    r = put_in(r || %{}, [selector.selector], %{key: key, value: value, type: :kv})
    s = Noizu.RuleEngine.StateProtocol.put!(s, :wildcards, r, context)
    s = Noizu.RuleEngine.StateProtocol.put!(s, :last_wildcard,  {selector.selector, Selector.set_wildcard_hint(selector, {:key, key})}, context)
    this = put_in(this, [Access.key(:meta), :wildcard], {selector.selector, Selector.set_wildcard_hint(selector, {:key, key})})
    {this, s}
  end

  #----------------------
  #
  #----------------------
  def clear_wildcard_hint(%__MODULE__{} = this, %Selector{} = selector, _type, state, context, options) do
    {r,s} = Noizu.RuleEngine.StateProtocol.get!(state, :wildcards, context)
    r = Map.delete(r || %{}, selector.selector)
    s = Noizu.RuleEngine.StateProtocol.put!(s, :wildcards, r, context)
    {_, this} = pop_in(this, [Access.key(:meta), :wildcard])
    {this, s}
  end

  #----------------------
  #
  #----------------------
  def merge(%__MODULE__{} = bind_a, %__MODULE__{} = bind_b, state, context, options) do
    r = cond do
          bind_a.meta[:wildcard] ->
            {ws,wr} = bind_a.meta[:wildcard]
            wsl = length(ws)
            r = Enum.map(bind_b.bind || [], fn(b_s) ->
              cond do
                List.starts_with?(b_s.selector, ws) ->
                  s = b_s.selector
                  s = wr.selector ++ Enum.slice(s, wsl .. -1)
                  %Selector{b_s| selector: s}
                :else -> b_s
              end
            end)
          :else -> bind_b.bind
        end |> Enum.uniq

    {%__MODULE__{bind_a| bind: Enum.uniq(bind_a.bind ++ r)}, state}
  end
  def merge(%__MODULE__{} = bind_a, nil, state, context, options), do: {bind_a, state}
  def merge(nil, %__MODULE__{} = bind_b, state, context, options) do
    {%__MODULE__{bind_b| bind: Enum.uniq(bind_b.bind)}, state}
  end
end