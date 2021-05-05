#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Formula.IfThen do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: String.t | list | tuple | nil,
               condition_clause: any,
               then_clause: any,
               else_clause: any,
               settings: Keyword.t,
               vsn: float,
             }
  defstruct [
    identifier: nil,
    condition_clause: nil,
    then_clause: nil,
    else_clause: nil,
    settings: [async?: :auto, throw_on_timeout?: :auto],
    vsn: @vsn
  ]
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Dynamic.Formula.IfThen do
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
    async? = cond do
               Enum.member?([true, :auto, :required], this.settings[:async?]) && (options[:settings] && options.settings.supports_async? == true) -> true
               this.settings[:async?] == :required -> throw Noizu.RuleEngine.Error.Basic.new("[ScriptError] Unable to perform required async execute on #{this.__struct__} - #{identifier(this, state, context)}", 310)
               true -> false
             end

    {condition, state} = Noizu.RuleEngine.ScriptProtocol.execute!(this.condition_clause, state, context, options)
    options_b = put_in(options, [:list_async?], async?)
    {bind, state} = Effective.new(this, state, context, options)
    if condition do
      {r, s} = Noizu.RuleEngine.ScriptProtocol.execute!(this.then_clause, state, context, options_b)
      Effective.merge(bind, r, s, context, options)
    else
      {r, s} = Noizu.RuleEngine.ScriptProtocol.execute!(this.else_clause, state, context, options_b)
      Effective.merge(bind, r, s, context, options)
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
    depth = options[:depth] || 0
    prefix = (depth == 0) && (">> ") || (String.duplicate(" ", ((depth - 1) * 4) + 3) <> "|-- ")
    options_b = put_in(options, [:depth], depth + 1)
    id = identifier(this, state, context, options)
    """
    #{prefix}#{id} [if]
    #{prefix} (CONDITION CLAUSE)
    #{Noizu.RuleEngine.ScriptProtocol.render(this.condition_clause, state, context, options_b)}#{prefix} (THEN CLAUSE)
    #{Noizu.RuleEngine.ScriptProtocol.render(this.then_clause, state, context, options_b)}#{prefix} (ELSE CLAUSE)
    #{Noizu.RuleEngine.ScriptProtocol.render(this.else_clause, state, context, options_b)}
    """
  end
end