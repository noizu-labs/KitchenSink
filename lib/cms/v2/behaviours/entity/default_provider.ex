#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2020 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Cms.V2.Entity.DefaultProvider do
  defmacro __using__(_options) do
    quote do
      @revision_format ~r/^(.*)@([0-9a-zA-Z][0-9a-zA-Z\.]*)-([0-9a-zA-Z]+)$/
      @version_format ~r/^(.*)@([0-9a-zA-Z][0-9a-zA-Z\.]*)$/

                        # @todo modify to allow overriding just article_string_to_id, article_id_to_string()
                        #------------------------------
                        # string_to_id
                        #------------------------------
      def string_to_id(nil, _caller), do: nil
      def string_to_id(identifier, caller) when is_bitstring(identifier) do
        case identifier do
          "ref." <> _ -> {:error, {:unsupported, identifier}}
          _ ->
            cond do
              Regex.match?(@revision_format, identifier) ->
                case Regex.run(@revision_format, identifier) do
                  [_, identifier, version, revision] ->
                    case caller.article_string_to_id(identifier) do
                      {:ok, i} ->
                        version_path = String.split(version, ".")
                                       |> Enum.map(
                                            fn(x) ->
                                              case Integer.parse(x) do
                                                {v, ""} -> v
                                                _ -> x
                                              end
                                            end)
                                       |> List.to_tuple()
                        revision = case Integer.parse(revision) do
                          {v, ""} -> v
                          _ -> revision
                        end
                        {:revision, {i, version_path, revision}}
                      _ -> {:error, {:unsupported, identifier}}
                    end
                  _ ->  {:error, {:unsupported, identifier}}
                end

              Regex.match?(@version_format, identifier) ->
                case Regex.run(@version_format, identifier) do
                  [_, identifier, version] ->
                    case caller.article_string_to_id(identifier) do
                      {:ok, i} ->
                        version_path = String.split(version, ".")
                                       |> Enum.map(
                                            fn(x) ->
                                              case Integer.parse(x) do
                                                {v, ""} -> v
                                                _ -> x
                                              end
                                            end)
                                       |> List.to_tuple()
                        {:version, {i, version_path}}
                      _ -> {:error, {:unsupported, identifier}}
                    end
                  _ ->  {:error, {:unsupported, identifier}}
                end

              true -> caller.article_string_to_id(identifier)
            end
        end
      end
      def string_to_id(i, _caller), do: {:error, {:unsupported, i}}

      #------------------------------
      # id_to_string
      #------------------------------
      def id_to_string(identifier, caller) do
        case identifier do
          nil -> nil
          {:revision, {i,v,r}} ->
            cond do
              i == nil -> {:error, {:unsupported, identifier}}
              !is_tuple(v) -> {:error, {:unsupported, identifier}}
              r == nil -> {:error, {:unsupported, identifier}}
              !(is_integer(r) || is_bitstring(r) || is_atom(r)) -> {:error, {:unsupported, identifier}}
              String.contains?("#{r}", ["-", "@"]) -> {:error, {:unsupported, identifier}}
              vp = caller.version_path_to_string(v) ->
                case caller.article_id_to_string(i) do
                  {:ok, id} -> {:ok, "#{id}@#{vp}-#{r}"}
                  _ -> {:error, {:unsupported, identifier}}
                end
              true -> {:error, {:unsupported, identifier}}
            end
          {:version, {i,v}} ->
            cond do
              i == nil -> {:error, {:unsupported, identifier}}
              !is_tuple(v) -> {:error, {:unsupported, identifier}}
              vp = caller.version_path_to_string(v) ->
                case caller.article_id_to_string(i) do
                  {:ok, id} -> {:ok, "#{id}@#{vp}"}
                  _ -> {:error, {:unsupported, identifier}}
                end
              true -> {:error, {:unsupported, identifier}}
            end
          _ -> caller.article_id_to_string(identifier)
        end
      end

      #------------------------------
      # version_path_to_string/2
      #------------------------------
      def version_path_to_string(version_path, _caller) do
        v_l = Tuple.to_list(version_path)
        v_err = Enum.any?(v_l, fn(x) ->
          cond do
            x == nil -> true
            !(is_bitstring(x) || is_integer(x) || is_atom(x)) -> true
            String.contains?("#{x}", [".", "-", "@"]) -> true
            true -> false
          end
        end)
        cond do
          length(v_l) == 0 -> nil
          v_err -> nil
          true -> Enum.map(v_l, &("#{&1}")) |> Enum.join(".")
        end
      end


      #------------------------------
      # article_string_to_id
      #------------------------------
      @doc """
        override this if your entity type uses string values, nested refs, etc. for it's identifier.
      """
      def article_string_to_id(nil, _caller), do: nil
      def article_string_to_id(identifier, _caller) when is_bitstring(identifier) do
        case identifier do
          "ref." <> _ -> {:error, {:unsupported, identifier}}
          _ ->
            case Integer.parse(identifier) do
              {id, ""} -> {:ok, id}
              v -> {:error, {:parse, v}}
            end
        end
      end
      def article_string_to_id(i, _caller), do: {:error, {:unsupported, i}}

      #------------------------------
      # article_id_to_string
      #------------------------------
      @doc """
        override this if your entity type uses string values, nested refs, etc. for it's identifier.
      """
      def article_id_to_string(identifier, _caller) do
        cond do
          is_integer(identifier) -> {:ok, "#{identifier}"}
          is_atom(identifier) -> {:ok, "#{identifier}"}
          is_bitstring(identifier) -> {:ok, "#{identifier}"}
          true -> {:error, {:unsupported, identifier}}
        end
      end


      #-------------------------
      # Overridable
      #-------------------------
      defoverridable [
        string_to_id: 2,
        id_to_string: 2,
        article_string_to_id: 2,
        article_id_to_string: 2,
      ]


    end
  end
end
