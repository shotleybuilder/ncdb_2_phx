import Config

# Configure test-only repo for testing
config :ncdb_2_phx,
  ecto_repos: [NCDB2Phx.TestRepo]

# Configure the test database
config :ncdb_2_phx, NCDB2Phx.TestRepo,
  username: System.get_env("DATABASE_USER", "postgres"),
  password: System.get_env("DATABASE_PASSWORD", "postgres"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  database: "ncdb_2_phx_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: System.get_env("DATABASE_PORT", "5432") |> String.to_integer(),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails.
config :ncdb_2_phx, NCDB2Phx.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime