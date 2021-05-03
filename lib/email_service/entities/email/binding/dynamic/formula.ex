#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Formula do
  @vsn 1.0
  @type t :: %__MODULE__{
               identifier: String.t | list | tuple | nil,
               argument: any, # Rule Engine Op
               selectors: list,
               vsn: float,
             }
  defstruct [
    identifier: nil,
    argument: nil,
    selectors: [],
    vsn: @vsn
  ]

  def selectors(this) do
    this.selectors
  end

  def negate(selector = %Noizu.EmailService.Email.Binding.Dynamic.Selector{}) do
    this = %__MODULE__{
      argument: selector,
      selectors: [selector]
    }
    negate(this)
  end

  def negate(this = %__MODULE__{}) do
    argument = %Noizu.RuleEngine.Op.NotOp{argument: this.argument}
    %__MODULE__{this| argument: argument}
  end
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Dynamic.Formula do
  alias Noizu.RuleEngine.Helper
  #-----------------
  # execute!/3
  #-----------------
  def execute!(this, state, context), do: execute!(this, state, context, %{})

  #-----------------
  # execute!/4
  #-----------------
  def execute!(this, state, context, options) do
    Noizu.RuleEngine.ScriptProtocol.execute!(this.argument, state, context, options)
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
    Helper.render_arg_list("Formula", identifier(this, state, context, options), [this.argument], state, context, options)
  end
end