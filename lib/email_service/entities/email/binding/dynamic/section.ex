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
  # add_alias/2
  #----------------------------
  def add_alias(this, value) do
    put_in(this, [Access.key(:match), value.as], value)
  end

  #----------------------------
  # spawn
  #----------------------------
  def spawn(this, type, clause, options \\ %{}) do
    spawn = %__MODULE__{this|
      section: type,
      clause: clause,
      bind: %{},
      errors: [],
      meta: %{},
    }
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
