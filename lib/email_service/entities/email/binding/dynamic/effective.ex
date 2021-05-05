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
      option: [],
      required: []
    },
    meta: %{},
    vsn: @vsn
  ]


  #----------------------
  #
  #----------------------
  def finalize(%__MODULE__{} = this, state, context, options) do
    # Special case scalars
    scalars = Enum.filter(this.bind, &(Selector.scalar?(&1)))
              |> Enum.uniq()
              |> Enum.sort_by(&(&1.selector < &1.selector))
    binds = Enum.filter(this.bind, &(!Selector.scalar?(&1)))
            |> Enum.uniq()
            |> Enum.sort_by(&(&1.selector < &1.selector))


    # @TODO this is relatively straight forward, for each {:select} find smallest bind and load up that value
    # For longer paths verify the bound value contains those readings or add to unbound list, only add shortest possible branches to unbound list.
    # To deal arrays, pre populate with nil values up to max list index, and inject via Access.at(index) in reduce loop.
    # Inject scalars if value exists otherwise we should be able to leave unbound unless handlebars throws an exception when accessing null paths.
    # Not some juggling needed to deal with intermediate preexpanded format (e.g. lists not populated) and final format.
    IO.puts """
    scalars: #{inspect scalars}
    ---------------
    binds: #{inspect binds}
    """

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