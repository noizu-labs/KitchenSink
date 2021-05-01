#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Dynamic do
  @vsn 1.0
  alias Noizu.EmailService.Email.Binding.Dynamic.Selector
  alias Noizu.EmailService.Email.Binding.Dynamic.Section
  alias Noizu.EmailService.Email.Binding.Dynamic.Error
  alias Noizu.EmailService.Email.Binding.Dynamic, as: Binding
  @type t :: %__MODULE__{
               current_token: {integer, String.t} | nil,
               bind: Map.t,
               conditional_bind: any,
               section_stack: [Section.t],
               errors: list,
               last_error: Error.t,
               outcome: atom,
               meta: Map.t,
               vsn: float,
             }

  defstruct [
    current_token: nil,
    bind: %{},
    conditional_bind: :pending,
    section_stack: [%Section{}],
    errors: [],
    last_error: nil,
    outcome: :ok,
    meta: %{},
    vsn: @vsn
  ]

  #----------------------------
  # extract/2
  #----------------------------
  @doc """
    Parse input string and extract (including conditional qualifiers) data needed to populate template.
  """
  def extract(block, options \\ %{}) do
    state = %__MODULE__{}

    # 1. Explicit Variable Bind
    state = case Regex.scan(~r/\{\{(!bind\s+[a-zA-Z0-9_\.\[\]]+)\}\}/, block, capture: :all_but_first) do
                        v when is_list(v) ->
                          List.flatten(v)
                          |> Enum.map(&(String.trim(&1)))
                          |> Enum.reduce_while(state,  fn(term, state) ->
                            case extract_selector(state, term, options) do
                              {:halt, state} -> {:halt, state}
                              {:error, state} -> {:cont, state}
                              {selector, state} ->
                                state = require_binding(state, selector, options)
                                {:cont, state}
                            end
                          end)
                        _ -> state
                      end

    cond do
      state.outcome != :ok ->
        mark_error(state, :invalid_required_binding, options)
        |> put_in([Access.key(:outcome)], :fatal_error)
      :else ->
        # 2. Strip comment sections that allow nested bars.
        block = String.replace(block, ~r/\{\{!--.*--\}\}/U, "")

        # 3. Strip plain comments.
        block = String.replace(block, ~r/\{\{!.*\}\}/U, "")

        # 4. Parse Tokens and Specifiers
        case Regex.scan(~r/\{\{([^\}]+)\}\}/, block, capture: :all_but_first) do
          v when is_list(v) ->
            List.flatten(v)
            |> Enum.reduce_while(state,  fn(token, acc) ->
              case extract_token({token, acc}, options) do
                {:halt, this} -> {:halt, this}
                {:cont, this} -> {:cont, this}
                this -> {:cont, this}
              end
            end)
          _ -> state
        end
    end |> finalize()
  end

  #----------------------------
  # finalize/1
  #----------------------------
  def finalize(this) do
    # compress and build formula tree
    this
  end

  #----------------------------
  # extract_token/2
  #----------------------------
  def extract_token({token, this}, options) do
    # compress and build formula tree
    token = String.trim(token)
    this = case this.current_token do
              nil -> %__MODULE__{this| current_token: {0, token}}
              {index, _previous_token} -> %__MODULE__{this| current_token: {index + 1, token}}
            end

    case token do
      # Begin Built-in
      "#" <> _clause ->
        case extract_token__section_open(this, token, options) do
          {:halt, this} -> {:halt, this}
          {:cont, this} -> {:cont, this}
          this -> {:cont, this}
        end

      # End Built-In
      "/" <> _clause ->
        case extract_token__section_close(this, token, options) do
          {:halt, this} -> {:halt, this}
          {:cont, this} -> {:cont, this}
          this -> {:cont, this}
        end

      # Specifiers
      _ ->
        case extract_selector(this, token, options) do
          {:error, this} -> {:halt, this}
          {clause, this} ->
            this = require_binding(this, clause, options)
            {:cont, this}
        end
    end
  end

  #----------------------------
  #
  #----------------------------
  def extract_token__section_open(this, token, options) do
    token = String.trim(token)
    case token do
      "#if " <> clause -> extract_token__section_open__enter(:if, clause, this, options)
      "#unless " <> clause -> extract_token__section_open__enter(:unless, clause, this, options)
      "#each" <> clause -> extract_token__section_open__enter(:each, clause, this, options)
      "#with" <> clause -> extract_token__section_open__enter(:with, clause, this, options)
      "#" <> _clause ->
        case Regex.run(~r/^#([\w\.]+)(\s.*\|.*)?$/U, token, capture: :all_but_first) do
          [section, clause] -> extract_token__section_open__enter({:unsupported, section}, clause, this, options)
          [section] -> extract_token__section_open__enter({:unsupported, section}, nil, this, options)
        end
      _ -> fatal_error(this, {:section_open, token})
    end
  end

  #----------------------------
  #
  #----------------------------
  def extract_token__section_open__enter(section, clause, this, options) do
    case extract_selector(this, clause, options) do
      {:error, this} -> {:halt, this}
      {clause, this} ->
        # mark param as required as we'll need it regardless of type at the current stack level.
        this = require_binding(this, clause, options)

        # append new section
        [head|tail] = this.section_stack
        new_section = Section.spawn(head, section, clause, options)
        this = %__MODULE__{this| section_stack: [new_section|this.section_stack]}

        # update this or bindings if each or with
        case section do
          :with ->
            cond do
              clause.as -> add_alias(this, clause)
              :else -> current_selector(this, clause)
            end
          :each ->
            cond do
              clause && clause.as -> add_alias(this, clause)
              :else -> current_selector(this, clause)
            end
            _ -> this
        end
    end
  end

  #----------------------------
  #
  #----------------------------
  def extract_token__section_close(this, token, options) do
    token = String.trim(token)
    case token do
      "/if" <> clause -> extract_token__section_close__exit(:if, this, options)
      "/unless" <> clause -> extract_token__section_close__exit(:unless, this, options)
      "/each" <> clause -> extract_token__section_close__exit(:each, this, options)
      "/with" <> clause -> extract_token__section_close__exit(:with, this, options)
      "/" <> section -> extract_token__section_close__exit({:unsupported, String.trim(section)}, this, options)
      _ -> fatal_error(this, {:section_close, token}, options)
    end
  end

  #----------------------------
  #
  #----------------------------
  def extract_token__section_close__exit(section, this, options) do
    #TODO output for processing structure needs to be built here.
    #E.g nested section tree.
    case extract_token__section_close__exit_match(section, this.section_stack, this, options) do
      {:error, cause} -> fatal_error(this, cause, options)
      this -> this
    end
  end

  #----------------------------
  #
  #----------------------------
  def extract_token__section_close__exit_match(section, [head|tail] = _command_stack, this, options) do
    cond do
      head.section == section ->
        %__MODULE__{this| section_stack: tail}
      Kernel.match?({:unsupported, _}, head.section) ->
        # Allow non closed unsupported sections, unwrap until end of list or match.
        extract_token__section_close__exit_match(section, tail, this, options)
      :else -> {:error, {:tag_close_mismatch, section}}
    end
  end

  #----------------------------
  # current_selector/1
  #----------------------------
  def current_selector(this) do
    Section.current_selector(get_in(this, [Access.key(:section_stack), Access.at(0)]))
  end

  #----------------------------
  # current_selector/2
  #----------------------------
  def current_selector(this, value) do
    update_in(this, [Access.key(:section_stack), Access.at(0)], &(Section.current_selector(&1, value)))
  end

  #----------------------------
  # add_alias/2
  #----------------------------
  def add_alias(this, clause) do
    update_in(this, [Access.key(:section_stack), Access.at(0)], &(Section.add_alias(&1, clause)))
  end

  #----------------------------
  # require_binding
  #----------------------------
  def require_binding(this, nil, _options) do
    this
  end
  def require_binding(this, %Selector{} = binding, options) do
    update_in(this, [Access.key(:section_stack), Access.at(0)], &(Section.require_binding(&1, binding, options)))
  end

  def fatal_error(this, cause, options \\ %{}) do
    {:halt, mark_error(this, cause, options)}
  end

  #----------------------------
  # mark_error
  #----------------------------
  def mark_error(this, cause, options \\ %{})
  def mark_error(this, cause, options) do
    error = %Error{error: cause, token: this.current_token}
    this
    |> update_in([Access.key(:section_stack), Access.at(0)], &(Section.mark_error(&1, error, options)))
    |> put_in([Access.key(:last_error)], error)
  end


  def parse_pipes(nil), do: nil
  def parse_pipes([]), do: nil
  def parse_pipes([v]), do: parse_pipes(v)
  def parse_pipes(pipe) do
    case Regex.run(~r/as \|\s*([a-zA-Z0-9_]+)?\s*\|/, pipe, capture: :all_but_first) do
      [h|t] -> %{as: h}
      _ -> %{}
    end
  end

  #----------------------------
  # extract_selector/3
  #----------------------------
  @doc """
    Parse clause to extract any operations/formulas and or bound variables.
    @returns Dynamic.Binding.Selector or Dynamic.Binding.HandleBarClause
  """
  def extract_selector(this, token, options \\ %{})
  def extract_selector(this, nil, _options), do: {nil, this}
  def extract_selector(this, token, options) do
    token = String.trim(token)
    cond do
      token == "else" -> {:error, mark_error(this, {:extract_clause, :else, :support_pending}, options)}
      token == "this" || token == "." ->
        selector = current_selector(this)
        if Selector.valid?(selector, options) do
          {selector, this}
        else
          {:error, mark_error(this, {:extract_clause, :this, :invalid}, options)}
        end
      token == "../" ->
        selector = current_selector(this)
        case Selector.parent(selector, nil, options) do
          {:error, clause} ->
            {:error, mark_error(this, clause, options)}
            selector -> {selector, this}
        end

      :else ->
        case token do
          "../" <> _relative ->
            clean_token = Regex.replace(~r/\|.*$/, token, "") # strip any pipes
            selector = current_selector(this)
            case Selector.relative(selector, clean_token, parse_pipes(token), options) do
              {:error, clause} ->
                {:error, mark_error(this, clause, options)}
              selector -> {selector, this}
            end

          "!bind " <> clause ->
            case extract_selector(this, clause, options) do
              {selector = %Selector{}, this} -> {selector, this}
              {:error, this} -> {:error, this}
              {_, _this} -> {:error, mark_error(this, :rule_engine_pending, options)}
            end

           "this." <> clause ->
           case Regex.run(~r/^this((?:[\.\[\]]@?[a-zA-Z0-9_]+)*)\]?(\s.*\|.*)?$/, token, capture: :all_but_first) do
             [""|_] -> {:error, mark_error(this, :parse, options)}
             [b|c] -> {:error, mark_error(this, clause, options)}
               b = Regex.scan(~r/[\.\[\]]@?[a-zA-Z0-9_]+/, b) |> List.flatten()
               case Selector.extend(current_selector(this), b, parse_pipes(c)) do
                 selector = %Selector{} -> {selector, this}
                 {:error, clause} -> {:error, mark_error(this, clause, options)}
               end
               _ ->
                 {:error, mark_error(this, {:invalid_token, token}, options)}
           end

          token ->
          case Regex.run(~r/^([a-zA-Z0-9_]+)((?:[\.\[\]]@?[a-zA-Z0-9_]+)*)\]?(\s.*\|.*)?$/, token, capture: :all_but_first) do
            [a,b|c] ->
              b = Regex.scan(~r/[\.\[\]]@?[a-zA-Z0-9]+/, b) |> List.flatten()
              case Selector.new([a] ++ b, parse_pipes(c)) do
                selector = %Selector{} -> {selector, this}
                {:error, clause} -> {:error, mark_error(this, clause, options)}
              end
              _ ->
                {:error, mark_error(this, {:invalid_token, token}, options)}
          end
        end
    end
  end
end