#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Formula.Each do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: String.t | list | tuple | nil,
               clause: any,
               argument: any, # Rule Engine Op
               vsn: float,
             }
  defstruct [
    identifier: nil,
    clause: nil,
    argument: nil,
    vsn: @vsn
  ]
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Dynamic.Formula.Each do
  alias Noizu.RuleEngine.Helper
  alias Noizu.EmailService.Email.Binding.Dynamic.Effective
  #-----------------
  # execute!/3
  #-----------------
  def execute!(this, state, context), do: execute!(this, state, context, %{})

  #-----------------
  # execute!/4
  #-----------------
  def execute!(this, state, context, options) do
    {bind,state} = Effective.new(this, state, context, options)
    {iterator, state} = Noizu.RuleEngine.ScriptProtocol.execute!(this.clause, state, context, options)

    iterator = case iterator do
                 {:value, v} -> v
                 _else -> iterator
               end

    case iterator do
      nil -> {bind, state}
      false -> {bind, state}
      v when is_list(v) ->
        {b,s,_i} = Enum.reduce(v, {bind, state, 0}, fn(x, {b,s, index}) ->
          {b,s} = Effective.set_wildcard_hint(b, this.clause, :list, {index, x}, s, context, options)
          {r,s} = Noizu.RuleEngine.ScriptProtocol.execute!(this.argument, s, context, options)
          {r,s} = Effective.merge(b, r, s, context, options)
          {r,s, index + 1}
        end)
        Effective.clear_wildcard_hint(b, this.clause, :list, s, context, options)
      v = %{} ->
        {b,s} = Enum.reduce(v, {bind, state}, fn({k,v}, {b,s}) ->
          {b,s} = Effective.set_wildcard_hint(b, this.clause, :kv, {k, v}, s, context, options)
          {r,s} = Noizu.RuleEngine.ScriptProtocol.execute!(this.argument, s, context, options)
          Effective.merge(b, r, s, context, options)
        end)
        Effective.clear_wildcard_hint(b, this.clause, :list, s, context, options)
    end
  end

  #---------------------
  # identifier/3
  #---------------------
  def identifier(this, _state, _context), do: Helper.identifier(this)

  #---------------------
  # identifier/4
  #---------------------
  def identifier(this, _state, _context, _options), do: Helper.identifier(this)

  #---------------------
  # render/3
  #---------------------
  def render(this, state, context), do: render(this, state, context, %{})

  #---------------------
  # render/4
  #---------------------
  def render(this, state, context, options) do
    Helper.render_arg_list("Each", identifier(this, state, context, options), [this.argument], state, context, options)
  end
end