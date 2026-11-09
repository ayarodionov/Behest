defmodule Gcd.MixProject do
  use Mix.Project

  def project do
    [
      app: :gcd,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  def application, do: []

  defp deps do
    [{:stream_data, "~> 1.0", only: [:dev, :test]}]
  end
end
