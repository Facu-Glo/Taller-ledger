defmodule Ledger.MixProject do
  use Mix.Project

  def project do
    [
      app: :leadger,
      version: "0.1.0",
      elixir: "~> 1.18",
      escript: [main_module: Ledger],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:csv, "~> 3.2"},
      {:decimal, "~> 2.0"},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end
end
