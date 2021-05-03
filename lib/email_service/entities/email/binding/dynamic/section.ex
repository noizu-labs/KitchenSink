#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Section do
  @vsn 1.0
  alias Noizu.EmailService.Email.Binding.Dynamic.Selector
  alias Noizu.EmailService.Email.Binding.Dynamic.Formula
  @type t :: %__MODULE__{
               section: :root | :if | :when | :each | :unless | {:unsupported, String.t},
               clause: any | nil,
               match: %{String.t => list},
               bind: Map.t,
               current_selector: Selector.t,
               errors: list,
               children: list,
               meta: Map.t,
               vsn: float,
             }

  defstruct [
    section: :root,
    clause: nil,
    match: %{},
    bind: %{},
    current_selector: %Selector{},
    errors: [],
    children: [],
    meta: %{},
    vsn: @vsn
  ]

  #----------------------------
  # current_selector/1
  #----------------------------
  def current_selector(this) do
    this.current_selector
  end

  #----------------------------
  # current_selector/2
  #----------------------------
  def current_selector(this, value) do
    %__MODULE__{this| current_selector: value}
  end

  #----------------------------
  # matches/1
  #----------------------------
  def matches(this) do
    this.match
  end

  #----------------------------
  # add_alias/2
  #----------------------------
  def add_alias(this, value) do
    put_in(this, [Access.key(:match), value.as], value)
  end

  #----------------------------
  # spawn
  #----------------------------
  def spawn(this, type, clause, options \\ %{}) do
    clause  = case type do
                :else -> this.clause
                :each -> Selector.wildcard(clause)
                _ -> clause
              end
    spawn = %__MODULE__{this|
      section: type,
      clause: clause,
      bind: %{},
      errors: [],
      meta: %{},
      children: [],
    }
  end

  #----------------------------
  # collapse/3
  #----------------------------
  def collapse(this = %__MODULE__{}, child = %__MODULE__{}, options) do
    case child.section do
      :if ->
        f = %Noizu.EmailService.Email.Binding.Dynamic.Formula.IfThen{
          condition_clause: child.clause,
          then_clause: %__MODULE__{child| match: nil, current_selector: nil, errors: nil}
        }
        %__MODULE__{this| children: this.children ++ [f]}
      :unless ->
        f = %Noizu.EmailService.Email.Binding.Dynamic.Formula.IfThen{
          condition_clause: Formula.negate(child.clause),
          then_clause: %__MODULE__{child| match: nil, current_selector: nil, errors: nil}
        }
        %__MODULE__{this| children: this.children ++ [f]}
        :each ->
          f = %Formula.Each{
            clause: child.clause,
            argument: %__MODULE__{child| match: nil, current_selector: nil, errors: nil},
          }
          %__MODULE__{this| children: this.children ++ [f]}
      _else ->
        %__MODULE__{this| bind: merge_bindings(this.bind, child.bind, options)}
    end
  end

  #----------------------------
  # collapse/4
  #----------------------------
  def collapse(this = %__MODULE__{}, if_child = %__MODULE__{}, else_child = %__MODULE__{}, options) do
    case if_child.section do
      :if ->
        f = %Noizu.EmailService.Email.Binding.Dynamic.Formula.IfThen{
          condition_clause: if_child.clause,
          then_clause: %__MODULE__{if_child| match: nil, current_selector: nil, errors: nil},
          else_clause: %__MODULE__{else_child| match: nil, current_selector: nil, errors: nil},
        }
        %__MODULE__{this| children: this.children ++ [f]}
      :unless ->
        f = %Noizu.EmailService.Email.Binding.Dynamic.Formula.IfThen{
          condition_clause: Formula.negate(if_child.clause),
          then_clause: %__MODULE__{if_child| match: nil, current_selector: nil, errors: nil},
          else_clause: %__MODULE__{else_child| match: nil, current_selector: nil, errors: nil}
        }
        %__MODULE__{this| children: this.children ++ [f]}
      _else ->
        # critical error
        %__MODULE__{this| bind: merge_bindings(this.bind, if_child.bind, options)}
    end
  end

  #----------------------------
  # merge_bindings/3
  #----------------------------
  def merge_bindings(a, b, options) do
    Enum.reduce(b, a, fn({k,v},acc) ->
      update_in(acc, [k], fn(p) ->
        p && merge_bindings(p, v, options) || v
      end)
    end)
  end

  #----------------------------
  # mark_error/3
  #----------------------------
  def mark_error(this, error, __options) do
    put_in(this, [Access.key(:errors)], this.errors ++ [error])
  end


  #----------------------------
  # require_binding
  #----------------------------
  def require_binding(this, nil, _options) do
    this
  end
  def require_binding(this, %Selector{} = binding, options) do
    [:root| path] = binding.selector
    {bind, _} = Enum.reduce(path, {this.bind, []}, fn(x, {b,p}) ->
      p = p ++ [x]
      {update_in(b, p, &( &1 || %{} )), p}
    end)
    %__MODULE__{this| bind: bind}
  end
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Dynamic.Section do
  alias Noizu.RuleEngine.Helper
  #-----------------
  # execute!/3
  #-----------------
  def execute!(this, state, context), do: execute!(this, state, context, %{})

  #-----------------
  # execute!/4
  #-----------------
  def execute!(this, state, context, options) do
    bind = Noizu.EmailService.Email.Binding.Helper.prepare_effective_binding(this.bind, state, context, options)
    Enum.reduce(this.children, {bind, state}, fn(child, {b,s}) ->
      {c,s} = Noizu.RuleEngine.ScriptProtocol.execute!(child, s, context, options)
      b = Noizu.EmailService.Email.Binding.Helper.merge_effective_binding(b,c, s, context, options)
      {b,s}
    end)
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
    Helper.render_arg_list("Section", identifier(this, state, context, options), [this.argument], state, context, options)
  end
end