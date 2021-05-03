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
  #-----------------
  # execute!/3
  #-----------------
  def execute!(this, state, context), do: execute!(this, state, context, %{})

  #-----------------
  # execute!/4
  #-----------------
  def execute!(this, state, context, options) do
    bind = Noizu.EmailService.Email.Binding.Helper.prepare_effective_binding(%{}, state, context, options)
    {e, state} = Noizu.RuleEngine.ScriptProtocol.execute!(this.clause, state, context, options)
    case e do
      nil -> {nil, state}
      v when is_list(v) ->
        {v,s,_i} = Enum.reduce(v, {bind, state, 0}, fn(x, {b,s, i}) ->
          # @TODO - Set internal state for bound variable b, plus @key/@value/@index etc. fields.
          {c,s} = Noizu.RuleEngine.ScriptProtocol.execute!(this.argument, s, context, options)
          b = Noizu.EmailService.Email.Binding.Helper.merge_effective_binding(b,c, s, context, options)
          {b,s, i + 1}
        end)
        {v,s}
      v = %{} ->
        Enum.reduce(v, {bind, state}, fn({k,v}, {b,s}) ->
          # @TODO - Set internal state for bound variable b, plus @key/@value/@index etc. fields.
          {c,s} = Noizu.RuleEngine.ScriptProtocol.execute!(this.argument, s, context, options)
          b = Noizu.EmailService.Email.Binding.Helper.merge_effective_binding(b,c, s, context, options)
          {b,s}
        end)
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