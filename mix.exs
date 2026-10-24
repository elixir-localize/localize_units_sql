defmodule Localize.Units.Sql.Mixfile do
  use Mix.Project

  @version "2.1.0"

  def project do
    [
      app: :localize_units_sql,
      version: @version,
      elixir: "~> 1.17",
      name: "Localize Units SQL",
      source_url: "https://github.com/elixir-localize/localize_units_sql",
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps: ~w(inets mix ecto ecto_sql eex localize)a
      ],
      compilers: Mix.compilers()
    ]
  end

  defp description do
    "Unit functions for the serialization to a database of a Localize.Unit.t data type.
    Also includes aggregation and sum functions."
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/elixir-localize/localize_units_sql",
        "Readme" =>
          "https://github.com/elixir-localize/localize_units_sql/blob/v#{@version}/README.md",
        "Changelog" =>
          "https://github.com/elixir-localize/localize_units_sql/blob/v#{@version}/CHANGELOG.md"
      },
      files: [
        "lib",
        "priv/SQL",
        "config",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE.md"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      main: "readme",
      logo: "logo.png",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md", "README.md"],
      formatters: ["html", "markdown"]
    ]
  end

  defp aliases do
    [
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp deps do
    [
      {:localize, "~> 1.4"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.19"},
      {:benchee, "~> 1.0", optional: true, only: :dev, runtime: false},
      {:exprof, "~> 0.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev, :release], runtime: false},
      {:earmark, "~> 1.4", only: [:dev, :release], runtime: false}
    ] ++ maybe_json_polyfill()
  end

  defp maybe_json_polyfill do
    if Code.ensure_loaded?(:json) do
      []
    else
      [{:json_polyfill, "~> 0.2 or ~> 1.0"}]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
