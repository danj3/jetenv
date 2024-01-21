defmodule Jetenv.Decode do
  @moduledoc """
  Key and value decoding.
  """

  @doc """
  Convert environment style key/values into a configuration.

  Keys are expected to be keyword path strings separated
  by double underscores with a trailing type specifier.

  Derives a deep Keyword path from the key provided.
  Performs type conversion of value based on type suffix.

  See `Jetenv` for type information.

  """
  @spec decode([{String.t(), String.t()}, ...], keyword()) :: keyword()
  def decode([{key, val} | rest], tree) do
    [type | path] = String.split(key, "__") |> Enum.reverse()
    config_path = path_to_config_path(path)

    config_val = decode_type({type, val})
    decode(rest, tree_merge(config_path, config_val, tree))
  end

  def decode([], tree), do: tree

  defp decode_type({"S", val}), do: val
  defp decode_type({"A", a}), do: String.to_atom(a)
  defp decode_type({"I", i}), do: String.to_integer(i)
  defp decode_type({"B", val}), do: val in ["true", "TRUE"]
  defp decode_type({"F", f}), do: String.to_float(f)
  defp decode_type({"M", m}), do: Module.concat([m])
  defp decode_type({"C", c}), do: String.to_charlist(c)
  defp decode_type({"J", c}), do: Jason.decode!(c)

  defp decode_type({"T", val}),
    do: decode_type({"G", Base.decode64!(val)})

  defp decode_type({"G", val}) do
    {:ok, term, _} =
      val
      |> String.to_charlist()
      |> :erl_scan.string()

    {:ok, native} = :erl_parse.parse_term(term)
    native
  end

  defp decode_type({"PEM", val}) do
    :public_key.pem_decode(val)
    |> pk_format()
  end

  defp pk_format([{:PrivateKeyInfo, pk, :not_encrypted} | _]) do
    {:PrivateKeyInfo, pk}
  end

  defp pk_format([{:Certificate, ct, :not_encrypted} | rest]) do
    [ct | pk_format(rest)]
  end

  defp pk_format([]), do: []

  defp path_to_config_path(path) do
    Enum.map(path, &path_element/1)
  end

  defp path_element(elm) do
    case elm do
      "Elixir_" <> _ = modname ->
        Module.concat([String.replace(modname, "_", ".")])

      str ->
        String.to_atom(str)
    end
  end

  defp tree_merge(config_path, config_val, tree) do
    Keyword.merge(
      tree,
      path_branch(config_path, config_val),
      &merge_branch/3
    )
  end

  defp merge_branch(_key, a, b) do
    Keyword.merge(a, b, &merge_branch/3)
  end

  defp path_branch(config_path, config_val) do
    Enum.reduce(config_path, config_val, fn path_parent, path_child ->
      [{path_parent, path_child}]
    end)
  end
end
