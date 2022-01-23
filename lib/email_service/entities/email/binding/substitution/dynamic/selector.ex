#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Substitution.Dynamic.Selector do
  @vsn 1.0
  @type t :: %__MODULE__{
               selector: list,
             }
  defstruct [
    selector: [],
  ]

  #----------------------------------
  #
  #----------------------------------
  def selectors(this) do
    [this]
  end

  #----------------------------------
  #
  #----------------------------------
  def valid?(this, options \\ %{})
  def valid?(%__MODULE__{selector: []}, options), do: false
  def valid?(%__MODULE__{}, options), do: true
  def valid?(_this, _options), do: false

  #----------------------
  # exists/1
  #----------------------
  def exists(%__MODULE__{} = this) do
    # indicate only return scalar values and true/false/nil, nested readings not required.
    %__MODULE__{this| selector: this.selector ++ [:scalar_value]}
  end

  def scalar?(%__MODULE__{} = this) do
    List.last(this.selector) == :scalar_value
  end

  def path(%__MODULE__{} = this) do
    cond do
      List.last(this.selector) == :scalar_value -> Enum.slice(this.selector, 0 .. -2)
      :else -> this.selector
    end
  end

  def auto_expand({:ref, _m, _id} = ref, state, context, options) do
    {lookup,state} = Noizu.RuleEngine.StateProtocol.get!(state, :ref_lookup, context)
    cond do
      v = lookup[ref] -> {v, state}
      v = Noizu.ERP.entity!(ref) ->
         lookup = put_in(lookup || %{}, [ref], v)
         state = Noizu.RuleEngine.StateProtocol.put!(state, :ref_lookup, lookup, context)
         {v, state}
      :else ->
         lookup = put_in(lookup || %{}, [ref], ref)
         state = Noizu.RuleEngine.StateProtocol.put!(state, :ref_lookup, lookup, context)
         {ref, state}
    end
  end

  def auto_expand(v, state, context, options) do
    {v,state}
  end

  def extract_wildcard(this, _key, bound?, blob, state, head, path, full_path, context, options) do
    cpath = path ++ [{:*}]
    cond do
      cpath == full_path -> {:halt, {bound?, blob, state, cpath}}
      :else ->
        {r,state} = Noizu.RuleEngine.StateProtocol.get!(state, :wildcards, context)
        case Enum.filter(r || [], fn({k,_}) -> k == cpath end) do
          [{_,%{type: :list, index: i, value: v}}|_] -> {:cont, {bound?, v, state, path ++ [{:at, i}]}}
          [{_,%{type: :kv, key: i, value: v}}|_] -> {:cont, {bound?, v, state, path ++ [{:key, i}]}}
          _ -> {:halt, {false, nil, state, cpath}}
        end
    end
  end

  def extract_key(this, member, bound?, blob, state, head, path, full_path, context, options) do
    path = path ++ [head]
    cond do
      is_map(blob) ->
        accessor = Enum.find(Map.keys(blob), &(&1 == member || "#{&1}" == member))
        if accessor do
          {blob, state} = auto_expand(get_in(blob, [Access.key(accessor)]), state, context, options)
          cond do
            blob != nil -> {:cont, {bound?, blob, state, path}}
            scalar?(this) -> {:cont, {bound?, blob, state, path}}
            :else -> {:halt, {false, nil, state, path}}
          end
        else
          {:halt, {false, nil, state, path}}
        end
      :else ->
        {:halt, {false, nil, state, path}}
    end
  end

  def extract_at(this, index, bound?, blob, state, head, path, _full_path, context, options) do
    path = path ++ [head]
    cond do
      is_list(blob) && length(blob) > index ->
        {blob, state} = auto_expand(get_in(blob, [Access.at(index)]), state, context, options)
        cond do
          blob != nil -> {:cont, {bound?, blob, state, path}}
          scalar?(this) -> {:cont, {bound?, blob, state, path}}
          :else -> {:halt, {false, nil, state, path}}
        end
      :else ->
        {:halt, {false, nil, state, path}}
    end
  end

  def bound_inner(%__MODULE__{} = this, bound, state, context, options) do
    full_path = path(this)
    {bound?,val, state, path} = Enum.reduce_while(full_path, {true, bound, state, []}, fn(head,{bound?, blob, state, path}) ->
      case head do
        {:*} -> extract_wildcard(this, :*, bound?, blob, state, head, path, full_path, context, options)
        {:select, name} -> extract_key(this, name, bound?, blob, state, head, path, full_path, context, options)
        {:key, name} -> extract_key(this, name, bound?, blob, state, head, path, full_path, context, options)
        {:at, index} -> extract_at(this, index, bound?, blob, state, head, path, full_path, context, options)
      end
    end)
    {bound?, Noizu.Proto.DynamicBind.bind_value(val, context, options), state}
  end

  def is_bound?(%__MODULE__{} = this, bound, state, context, options) do
    p = path(this)
    {bound?,_v,_state} = bound_inner(this, bound, state, context, options)
    bound? # @todo dropped state
  end

  def bound(%__MODULE__{} = this, bound, state, context, options) do
    p = path(this)
    {bound?, v, _state} = bound_inner(this, bound, state, context, options)
    bound? && {:value, v} # @todo dropped state
  end

  #----------------------------------
  #
  #----------------------------------
  def new([h|t], pipes, matches) do
    selector = case matches[h] do
               %{selector: v} -> v
               _ -> [{:select, h}]
               end
    case t do
      [] -> {%__MODULE__{selector: selector}, pipes}
      v when is_list(v) -> extend(%__MODULE__{selector: selector}, t, pipes)
    end
  end

  #----------------------------------
  #
  #----------------------------------
  def extend(this, [h|t] = v, pipes) do
    cond do
      this.selector == [] -> {:error, {:extract_clause, :this, :invalid}}
      :else ->
      selector = this.selector ++
                 Enum.map(v || [], fn(x) ->
                   case x do
                     "." <> v -> {:key, String.trim(v)}
                     "]" <> v -> {:key, String.trim(v)}
                     "[" <> v -> {:at, String.trim(v)}
                   end
                 end)
      {%__MODULE__{this| selector: selector}, pipes}
    end
  end

  #----------------------------------
  #
  #----------------------------------
  def relative(this, path, pipes, options \\ %{}) do
    Enum.reduce_while(String.split(path, "./"), {this, pipes}, fn(token, {t, p} = acc) ->
      case token do
        "" -> {:halt, acc}
        "." ->
          case parent(t, p) do
            tp = {%__MODULE__{}, _meta} -> {:cont, tp}
            e = {:error, _} -> {:halt, e}
          end
        v ->
          b = Regex.scan(~r/[\.\[\]]@?[a-zA-Z0-9]+/, "." <> v) |> List.flatten()
          case extend(t, b, p) do
            tp = {%__MODULE__{}, _} -> {:cont, tp}
            e = {:error, _} -> {:halt, e}
          end
      end
    end)
  end

  #----------------------------------
  #
  #----------------------------------
  def parent(this, pipes, options \\ %{})
  def parent(this = %__MODULE__{selector: []}, _pipes, options) do
  {:error, {:select_parent, :already_root}}
  end
  def parent(this = %__MODULE__{selector: [_object]}, _pipes, options) do
  {:error, {:select_parent, :already_top}}
  end
  def parent(this = %__MODULE__{selector: selector}, pipes, options) do
    parent = cond do
               List.last(this.selector) == :* -> Enum.slice(this.selector, 0 .. -3)
               :else -> Enum.slice(this.selector, 0 .. -2)
             end
    {%__MODULE__{this| selector: parent}, pipes}
  end


  #----------------------------------
  #
  #----------------------------------
  def wildcard(this) do
    %__MODULE__{this| selector: this.selector ++ [{:*}]}
  end

  #----------------------------------
  #
  #----------------------------------
  def set_wildcard_hint(%__MODULE__{} = this, hint) do
    selector = Enum.slice(this.selector, 0..-2) ++ [hint]
    %__MODULE__{selector: selector}
  end
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Substitution.Dynamic.Selector do
  alias Noizu.RuleEngine.Helper
  #-----------------
  # execute!/3
  #-----------------
  def execute!(this, state, context), do: execute!(this, state, context, %{})

  #-----------------
  # execute!/4
  #-----------------
  def execute!(this, state, context, options) do
    variable_extractor = options.variable_extractor
    variable_extractor.(this, state, context, options)
  end

  #---------------------
  # identifier/3
  #---------------------
  def identifier(this, _state, _context), do: "..."

  #---------------------
  # identifier/4
  #---------------------
  def identifier(this, _state, _context, _options), do: "..."

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
    id = identifier(this, state, context, options)
    v = "#{inspect this.selector}"
    t = String.slice(v, 0..64)
    t = if (t != v), do: t <> "...", else: t
    "#{prefix}#{id} [VALUE #{t}]\n"
  end
end

#=============================================================================
# Inspect Protocol
#=============================================================================
defimpl Inspect, for: Noizu.EmailService.Email.Binding.Substitution.Dynamic.Selector do
  import Inspect.Algebra

  def inspect(entity, opts) do

    path = Enum.map(entity.selector, fn(k) ->
      case k do
        {:select, n} -> n
        {:key, n} -> n
        {:at, n} -> "[#{n}]"
        {:*} -> "*"
        :scalar_value -> "(?)"
        _ -> "_"
      end
    end) |> Enum.join(".")

    concat ["Selector(", path, ")"]
  end
end  # end Inspect
