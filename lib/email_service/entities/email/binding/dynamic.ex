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
               section_stack: [Section.t],
               errors: list,
               last_error: Error.t,
               outcome: atom,
               meta: Map.t,
               vsn: float,
             }

  defstruct [
    current_token: nil,
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

    # 1. Reshape bindings
    block = String.replace(block, ~r/\{\{!bind /, "{{#bind ")
    # 1. Explicit Variable Bind

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
    end
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
      "#bind " <> clause ->
        case extract_selector(this, "!bind " <> clause, options) do
          {:error, this} -> {:halt, this}
          {clause, this} ->
            this = require_binding(this, clause, options)
            {:cont, this}
        end

      # Begin Built-in
      "#" <> _clause ->
        case extract_token__section_open(this, token, options) do
          {:halt, this} -> {:halt, this}
          {:cont, this} -> {:cont, this}
          this -> {:cont, this}
        end

      "else" ->
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
      "else" -> extract_token__section_open__enter(:else, nil, this, options)
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
    case extended_extract_selector(this, clause, options) do
      {:error, this} -> {:halt, this}
      {{clause, pipes}, this} ->
        # Deprecate, section collapse process takes care of forced requirements, formula process takes care of ensuring required bindings for if/unless clauses loaded.
        # this = require_binding(this, clause, options)

        # append new section
        [head|tail] = this.section_stack
        new_section = Section.spawn(head, section, clause, options)
        this = %__MODULE__{this| section_stack: [new_section|this.section_stack]}

        # update this or bindings if each or with
        case section do
          :with ->
            cond do
              as = pipes[:as] -> add_alias(this, clause, as)
              :else -> current_selector(this, clause)
            end
          :each ->
            clause = Selector.wildcard(clause)
            cond do
              as = pipes[:as] -> add_alias(this, clause, as)
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
  # extract_token__section_close__exit
  #----------------------------
  def extract_token__section_close__exit(section, this, options) do
    #TODO output for processing structure needs to be built here.
    #E.g nested section tree.
    case extract_token__section_close__exit_match(section, this, options) do
      {:error, cause} -> fatal_error(this, cause, options)
      this -> this
    end
  end

  #----------------------------
  # extract_token__section_close__exit_match
  #----------------------------
  def extract_token__section_close__exit_match(section, %__MODULE__{section_stack: [h,p|tail]} = this, options) do
    cond do
      h.section == section ->
        p = Section.collapse(p, h, options)
        %__MODULE__{this| section_stack: [p|tail]}
      h.section == :else && section == p.section && (section == :if || section == :unless) ->
        [e,i_u,p|t] = this.section_stack
        p = Section.collapse(p, i_u, e, options)
        %__MODULE__{this| section_stack: [p|t]}
      Kernel.match?({:unsupported, _}, h.section) ->
        # Allow non closed unsupported sections, unwrap until end of list or match.
        p = Section.collapse(p, h, options)
        extract_token__section_close__exit_match(section, %__MODULE__{this| section_stack: [p|tail]}, options)
      :else -> {:error, {:tag_close_mismatch, section}}
    end
  end

  def matches(this) do
    Section.matches(get_in(this, [Access.key(:section_stack), Access.at(0)]))
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
  def add_alias(this, clause, at) do
    update_in(this, [Access.key(:section_stack), Access.at(0)], &(Section.add_alias(&1, clause, at)))
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
  def extract_selector(this, token, options \\ %{}) do
    case extended_extract_selector(this, token, options) do
      {:error, this} -> {:error, this}
      {{clause, _meta}, this} -> {clause, this}
    end
  end

  #----------------------------
  # extract_selector/3
  #----------------------------
  @doc """
    Parse clause to extract any operations/formulas and or bound variables.
    @returns Dynamic.Binding.Selector or Dynamic.Binding.HandleBarClause
  """
  def extended_extract_selector(this, token, options \\ %{})
  def extended_extract_selector(this, nil, _options), do: {{nil, nil}, this}
  def extended_extract_selector(this, token, options) do
    token = String.trim(token)
    cond do
      token == "this" || token == "." ->
        selector = current_selector(this)
        if Selector.valid?(selector, options) do
          {{selector, nil}, this}
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
            pipes = parse_pipes(token)
            case Selector.relative(selector, clean_token, parse_pipes(token), options) do
              {:error, clause} ->
                {:error, mark_error(this, clause, options)}
              selector -> {selector, this}
            end

          "!bind " <> clause ->
            case extended_extract_selector(this, clause, options) do
              {{%Selector{}, _meta} = selector, this} -> {selector, this}
              {:error, this} -> {:error, this}
              {_, _this} -> {:error, mark_error(this, :rule_engine_pending, options)}
            end

           "this." <> clause ->
           case Regex.run(~r/^this((?:[\.\[\]]@?[a-zA-Z0-9_]+)*)\]?(\s.*\|.*)?$/, token, capture: :all_but_first) do
             [""|_] -> {:error, mark_error(this, :parse, options)}
             [b|c] -> {:error, mark_error(this, clause, options)}
               b = Regex.scan(~r/[\.\[\]]@?[a-zA-Z0-9_]+/, b) |> List.flatten()
               case Selector.extend(current_selector(this), b, parse_pipes(c)) do
                 selector = {%Selector{}, _meta} -> {selector, this}
                 {:error, clause} -> {:error, mark_error(this, clause, options)}
               end
               _ ->
                 {:error, mark_error(this, {:invalid_token, token}, options)}
           end

          token ->
          case Regex.run(~r/^([a-zA-Z0-9_]+)((?:[\.\[\]]@?[a-zA-Z0-9_]+)*)\]?(\s.*\|.*)?$/, token, capture: :all_but_first) do
            [a,b|c] ->
              b = Regex.scan(~r/[\.\[\]]@?[a-zA-Z0-9_]+/, b) |> List.flatten()
              # todo check for existing match
              case Selector.new([a] ++ b, parse_pipes(c), matches(this)) do
                selector = {%Selector{}, _meta} -> {selector, this}
                {:error, clause} -> {:error, mark_error(this, clause, options)}
              end
              _ ->
                {:error, mark_error(this, {:invalid_token, token}, options)}
          end
        end
    end
  end
end

defimpl Noizu.RuleEngine.ScriptProtocol, for: Noizu.EmailService.Email.Binding.Dynamic do
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
    [root] = this.section_stack
    {r, s} = Noizu.RuleEngine.ScriptProtocol.execute!(root, state, context, options)
    Effective.finalize(r,s, context, options)
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
    id = identifier(this, state, context, options)
    v = "#{inspect this.selector}"
    t = String.slice(v, 0..64)
    t = if (t != v), do: t <> "...", else: t
    "#{prefix}#{id} [VALUE #{t}]\n"
  end
end