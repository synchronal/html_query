defmodule HtmlQuery.MixProject do
  use Mix.Project

  @scm_url "https://github.com/synchronal/html_query"
  @version "0.2.1"

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def project do
    [
      app: :html_query,
      deps: deps(),
      description: "HTML query functions",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @scm_url,
      name: "HtmlQuery",
      package: package(),
      preferred_cli_env: [credo: :test, dialyzer: :test],
      source_url: @scm_url,
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  # # #

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:floki, "~> 0.32"},
      {:jason, "~> 1.3", optional: true},
      {:mix_audit, "~> 1.0", only: :dev, runtime: false},
      {:mix_test_interactive, "~> 1.2", only: :dev, runtime: false},
      {:moar, "~> 1.10"}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: ~w[lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*],
      licenses: ["MIT"],
      links: %{"GitHub" => @scm_url},
      maintainers: ["synchronal.dev", "Erik Hanson", "Eric Saxby"]
    ]
  end
end
