#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2019 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Entity.DefaultImplementation do
  @revision_format ~r/^(.*)@([0-9\.]*)-([0-9]*)$/

                     # @todo modify to allow overriding just article_string_to_id, article_id_to_string()
                     #------------------------------
                     # string_to_id
                     #------------------------------
  def string_to_id(nil), do: nil
  def string_to_id(identifier) when is_bitstring(identifier) do
    case identifier do
      "ref." <> _ -> {:error, {:unsupported, identifier}}
      _ ->
        if Regex.match?(@revision_format, identifier) do
          case Regex.run(@revision_format, identifier) do
            [_, identifier, version, revision] ->
              case article_string_to_id(identifier) do
                {:ok, i} ->
                  version_path = String.split(version, ".") |> Enum.map(&(String.to_integer(&1))) |> List.to_tuple()
                  revision_number = String.to_integer(revision)
                  {:revision, {i, version_path, revision_number}}
                _ -> {:error, {:unsupported, identifier}}
              end
            _ ->  {:error, {:unsupported, identifier}}
          end
        else
          article_string_to_id(identifier)
        end
    end
  end
  def string_to_id(i), do: {:error, {:unsupported, i}}

  #------------------------------
  # id_to_string
  #------------------------------
  def id_to_string(identifier) do
    case identifier do
      nil -> nil
      {:revision, {i,v,r}} ->
        case article_id_to_string(i) do
          {:ok, id} ->
            vp = Tuple.to_list(v)
                 |> Enum.map(&("#{&1}"))
                 |> Enum.join(".")
            {:ok, "#{id}@#{vp}-#{r}"}
          _ -> {:error, {:unsupported, identifier}}
        end
      _ -> article_id_to_string(identifier)
    end
  end


  #------------------------------
  # article_string_to_id
  #------------------------------
  @doc """
    override this if your entity type uses string values, nested refs, etc. for it's identifier.
  """
  def article_string_to_id(nil), do: nil
  def article_string_to_id(identifier) when is_bitstring(identifier) do
    case identifier do
      "ref." <> _ -> {:error, {:unsupported, identifier}}
      _ ->
        case Integer.parse(identifier) do
          {id, ""} -> {:ok, id}
          v -> {:error, {:parse, v}}
        end
    end
  end
  def article_string_to_id(i), do: {:error, {:unsupported, i}}

  #------------------------------
  # article_id_to_string
  #------------------------------
  @doc """
    override this if your entity type uses string values, nested refs, etc. for it's identifier.
  """
  def article_id_to_string(identifier), do: {:ok, "#{identifier}"}


end