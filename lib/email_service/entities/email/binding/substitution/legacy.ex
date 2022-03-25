#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.EmailService.Email.Binding.Substitution.Legacy do
  @vsn 1.0
  #alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Selector
  #alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Section
  #alias Noizu.EmailService.Email.Binding.Substitution.Dynamic.Error
  #alias Noizu.EmailService.Email.Binding.Substitution.Dynamic, as: Binding
  @type t :: %__MODULE__{
               version: any,
               binding: MapSet.t | nil,
               vsn: float,
             }

  defstruct [
    version: nil,
    binding: nil,
    vsn: @vsn
  ]


  def effective_bindings(%__MODULE__{binding: substitutions}, input, context, _options) do
    {bound, unbound} = List.foldl(
      MapSet.to_list(substitutions),
      {%{}, []},
      fn(substitution, {bound, unbound}) ->
        case extract_binding(substitution, input, context) do
          {:error, details} ->
            {bound, unbound ++ [{substitution, {:error, details}}]}
          m ->
            {Map.put(bound, substitution, m), unbound}
        end
      end
    )

    %Noizu.EmailService.Email.Binding.Substitution.Legacy.Effective{
      bind: MapSet.to_list(substitutions),
      bound: bound,
      unbound: %{:optional => [], :required => unbound},
      outcome: length(unbound) > 0 && {:error, :unbound_fields} || :ok
    }
  end


  #-------------------------
  # extract_binding/3
  #-------------------------
  def extract_binding(binding, bindings, context) do
    value = if Map.has_key?(bindings, binding) do
      # Allow Overrides of fields otherwise yanked from EAV, Structs, etc.
              bindings[binding]
    else
      case String.split(binding, ".") do
        ["site"] -> extract_inner_site()
        ["EAV"| specifier] -> extract_inner_eav(specifier, context)
        path -> extract_inner_path(path, bindings, context)
      end
            end

    case value do
      {:error, details} -> {:error, details}
      _ -> Noizu.Proto.EmailBind.format(value)
    end
  end # end extract_binding/2

  #-------------------------
  # extract_inner_site/0
  #-------------------------
  defp extract_inner_site() do
    case Application.get_env(:sendgrid, :email_site_url) do
      nil -> {:error, :email_sit_url_not_set}
      m -> m
    end
  end # end extract_inner/1

  #-------------------------
  # extract_inner_eav/1
  #-------------------------
  defp extract_inner_eav(_path, _context) do
    #@TODO _path ->  ref.type.id|attribute
    #@TODO pending EAV table implementation.
    {:error, :eav_lookup_nyi}
  end # end extract_inner/2

  #-------------------------
  # extract_inner_path/3
  #-------------------------
  defp extract_inner_path([] = _path, current, _context) do
    current
  end # end extract_inner/3

  defp extract_inner_path([h|t] = _path, %{} = current, context) do
    matching_key = Map.keys(current)
                   |> Enum.find(&("#{&1}" == h))
    cond do
      matching_key == nil && h == "EAV" ->
        # @TODO Noizu.ERP.ref(current) -> EAV fetch
        {:error, :eav_lookup_nyi}
      matching_key == nil -> {:error, "#{h} key not found."}
      true -> extract_inner_path(t, Map.get(current, matching_key), context)
    end
  end # end extract_inner/3




  @doc """
    Parse input string and extract (including conditional qualifiers) data needed to populate template.
  """
  def extract(block, options \\ %{})
  def extract(%SendGrid.Template.Version{} = version, options) do
    this = extract((version.subject || "") <>  (version.html_content || "") <> (version.plain_content || ""), options)
    %__MODULE__{this| version: version.id}
  end
  def extract(block, _options) when is_bitstring(block) do
    bind = case Regex.scan(~r/-\{([a-zA-Z0-9\._\[\]]+)\}-/, block, capture: :all_but_first) do
      nil -> MapSet.new()
      matches when is_list(matches) ->
        matches
        |> List.flatten
        |> MapSet.new
    end
    %__MODULE__{binding: bind}
  end
end