defmodule Mix.Tasks.Jetenv.Generate do
  @moduledoc """
  generate output suitable for input to:

  * --docker docker api json
  * --js javascript/json key/val dictionary
  * --sh shell environment variable eval-able
  * no option, plain json

  positional arguments, otp application names to generate

  customize prefix (default is 'je') with --prefix

  json environment suitable for docker api
  """

  @shortdoc "generate output for building environment"

  use Mix.Task
  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {switches, apps, []} =
      OptionParser.parse(
        args,
        strict: [
          prefix: :string,
          docker: :boolean,
          js: :boolean,
          sh: :boolean
        ]
      )

    prefix = Keyword.get(switches, :prefix, "je")

    apps
    |> Enum.map(&String.to_existing_atom/1)
    |> Enum.flat_map(fn app ->
      Application.get_all_env(app)
      |> Jetenv.Encode.from_config(app, prefix)
    end)
    |> wrapping(switches)
    |> IO.puts()
  end

  def wrapping(conf, opts) do
    cond do
      opts[:js] ->
        Map.new(conf)
        |> Jason.encode!(pretty: true)

      opts[:docker] ->
        %{
          "Env" => Enum.map(conf, fn {k, v} -> "#{k}=#{v}" end)
        }
        |> Jason.encode!(pretty: true)

      opts[:sh] ->
        Enum.map(conf, fn {k, v} -> "#{k}=\"#{esc(v)}\"" end)
        |> Enum.join("\n")

      true ->
        Enum.map(conf, fn {k, v} -> "#{k}=#{v}" end)
        |> Jason.encode!(pretty: true)
    end
  end

  defp esc(val) do
    String.codepoints(val)
    |> Enum.flat_map(fn cc ->
      case cc do
        "\t" -> ["\\", "t"]
        "\n" -> ["\\", "n"]
        "\"" -> ["\\", "\""]
        cx -> [cx]
      end
    end)
    |> Enum.join()
  end
end
