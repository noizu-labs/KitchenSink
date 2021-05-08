#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Substitution.Dynamic.Section do
  @vsn 1.0
  alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Selector
  alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula
  alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Effective
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
    bind: [],
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
  # add_alias/3
  #----------------------------
  def add_alias(this, value, as) do
    put_in(this, [Access.key(:match), as], value)
  end

  #----------------------------
  # spawn
  #----------------------------
  def spawn(this, type, clause, options \\ %{}) do
    clause  = case type do
                :else -> nil
                :each -> Selector.wildcard(clause)
                _ -> clause
              end
    spawn = %__MODULE__{this|
      section: type,
      clause: clause,
      bind: [],
      errors: [],
      meta: %{},
      children: [],
    }
  end

  def collapse_daisy_chain([h,p|t], options) do
    cond do
      (h.section == :else || h.section == :extended_else) && p.section == :extended_else ->
        # TODO deal with selector list
        f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
          condition_clause: p.clause,
          then_clause: %__MODULE__{p| match: nil, current_selector: nil, errors: nil},
          else_clause: %__MODULE__{h| match: nil, current_selector: nil, errors: nil},
          selectors: Formula.selectors(p)
        }

        {o, clip} = Enum.reduce_while(t, {f,0}, fn(section, {acc, clip}) ->
          cond do
            section.section == :extended_else ->
              f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
                condition_clause: section.clause,
                then_clause: %__MODULE__{section| match: nil, current_selector: nil, errors: nil},
                else_clause: acc,
                selectors: Formula.selectors(section) ++ acc.selectors,
              }
              {:cont, {f, clip + 1}}
            section.section == :if ->
              f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
                condition_clause: section.clause,
                then_clause: %__MODULE__{section| match: nil, current_selector: nil, errors: nil},
                else_clause: acc,
                selectors: Formula.selectors(section) ++ acc.selectors,
              }
              {:halt, {f, clip + 1}}
            section.section == :unless ->
              c = Formula.negate(section.clause)
              f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
                condition_clause: c,
                then_clause: %__MODULE__{section| match: nil, current_selector: nil, errors: nil},
                else_clause: acc,
                selectors: Formula.selectors(section) ++ acc.selectors,
              }
              {:halt, {f, clip}}
            :else -> {:halt, {{:error, :invalid_daisy_chain}, clip}}
          end
        end)
        case o do
          {:error, _} -> o
          f ->
            [h|t] = Enum.slice(t, clip .. -1)
            [%__MODULE__{h| children: h.children ++ [f]} | t]
        end
      :else -> {:error, :invalid_daisy_chain}
    end
  end

  #----------------------------
  # collapse/3
  #----------------------------
  def collapse(this = %__MODULE__{}, child = %__MODULE__{}, options) do
    case child.section do
      :if ->
        c = child.clause
        f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
          condition_clause: child.clause,
          then_clause: %__MODULE__{child| match: nil, current_selector: nil, errors: nil},
          selectors: Formula.selectors(child.clause),
        }
        %__MODULE__{this| children: this.children ++ [f]}
      :unless ->
        c = Formula.negate(child.clause)
        f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
          condition_clause: c,
          then_clause: %__MODULE__{child| match: nil, current_selector: nil, errors: nil},
          selectors: Formula.selectors(child.clause),
        }
        %__MODULE__{this| children: this.children ++ [f]}
      :each ->
        f = %Formula.Each{
          clause: child.clause,
          argument: %__MODULE__{child| match: nil, current_selector: nil, errors: nil},
        }
        %__MODULE__{this| children: this.children ++ [f]}
      _else ->
        %__MODULE__{this| bind: merge_bindings(this.bind, child.bind, options), children: this.children ++ child.children}
    end
  end

  #----------------------------
  # collapse/4
  #----------------------------
  def collapse(this = %__MODULE__{}, if_child = %__MODULE__{}, else_child = %__MODULE__{}, options) do
    case if_child.section do
      :if ->
        c = if_child.clause
        f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
          condition_clause: c,
          then_clause: %__MODULE__{if_child| match: nil, current_selector: nil, errors: nil},
          else_clause: %__MODULE__{else_child| match: nil, current_selector: nil, errors: nil},
          selectors: Formula.selectors(if_child),
        }
        %__MODULE__{this| children: this.children ++ [f]}
      :unless ->
        c = Formula.negate(if_child.clause)
        f = %Noizu.EmailService.Email.Binding.Substitution.Dynamic.Formula.IfThen{
          condition_clause: c,
          then_clause: %__MODULE__{if_child| match: nil, current_selector: nil, errors: nil},
          else_clause: %__MODULE__{else_child| match: nil, current_selector: nil, errors: nil},
          selectors: Formula.selectors(if_child),
        }
        %__MODULE__{this| children: this.children ++ [f]}
    end
  end

  #----------------------------
  # merge_bindings/3
  #----------------------------
  def merge_bindings(a, b, options) do
    (a || []) ++ (b || [])
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
    %__MODULE__{this| bind: Enum.uniq([binding] ++ this.bind)}
  end
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Substitution.Dynamic.Section do
  alias Noizu.RuleEngine.Helper
  alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Effective
  #-----------------
  # execute!/3
  #-----------------
  def execute!(this, state, context), do: execute!(this, state, context, %{})

  #-----------------
  # execute!/4
  #-----------------
  def execute!(this, state, context, options) do
    {bind, state} = Effective.new(this, state, context, options)
    Enum.reduce(this.children, {bind, state}, fn(child, {b,s}) ->
      {r,s} = Noizu.RuleEngine.ScriptProtocol.execute!(child, s, context, options)
      Effective.merge(b, r, s, context, options)
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