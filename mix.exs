defmodule NCDB2Phx.MixProject do
  use Mix.Project

  @version "0.2.5"
  @description "A comprehensive, production-ready import engine for Phoenix applications using Ash Framework. Enables importing data from no-code databases (Airtable, Baserow, Notion) and other sources (CSV, APIs, databases) with real-time progress tracking, error handling, and LiveView admin interface."
  @source_url "https://github.com/shotleybuilder/ncdb_2_phx"
  @homepage_url "https://github.com/shotleybuilder/ncdb_2_phx"

  def project do
    [
      app: :ncdb_2_phx,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      
      # Hex.pm metadata
      description: @description,
      source_url: @source_url,
      homepage_url: @homepage_url,
      name: "NCDB2Phx",
      
      # Test coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Core Phoenix/Ash dependencies
      {:phoenix, "~> 1.7.14 or ~> 1.8.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      
      # Ash Framework
      {:ash, "~> 3.0"},
      {:ash_postgres, "~> 2.0"},
      {:ash_phoenix, "~> 2.0"},
      
      # HTTP clients and JSON
      {:req, "~> 0.5.0"},
      {:tesla, "~> 1.8"},
      {:jason, "~> 1.4"},
      
      # Database and migrations
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.16"},
      
      # Process monitoring and PubSub
      {:phoenix_pubsub, "~> 2.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      
      # Email
      {:swoosh, "~> 1.16"},
      
      # Development and testing tools
      {:floki, ">= 0.30.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ash.codegen", "run priv/repo/seeds.exs"],
      test: ["ecto.create --quiet", "test"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets npm run build"],
      "assets.deploy": ["cmd --cd assets npm run build", "phx.digest"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "NCDB2Phx",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/ncdb_2_phx",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/installation.md",
        "guides/quickstart.md",
        "guides/adapters.md",
        "guides/configuration.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\/.?/
      ],
      groups_for_modules: [
        "Core Components": [
          NCDB2Phx,
          NCDB2Phx.SyncEngine
        ],
        "Utilities": [
          NCDB2Phx.Utilities.ConfigValidator,
          NCDB2Phx.Utilities.SourceAdapter,
          NCDB2Phx.Utilities.TargetProcessor,
          NCDB2Phx.Utilities.ProgressTracker,
          NCDB2Phx.Utilities.ErrorHandler,
          NCDB2Phx.Utilities.RecordTransformer,
          NCDB2Phx.Utilities.RecordValidator,
          NCDB2Phx.Utilities.Validations
        ],
        "Resources": [
          NCDB2Phx.Resources.SyncSession,
          NCDB2Phx.Resources.SyncBatch,
          NCDB2Phx.Resources.SyncLog
        ],
        "Adapters": [
          NCDB2Phx.Adapters.AirtableAdapter
        ],
        "Systems": [
          NCDB2Phx.Systems.EventSystem
        ],
        "Components": [
          NCDB2Phx.Components.SyncComponents
        ]
      ]
    ]
  end

  defp package do
    [
      # Core package info
      name: "ncdb_2_phx",
      description: @description,
      files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* guides),
      licenses: ["Apache-2.0"],
      
      # Maintainers and contributors
      maintainers: [
        "NCDB2Phx Team <contact@shotleybuilder.com>"
      ],
      
      # Package links
      links: %{
        "Homepage" => @homepage_url,
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/ncdb_2_phx",
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Issues" => "#{@source_url}/issues",
        "Discussions" => "#{@source_url}/discussions"
      },
      
      # Hex.pm specific metadata
      repository: "hexpm",
      
      # Package categories for discoverability
      extra: %{
        "categories" => ["phoenix", "ash", "sync", "data-integration", "airtable"],
        "keywords" => [
          "phoenix", "ash", "elixir", "sync", "data-sync", "airtable", 
          "csv", "api", "real-time", "liveview", "batch-processing",
          "data-integration", "etl", "migration", "import", "export"
        ]
      }
    ]
  end
end