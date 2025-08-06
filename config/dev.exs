import Config

# Configure dev-only repo for development (optional)
config :ncdb_2_phx,
  ecto_repos: [NCDB2Phx.DevRepo]

# Configure the development database
config :ncdb_2_phx, NCDB2Phx.DevRepo,
  username: System.get_env("DATABASE_USER", "postgres"),
  password: System.get_env("DATABASE_PASSWORD", "postgres"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  database: "ncdb_2_phx_dev",
  port: System.get_env("DATABASE_PORT", "5432") |> String.to_integer(),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime