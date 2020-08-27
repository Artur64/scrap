defmodule Scrap.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrap,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:httpoison, "~> 1.7"},
      {:floki, "~> 0.27.0"}
      # Optional dependency, requires OS to have cmake and C compiler to work
      # {:fast_html, "~> 2.0"}
    ]
  end
end
