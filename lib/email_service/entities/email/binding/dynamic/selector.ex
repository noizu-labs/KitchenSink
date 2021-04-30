#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic.Selector do
  @vsn 1.0
  @type t :: %__MODULE__{
               selector: list,
               as: String.t | nil,
               vsn: float,
             }
  defstruct [
    selector: [:root],
    as: nil,
    vsn: @vsn
  ]

  def valid?(this, options \\ %{})
  def valid?(%__MODULE__{selector: [:root]}, options), do: false
  def valid?(%__MODULE__{}, options), do: true
  def valid?(_this, _options), do: false

  def new([h|t]) do
    selector = [:root, {:select, h}]
    case t do
      [] -> %__MODULE__{selector: selector}
      v when is_list(v) -> extend(%__MODULE__{selector: selector}, t)
    end
  end

  def wildcard(this) do
    %__MODULE__{this| selector: this.selector ++ [{:*}]}
  end

  def extend(this, [h|t] = v) do
    cond do
      this.selector == [:root] -> {:error, {:extract_clause, :this, :invalid}}
      :else ->
      selector = this.selector ++
                 Enum.map(v || [], fn(x) ->
                   case x do
                     "." <> v -> {:key, String.trim(v)}
                     "]" <> v -> {:key, String.trim(v)}
                     "[" <> v -> {:at, String.trim(v)}
                   end
                 end)
      %__MODULE__{this| selector: selector, as: nil}
    end
  end

  def relative(this, path, options \\ %{}) do
    Enum.reduce_while(String.split(path, "./"), this, fn(token,acc) ->
      case token do
        "" -> {:halt, acc}
        "." ->
          case parent(acc) do
            p = %__MODULE_{} -> {:cont, p}
            e -> {:halt, e}
          end
        v ->
          b = Regex.scan(~r/[\.\[\]]@?[a-zA-Z0-9]+/, "." <> v) |> List.flatten()
          case extend(acc, b) do
            p = %__MODULE_{} -> {:cont, p}
            e -> {:halt, e}
          end
      end
    end)
  end

  def parent(this, options \\ %{})
  def parent(this = %__MODULE__{selector: [:root]}, options) do
  {:error, {:select_parent, :already_root}}
  end
  def parent(this = %__MODULE__{selector: [:root, _object]}, options) do
  {:error, {:select_parent, :already_top}}
  end
  def parent(this = %__MODULE__{selector: selector}, options) do
    parent = cond do
               List.last(this.selector) == :* -> Enum.slice(this.selector, 0 .. -3)
               :else -> Enum.slice(this.selector, 0 .. -2)
             end
    %__MODULE__{this| selector: parent, as: nil}
  end
end