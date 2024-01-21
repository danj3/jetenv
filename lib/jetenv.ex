defmodule Jetenv do
  @moduledoc """
  Directly map environment variables into the application
  configuration at runtime including type conversion and
  complex type bundling.

  # Types supported

  * S - String
  * A - Atom
  * I - Integer
  * B - boolean (true or TRUE is true all else is false)
  * F - Float
  * M - Module name
  * C - charlist
  * J - JSON encoded string
  * G - Erlang term
  * T - Base64 encoded Erlang term
  * PEM - PEM string, see note below

  Type specifiers are required suffixes, two underscores and the
  type, e.g.:

  ```
  je__my_app__some_string__S="a string value"
  ```

  ### PEM handling

  PEM strings are decoded using :public_key, however the usual
  consumers of the results (private key or cert) expect
  different things than what :public_key returns. The PEM
  handler provides values appropriate for use in `ssl_opts`
  `cacert` and `key`.

  ### Modules in keys

  There is a special case for representing a module name
  in the key string. This often occurs for configuring
  ecto Repos.

  A module will be detected by starting with `Elixir`.
  Underscores will be effectively translated to dots.

  Example:

  ```
  je__my_app__Elixir_MyApp_Repo__database__S=mydb
  ```

  """

  @typedoc """
  Common run options are:

  * prefix: String.t - the string a name starts with for discovery

  """
  @type run_options :: keyword()

  @doc """
  The default is `je` but can be overridden by setting the
  environment variable `jetenv_prefix`. This function
  returns the prefix in effect.

  If options are not provided to load functions, this
  will provide the default.
  """
  @spec prefix_env() :: String.t()
  def prefix_env do
    System.get_env("jetenv_prefix", "je")
  end

  @doc """
  Processes values from the environment into a nested
  Keyword list suitable for use in runtime.exs or
  as confg to `Application.put_all_env/2`.

  This variant will filter out non-loaded applications.

  Prefix can be specified to override environment.

  See `t:run_options/0`
  """
  @spec load_env(run_options() | []) :: keyword()
  def load_env(opts \\ []) do
    load_all_env(opts)
    |> filter_loaded
  end

  @doc """
  Same as `load_env/1` except does not filter out
  config against loaded applications.

  See `t:run_options/0`

  """
  @spec load_all_env(run_options() | []) :: keyword()
  def load_all_env(opts \\ []) do
    System.get_env()
    |> load(opts)
  end

  @doc """
  Accepts a map (such as from `System.get_env/0`)
  and generates a config tree.

  See `t:run_options/0`
  """
  @spec load(%{String.t() => String.t()}, run_options | []) :: keyword()
  def load(env_map, opts \\ []) do
    env_map
    |> prefix_filter(Keyword.get(opts, :prefix, prefix_env()))
    |> Jetenv.Decode.decode([])
  end

  defp filter_loaded(config) do
    loaded = Application.loaded_applications() |> Enum.map(&elem(&1, 0))

    Enum.filter(
      config,
      fn {app, _stuff} ->
        app in loaded
      end
    )
  end

  defp prefix_filter(env_map, prefix) do
    ps = (prefix || prefix_env()) <> "__"

    Enum.reduce(env_map, [], fn {k, v}, acc ->
      if String.starts_with?(k, ps) do
        [{String.replace_prefix(k, ps, ""), v} | acc]
      else
        acc
      end
    end)
  end
end
