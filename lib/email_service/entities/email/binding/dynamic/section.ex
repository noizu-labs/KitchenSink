#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Section do
  @vsn 1.0
  alias Noizu.EmailService.Email.Binding.Dynamic.Selector

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
    clause = if type == :else do
        this.clause # todo negate formula
    else
        clause
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
    # todo any non if/unless/:else children sections bindings can be added to this level, only child's if/unless sections need to be added to our children set.
    case child.section do
      :if -> %__MODULE__{this| children: this.children ++ [child]}
      :else -> %__MODULE__{this| children: this.children ++ [child]}
      :unless -> %__MODULE__{this| children: this.children ++ [child]}
      _else ->  %__MODULE__{this| bind: merge_bindings(this.bind, child.bind, options)}
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
