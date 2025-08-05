import Config

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails.
config :airtable_sync_phoenix, AirtableSyncPhoenix.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime