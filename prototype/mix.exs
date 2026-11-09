defmodule Behest.MixProject do
  use Mix.Project

  def project do
    [
      app: :behest,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib", "examples"]
  defp elixirc_paths(_), do: ["lib", "examples"]
end
