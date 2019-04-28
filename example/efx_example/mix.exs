defmodule EfxExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :efx_example,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: [:yecc, :leex, :erlang, :efx, :xref, :app],
      aliases: ["deps.compile": ["efx.precompile", "deps.compile"]],
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
      {:efx, path: "../.."},
      # Library to test replacing in deps
      {:httpoison, "~> 1.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
