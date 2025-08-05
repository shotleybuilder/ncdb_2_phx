defmodule AirtableSyncPhoenix.MixProject do
  use Mix.Project

  @version "1.0.0"
  @description "A comprehensive, production-ready sync engine for Phoenix applications using Ash Framework. Enables syncing data from external sources (Airtable, CSV, APIs, databases) with real-time progress tracking, error handling, and LiveView admin interface."
  @source_url "https://github.com/shotleybuilder/airtable_sync_phoenix"
  @homepage_url "https://github.com/shotleybuilder/airtable_sync_phoenix"

  def project do
    [
      app: :airtable_sync_phoenix,
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
      name: "AirtableSyncPhoenix",
      
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
      mod: {AirtableSyncPhoenix.Application, []},
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
      {:phoenix, "~> 1.7.14"},
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
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build"],
      "ash.setup": ["ash.create", "ash.migrate", "run priv/repo/seeds.exs"],
      "ash.reset": ["ash.drop", "ash.setup"],
      "ash.migrate": ["ash.codegen --check", "ash.migrate"],
      test: ["ash.create --quiet", "ash.migrate --quiet", "test"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets npm run build"],
      "assets.deploy": ["cmd --cd assets npm run build", "phx.digest"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "AirtableSyncPhoenix",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/airtable_sync_phoenix",
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
          AirtableSyncPhoenix,
          AirtableSyncPhoenix.SyncEngine
        ],
        "Utilities": [
          AirtableSyncPhoenix.Utilities.ConfigValidator,
          AirtableSyncPhoenix.Utilities.SourceAdapter,
          AirtableSyncPhoenix.Utilities.TargetProcessor,
          AirtableSyncPhoenix.Utilities.ProgressTracker,
          AirtableSyncPhoenix.Utilities.ErrorHandler,
          AirtableSyncPhoenix.Utilities.RecordTransformer,
          AirtableSyncPhoenix.Utilities.RecordValidator,
          AirtableSyncPhoenix.Utilities.Validations
        ],
        "Resources": [
          AirtableSyncPhoenix.Resources.SyncSession,
          AirtableSyncPhoenix.Resources.SyncBatch,
          AirtableSyncPhoenix.Resources.SyncLog
        ],
        "Adapters": [
          AirtableSyncPhoenix.Adapters.AirtableAdapter
        ],
        "Systems": [
          AirtableSyncPhoenix.Systems.EventSystem
        ],
        "Components": [
          AirtableSyncPhoenix.Components.SyncComponents
        ]
      ]
    ]
  end

  defp package do
    [
      # Core package info
      name: "airtable_sync_phoenix",
      description: @description,
      files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* guides),
      licenses: ["Apache-2.0"],
      
      # Maintainers and contributors
      maintainers: [
        "AirtableSyncPhoenix Team <contact@airtable-sync-phoenix.dev>"
      ],
      
      # Package links
      links: %{
        "Homepage" => @homepage_url,
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/airtable_sync_phoenix",
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