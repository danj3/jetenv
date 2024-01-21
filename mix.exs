defmodule Jetenv.MixProject do
  use Mix.Project

  def project do
    [
      app: :jetenv,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "Jetenv",
      source_url: "https://github.com/danj3/jetenv/tree/v-0.1.0",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp package do
    [
      exclude_patterns: [~r{.*~$}],
      description: description(),
      licenses: ["Apache-2.0"],
      links: %{
        "github" => "https://github.com/danj3/jetenv"
      }
    ]
  end

  defp description do
    """
    Full, single source runtime configuration from the ENV
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :public_key]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
