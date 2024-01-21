defmodule Jetenv.Encode do
  @moduledoc """
  Generate environment from config KWL
  """

  @doc """
  Encode input from Application.get_all_env. Provide `app` to
  add app key to tree, `prefix` for name prefix.
  """
  @spec from_config(keyword(), atom(), String.t()) :: [{String.t(), String.t()}]
  def from_config(config_kwl, app, prefix) do
    kw_to_tl(config_kwl, [app, prefix], [])
  end

  defp kw_to_tl(kwl, prefix, result)

  defp kw_to_tl([{k, v} | kwr], prefix, result) do
    if not is_atom(k), do: raise("key #{k} cannot be encoded")

    case v do
      [{_k, _v} | _] ->
        kw_to_tl(kwr, prefix, kw_to_tl(v, [fix_key(k) | prefix], result))

      _ ->
        case v do
          v2 when is_list(v2) ->
            encode_other(v2)

          v2 when is_binary(v2) ->
            {"S", v2}

          v2 when is_boolean(v2) ->
            {"B", to_string(v2)}

          v2 when is_float(v2) ->
            {"F", to_string(v2)}

          v2 when is_integer(v2) ->
            {"I", to_string(v2)}

          v2 when is_atom(v2) ->
            Atom.to_string(v2)
            |> case do
              "Elixir." <> m = _vs -> {"M", m}
              atm -> {"A", atm}
            end

          v2 ->
            encode_other(v2)
        end
        |> then(fn {suff, val} ->
          kw_to_tl(kwr, prefix, [genenv(suff, k, prefix, val) | result])
        end)
    end
  end

  defp kw_to_tl([], _prefix, result),
    do: result

  defp encode_other(thing) do
    types = type_walk(thing) |> Enum.uniq()

    cond do
      :atom in types -> encode_other_type(thing)
      :struct in types -> encode_other_type_armor(thing)
      :key_number in types -> encode_other_type(thing)
      :tuple in types -> encode_other_type(thing)
      true -> {"J", Jason.encode!(thing)}
    end
  end

  defp encode_other_type(value) do
    nval = encode_other_type_aux(value)

    {"G", nval}
  end

  defp encode_other_type_armor(value) do
    {"G", nval} = encode_other_type(value)
    {"T", Base.encode64(nval)}
  end

  defp encode_other_type_aux(value) do
    :io_lib.format("~w.", [value])
    |> :erlang.iolist_to_binary()
  end

  defp fix_key(tkey) do
    cond do
      is_atom(tkey) ->
        Atom.to_string(tkey)
        |> case do
          "Elixir." <> _ = m -> String.replace(m, ".", "_")
          m -> m
        end

      true ->
        tkey
    end
  end

  defp genenv(suff, tkey, prefix, val) do
    [suff, fix_key(tkey) | prefix]
    |> Enum.reverse()
    |> Enum.join("__")
    |> then(fn kn -> {kn, val} end)
  end

  defp type_walk(val, types \\ [])

  defp type_walk(val, types) when is_struct(val) do
    [:struct | types]
  end

  defp type_walk(val, types) when is_map(val) do
    type_walk(Map.to_list(val), [:map | types])
  end

  defp type_walk([{k, v} | rest], types) do
    key_check =
      case type_of(k) do
        :number -> :key_number
        other -> other
      end

    type_walk(rest, [key_check | type_walk(v, types)])
  end

  defp type_walk([v | rest], types) do
    type_walk(rest, type_walk(v, types))
  end

  defp type_walk([], types), do: types

  defp type_walk(v, types) do
    [type_of(v) | types]
  end

  defp type_of(ent) do
    cond do
      is_atom(ent) -> :atom
      is_binary(ent) -> :binary
      is_number(ent) -> :number
      is_list(ent) -> :list
      is_struct(ent) -> :struct
      is_map(ent) -> :map
      is_tuple(ent) -> :tuple
    end
  end
end
