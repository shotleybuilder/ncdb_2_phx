# Configuration Guide

This guide covers all configuration options for NCDB2Phx, from basic setup to advanced performance tuning.

## Overview

NCDB2Phx configuration happens at three levels:
1. **Application Configuration** - Global defaults in config files
2. **Sync Configuration** - Per-sync operation settings
3. **Runtime Configuration** - Environment variables and dynamic settings

## Application Configuration

Set global defaults in your application configuration:

### Basic Configuration

```elixir
# config/config.exs
config :ncdb_2_phx,
  # Default processing settings
  default_batch_size: 100,
  default_timeout: 30_000,
  default_max_retries: 3,
  
  # PubSub configuration
  pubsub_module: MyApp.PubSub,
  default_progress_topic: "sync_progress",
  
  # Error handling
  enable_error_recovery: true,
  enable_detailed_logging: true,
  
  # Admin interface
  enable_admin_interface: true
```

### Router Configuration

Configure the admin interface router with various customization options:

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  
  import NCDB2Phx.Router
  
  # Basic admin interface
  scope "/admin" do
    pipe_through [:browser, :admin]
    ncdb_sync_routes "/sync"
  end
  
  # Advanced configuration with all options
  scope "/admin" do 
    pipe_through [:browser, :admin]
    ncdb_sync_routes "/sync",
      # Route customization
      as: :admin_sync,                    # Route helper prefix (default: :ncdb_sync)
      live_session_name: :admin_session,  # LiveView session name (default: :ncdb_sync_session)
      
      # Layout customization
      root_layout: {MyAppWeb.Layouts, :admin},  # Use custom admin layout
      
      # Session arguments (available in all LiveViews)
      session_args: %{
        "current_user_id" => "user_context",
        "user_permissions" => "sync_permissions",
        "organization_id" => "current_org_id"
      },
      
      # Private router data (for custom middleware)
      private: %{
        authentication_required: true,
        audit_logging: true,
        feature_flags: ["admin_interface", "sync_monitoring"]
      }
  end
end
```

### Admin Interface Configuration

Control admin interface features and behavior:

```elixir
# config/config.exs
config :ncdb_2_phx,
  admin_interface: %{
    # Authentication
    require_authentication: true,
    session_timeout: 3600,              # 1 hour session timeout
    
    # UI customization
    theme: :default,                     # :default, :dark, :light, or custom module
    brand_name: "My Company Sync Admin",
    logo_url: "/assets/images/logo.png",
    favicon_url: "/assets/images/favicon.ico",
    
    # Feature toggles
    enable_session_creation: true,       # Allow creating new syncs via UI
    enable_session_editing: true,        # Allow editing sync configurations
    enable_session_cancellation: true,   # Allow canceling running syncs
    enable_batch_analysis: true,         # Show detailed batch analysis
    enable_log_streaming: true,          # Real-time log streaming
    enable_system_monitoring: true,      # System health monitoring
    enable_configuration_ui: true,       # Configuration management UI
    
    # Performance settings
    default_page_size: 25,               # Records per page in lists
    max_page_size: 100,                  # Maximum allowed page size
    real_time_update_interval: 1000,     # LiveView update interval (ms)
    log_buffer_size: 1000,              # Log entries to buffer for streaming
    
    # Data retention
    session_retention_days: 90,          # Keep session data for 90 days
    log_retention_days: 30,             # Keep detailed logs for 30 days
    
    # Export options
    enable_csv_export: true,            # Enable CSV exports
    enable_json_export: true,           # Enable JSON exports
    max_export_records: 10000,          # Limit exported records
    
    # API configuration
    api_rate_limit: 100,                # API requests per minute per user
    api_timeout: 30_000,                # API request timeout (ms)
    enable_api_docs: true               # Enable built-in API documentation
  }
```

### LiveView Session Configuration

Configure LiveView sessions for the admin interface:

```elixir
# lib/my_app_web/router.ex
scope "/admin" do
  pipe_through [:browser, :admin]
  
  ncdb_sync_routes "/sync",
    # LiveView session configuration
    session_args: %{
      # Authentication context
      "current_user_id" => fn conn -> 
        get_session(conn, :current_user_id) 
      end,
      "user_permissions" => fn conn ->
        conn.assigns[:current_user].permissions
      end,
      
      # Organization/tenant context
      "current_tenant_id" => fn conn ->
        conn.assigns[:current_tenant]&.id
      end,
      
      # Feature flags
      "feature_flags" => fn conn ->
        get_user_feature_flags(conn.assigns[:current_user])
      end,
      
      # Custom theme/branding
      "theme_config" => fn conn ->
        get_tenant_theme_config(conn.assigns[:current_tenant])
      end,
      
      # Audit trail
      "session_metadata" => fn conn ->
        %{
          ip_address: get_peer_data(conn).address |> Tuple.to_list() |> Enum.join("."),
          user_agent: get_req_header(conn, "user-agent") |> List.first(),
          created_at: DateTime.utc_now()
        }
      end
    }
end
```

### Environment-Specific Configuration

```elixir
# config/dev.exs
config :ncdb_2_phx,
  default_batch_size: 25,           # Smaller batches for development
  default_timeout: 15_000,          # Shorter timeout for faster feedback
  enable_detailed_logging: true,    # Verbose logging for debugging
  debug_mode: true                  # Additional debug features

# config/test.exs  
config :ncdb_2_phx,
  default_batch_size: 5,            # Very small batches for tests
  default_timeout: 5_000,           # Quick timeouts for fast tests
  enable_detailed_logging: false,   # Reduce test noise
  enable_progress_tracking: false   # Skip progress tracking in tests

# config/prod.exs
config :ncdb_2_phx,
  default_batch_size: 500,          # Larger batches for efficiency
  default_timeout: 120_000,         # 2 minute timeout for large syncs
  enable_detailed_logging: false,   # Reduce log volume
  enable_performance_monitoring: true
```

## Sync Configuration

Each sync operation accepts a detailed configuration map:

### Complete Sync Configuration

```elixir
config = %{
  # Source configuration
  source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
  source_config: %{
    api_key: System.get_env("AIRTABLE_API_KEY"),
    base_id: "appXXXXXXXXXXXXXX",
    table_id: "tblXXXXXXXXXXXXXX",
    view_id: "viwXXXXXXXXXXXXXX",        # Optional: filter to specific view
    fields: ["Name", "Email", "Status"],  # Optional: limit fields
    filter_by_formula: "NOT({Status} = 'Inactive')",  # Optional: Airtable formula
    sort: [%{field: "Created", direction: "asc"}],     # Optional: sort order
    max_records: 1000,                    # Optional: limit total records
    page_size: 100                        # Optional: records per API call
  },
  
  # Target configuration
  target_resource: MyApp.Accounts.User,
  target_config: %{
    unique_field: :email,                 # Field to check for duplicates
    create_action: :create,               # Ash action for creating records
    update_action: :update,               # Ash action for updating records
    upsert_action: :upsert,              # Optional: combined create/update action
    domain: MyApp.Accounts,              # Optional: explicit domain
    enable_policies: true,               # Optional: enable Ash policies
    additional_attributes: %{            # Optional: add computed fields
      source_system: "airtable",
      synced_at: fn -> DateTime.utc_now() end
    }
  },
  
  # Processing configuration  
  processing_config: %{
    batch_size: 100,                     # Records per batch
    limit: nil,                          # Total record limit (nil = no limit)
    timeout: 30_000,                     # Timeout per batch (ms)
    
    # Error handling
    enable_error_recovery: true,         # Retry failed records
    max_retries: 3,                      # Max retries per record
    retry_backoff: :exponential,         # :linear, :exponential, or custom function
    stop_on_error: false,                # Continue despite errors
    error_threshold: 0.1,                # Stop if >10% error rate
    
    # Progress tracking
    enable_progress_tracking: true,      # Real-time progress updates
    progress_interval: 1000,             # Progress update frequency (ms)
    enable_batch_callbacks: true,        # Callbacks after each batch
    
    # Data transformation
    record_transformer: &MyApp.Transformers.user_transformer/3,
    record_validator: &MyApp.Validators.user_validator/2,
    record_filter: &MyApp.Filters.active_users_only/2,
    
    # Performance tuning
    enable_streaming: true,              # Stream records vs batch loading
    stream_chunk_size: 1000,            # Records per stream chunk
    enable_parallel_processing: false,   # Process batches in parallel
    parallel_workers: 4,                 # Number of parallel workers
    
    # Debugging
    enable_detailed_logging: false,      # Detailed operation logs
    log_record_data: false,             # Log individual record data (careful!)
    debug_mode: false,                  # Additional debug features
    dry_run: false                      # Preview changes without applying
  },
  
  # PubSub configuration
  pubsub_config: %{
    module: MyApp.PubSub,               # Your PubSub module
    topic: "user_sync_progress",        # Progress topic
    error_topic: "user_sync_errors",    # Error notifications topic
    completion_topic: "user_sync_complete", # Completion notifications
    enable_detailed_events: true,       # Send detailed event data
    event_throttle_ms: 100,             # Throttle rapid events
    
    # Admin interface real-time updates
    admin_topic: "sync_admin_updates",  # Admin interface updates
    broadcast_to_admin: true,           # Send events to admin interface
    admin_event_types: [                # Events to broadcast to admin
      :sync_started, :sync_completed, :sync_failed,
      :batch_completed, :progress_update, :error_occurred
    ]
  },
  
  # Session configuration
  session_config: %{
    sync_type: :import_users,           # Identifier for this sync type
    description: "Import users from Airtable CRM",
    tags: ["crm", "users", "scheduled"], # Tags for filtering/searching
    metadata: %{                        # Custom metadata
      triggered_by: "admin_user",
      automation_id: "daily_user_sync"
    },
    retention_days: 30                  # Keep session data for 30 days
  }
}
```

## Environment Variables

Configure sensitive data through environment variables:

### Airtable Configuration

```bash
# Required
AIRTABLE_API_KEY="patXXXXXXXXXXXXXX"

# Optional defaults
AIRTABLE_BASE_ID="appXXXXXXXXXXXXXX"
AIRTABLE_DEFAULT_BATCH_SIZE="100"
AIRTABLE_DEFAULT_TIMEOUT="30000"
```

### Database Configuration

```bash
# If using custom database connections
SYNC_DATABASE_URL="postgresql://user:pass@localhost/sync_db"
SYNC_POOL_SIZE="10"
```

### Performance Configuration

```bash
# Performance tuning
SYNC_MAX_PARALLEL_WORKERS="4"
SYNC_DEFAULT_BATCH_SIZE="500"
SYNC_ENABLE_STREAMING="true"
```

### Monitoring Configuration

```bash
# Monitoring and alerting
SYNC_ENABLE_TELEMETRY="true"
SYNC_METRICS_ENDPOINT="http://metrics.example.com"
SYNC_ALERT_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

## Advanced Configuration Patterns

### Configuration Builder

Create a configuration builder for complex setups:

```elixir
defmodule MyApp.SyncConfigBuilder do
  def build_user_sync_config(opts \\ []) do
    base_config()
    |> add_source_config(opts)
    |> add_target_config(opts)
    |> add_processing_config(opts)
    |> add_environment_overrides(opts)
  end
  
  defp base_config do
    %{
      source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
      target_resource: MyApp.Accounts.User,
      pubsub_config: %{module: MyApp.PubSub}
    }
  end
  
  defp add_source_config(config, opts) do
    source_config = %{
      api_key: get_env_or_option("AIRTABLE_API_KEY", opts, :api_key),
      base_id: get_env_or_option("AIRTABLE_BASE_ID", opts, :base_id),
      table_id: get_table_id_for_env(),
      max_records: Keyword.get(opts, :limit)
    }
    
    Map.put(config, :source_config, source_config)
  end
  
  defp add_target_config(config, opts) do
    target_config = %{
      unique_field: Keyword.get(opts, :unique_field, :email),
      create_action: Keyword.get(opts, :create_action, :create),
      update_action: Keyword.get(opts, :update_action, :update)
    }
    
    Map.put(config, :target_config, target_config)
  end
  
  defp add_processing_config(config, opts) do
    processing_config = %{
      batch_size: get_batch_size_for_env(),
      enable_error_recovery: Keyword.get(opts, :enable_recovery, true),
      dry_run: Keyword.get(opts, :dry_run, false)
    }
    
    Map.put(config, :processing_config, processing_config)
  end
  
  defp get_env_or_option(env_var, opts, option_key) do
    System.get_env(env_var) || Keyword.get(opts, option_key) || 
      raise "Missing #{env_var} environment variable or #{option_key} option"
  end
  
  defp get_table_id_for_env do
    case Mix.env() do
      :prod -> System.get_env("AIRTABLE_PROD_TABLE_ID")
      :test -> System.get_env("AIRTABLE_TEST_TABLE_ID")
      _ -> System.get_env("AIRTABLE_DEV_TABLE_ID")
    end
  end
  
  defp get_batch_size_for_env do
    case Mix.env() do
      :prod -> 500
      :test -> 5
      _ -> 50
    end
  end
end
```

Usage:

```elixir
# Simple usage
config = MyApp.SyncConfigBuilder.build_user_sync_config()

# With options
config = MyApp.SyncConfigBuilder.build_user_sync_config(
  limit: 1000,
  dry_run: true,
  unique_field: :external_id
)
```

### Environment-Aware Configuration

```elixir
defmodule MyApp.SyncConfig do
  def get_config(sync_type, env \\ Mix.env()) do
    base_config(sync_type)
    |> apply_environment_overrides(env)
    |> validate_config()
  end
  
  defp base_config(:users) do
    %{
      source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
      target_resource: MyApp.Accounts.User,
      target_config: %{unique_field: :email}
    }
  end
  
  defp base_config(:products) do
    %{
      source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
      target_resource: MyApp.Catalog.Product,
      target_config: %{unique_field: :sku}
    }
  end
  
  defp apply_environment_overrides(config, :prod) do
    Map.merge(config, %{
      processing_config: %{
        batch_size: 1000,
        timeout: 120_000,
        enable_parallel_processing: true
      }
    })
  end
  
  defp apply_environment_overrides(config, :test) do
    Map.merge(config, %{
      processing_config: %{
        batch_size: 5,
        timeout: 5_000,
        enable_progress_tracking: false
      }
    })
  end
  
  defp apply_environment_overrides(config, _env), do: config
  
  defp validate_config(config) do
    case NCDB2Phx.validate_sync_config(config) do
      :ok -> config
      {:error, errors} -> raise "Invalid sync config: #{inspect(errors)}"
    end
  end
end
```

## Performance Tuning

### Batch Size Optimization

```elixir
# Start with conservative batch sizes and increase based on performance
processing_config: %{
  batch_size: case System.get_env("DATABASE_PERFORMANCE_TIER") do
    "high" -> 1000    # High-performance database
    "medium" -> 500   # Standard database
    "low" -> 100      # Shared or limited database
    _ -> 250          # Default safe size
  end
}
```

### Memory Management

```elixir
processing_config: %{
  # Enable streaming for large datasets
  enable_streaming: true,
  stream_chunk_size: 1000,
  
  # Limit concurrent processing
  parallel_workers: min(System.schedulers(), 4),
  
  # Garbage collection tuning
  enable_gc_after_batch: true,
  gc_threshold: 50  # Force GC every 50 batches
}
```

### Network Optimization

```elixir
source_config: %{
  # ... other config
  
  # Connection pooling
  pool_size: 10,
  max_overflow: 5,
  
  # Request tuning
  page_size: 100,              # Balance between requests and memory
  request_timeout: 30_000,     # Per-request timeout
  connection_timeout: 10_000,  # Connection establishment timeout
  
  # Rate limiting
  rate_limit: %{
    requests_per_second: 5,    # Respect API limits
    burst_size: 10             # Brief bursts allowed
  }
}
```

## Error Handling Configuration

### Comprehensive Error Strategy

```elixir
processing_config: %{
  # Retry configuration
  max_retries: 3,
  retry_backoff: :exponential,
  retry_backoff_base: 1000,      # Start with 1 second
  retry_backoff_max: 60_000,     # Max 1 minute between retries
  
  # Error thresholds
  error_threshold: 0.05,         # Stop if >5% error rate
  consecutive_error_limit: 10,   # Stop after 10 consecutive errors
  
  # Error classification
  retryable_errors: [
    :network_timeout,
    :rate_limited,
    :temporary_server_error
  ],
  
  fatal_errors: [
    :authentication_failed,
    :invalid_configuration,
    :resource_not_found
  ],
  
  # Error callbacks
  error_callback: &MyApp.ErrorHandlers.sync_error_handler/3,
  fatal_error_callback: &MyApp.ErrorHandlers.fatal_sync_error/3
}
```

### Custom Error Handlers

```elixir
defmodule MyApp.ErrorHandlers do
  def sync_error_handler(error, record, context) do
    case classify_error(error) do
      :retryable ->
        Logger.warn("Retryable sync error", error: error, record_id: record.source_record_id)
        {:retry, error}
        
      :skippable ->
        Logger.error("Skipping invalid record", error: error, record: record)
        notify_data_team(error, record)
        {:skip, error}
        
      :fatal ->
        Logger.error("Fatal sync error", error: error)
        {:stop, error}
    end
  end
  
  def fatal_sync_error(error, context, config) do
    # Alert administrators
    send_alert("Sync failed fatally", %{
      error: error,
      sync_type: context.sync_type,
      session_id: context.session_id
    })
    
    # Log for debugging
    Logger.error("Fatal sync error - manual intervention required",
      error: error,
      context: context,
      config: sanitize_config(config)
    )
  end
end
```

## Monitoring and Telemetry

### Telemetry Configuration

```elixir
# config/config.exs
config :ncdb_2_phx,
  enable_telemetry: true,
  telemetry_config: %{
    # Metrics to collect
    metrics: [
      :sync_duration,
      :records_processed,
      :error_rate,
      :batch_processing_time,
      :api_response_time
    ],
    
    # Metric destinations
    metric_stores: [
      {NCDB2Phx.Telemetry.PrometheusStore, %{port: 9090}},
      {NCDB2Phx.Telemetry.DatadogStore, %{api_key: System.get_env("DATADOG_API_KEY")}}
    ],
    
    # Event sampling
    sample_rate: 1.0,          # Sample 100% of events
    event_buffer_size: 1000    # Buffer events for batch sending
  }
```

### Custom Telemetry Handlers

```elixir
defmodule MyApp.SyncTelemetry do
  def setup do
    :telemetry.attach_many(
      "sync-telemetry",
      [
        [:ncdb_2_phx, :sync, :start],
        [:ncdb_2_phx, :sync, :stop],
        [:ncdb_2_phx, :sync, :exception],
        [:ncdb_2_phx, :batch, :complete]
      ],
      &handle_telemetry_event/4,
      %{}
    )
  end
  
  def handle_telemetry_event([:ncdb_2_phx, :sync, :start], measurements, metadata, _config) do
    MyApp.Metrics.increment("sync.started", tags: [sync_type: metadata.sync_type])
  end
  
  def handle_telemetry_event([:ncdb_2_phx, :sync, :stop], measurements, metadata, _config) do
    MyApp.Metrics.timing("sync.duration", measurements.duration, tags: [
      sync_type: metadata.sync_type,
      status: metadata.status
    ])
    
    MyApp.Metrics.gauge("sync.records_processed", metadata.records_processed)
  end
  
  def handle_telemetry_event([:ncdb_2_phx, :batch, :complete], measurements, metadata, _config) do
    MyApp.Metrics.timing("batch.processing_time", measurements.duration)
    MyApp.Metrics.histogram("batch.size", metadata.batch_size)
  end
end
```

## Configuration Validation

### Runtime Validation

```elixir
defmodule MyApp.ConfigValidator do
  def validate_sync_config!(config) do
    with :ok <- validate_source_config(config),
         :ok <- validate_target_config(config),
         :ok <- validate_processing_config(config),
         :ok <- validate_environment_requirements(config) do
      config
    else
      {:error, reason} -> raise "Invalid sync configuration: #{reason}"
    end
  end
  
  defp validate_source_config(%{source_config: %{api_key: api_key}}) when byte_size(api_key) > 10 do
    :ok
  end
  defp validate_source_config(_) do
    {:error, "Invalid or missing API key"}
  end
  
  defp validate_target_config(%{target_resource: resource}) do
    if Code.ensure_loaded?(resource) and function_exported?(resource, :ash_resource?, 0) do
      :ok
    else
      {:error, "Target resource is not a valid Ash resource"}
    end
  end
  
  defp validate_processing_config(%{processing_config: %{batch_size: size}}) when size > 0 and size <= 10000 do
    :ok
  end
  defp validate_processing_config(_) do
    {:error, "Batch size must be between 1 and 10000"}
  end
  
  defp validate_environment_requirements(config) do
    case Mix.env() do
      :prod -> validate_production_requirements(config)
      _ -> :ok
    end
  end
  
  defp validate_production_requirements(config) do
    # Ensure production has proper error handling, monitoring, etc.
    with :ok <- ensure_error_handling_enabled(config),
         :ok <- ensure_monitoring_configured(config) do
      :ok
    end
  end
end
```

## Configuration Best Practices

### 1. Use Environment-Specific Defaults

```elixir
# Good
config :ncdb_2_phx,
  default_batch_size: if(Mix.env() == :prod, do: 500, else: 50)

# Better  
defp get_default_batch_size do
  case {Mix.env(), System.get_env("DATABASE_PERFORMANCE_TIER")} do
    {:prod, "high"} -> 1000
    {:prod, _} -> 500
    {:test, _} -> 5
    _ -> 50
  end
end
```

### 2. Validate Early and Often

```elixir
# Validate at startup
def application_start do
  NCDB2Phx.ConfigValidator.validate_application_config!()
  # ... rest of startup
end

# Validate before each sync
def execute_sync(config, opts) do
  config
  |> NCDB2Phx.ConfigValidator.validate_sync_config!()
  |> NCDB2Phx.execute_sync(opts)
end
```

### 3. Use Configuration Builders

```elixir
# Encapsulate complex configuration logic
config = MyApp.SyncConfigs.build_for_environment(:users, Mix.env())
```

### 4. Document Configuration Options

```elixir
@moduledoc """
Sync configuration options:

## Required
- `api_key`: Airtable API key (from environment)
- `base_id`: Airtable base ID
- `table_id`: Airtable table ID

## Optional  
- `batch_size`: Records per batch (default: 100)
- `timeout`: Timeout per batch in ms (default: 30000)
- `enable_recovery`: Enable error recovery (default: true)

## Performance Tuning
For high-volume syncs, consider:
- Increasing `batch_size` to 500-1000
- Enabling `parallel_processing`
- Adjusting `stream_chunk_size`
"""
```

### 5. Secure Sensitive Configuration

```elixir
# Good - use environment variables
api_key: System.get_env("AIRTABLE_API_KEY")

# Bad - hardcode secrets
api_key: "patXXXXXXXXXXXXXX"

# Better - validate secrets exist
api_key: System.get_env("AIRTABLE_API_KEY") || 
         raise("AIRTABLE_API_KEY environment variable is required")
```

## Troubleshooting Configuration Issues

### Common Configuration Problems

1. **Missing Environment Variables**
   ```bash
   # Check all required environment variables are set
   printenv | grep AIRTABLE
   ```

2. **Invalid Resource References**
   ```elixir
   # Verify resource is loaded and is an Ash resource
   Code.ensure_loaded?(MyApp.Accounts.User)
   MyApp.Accounts.User.ash_resource?()
   ```

3. **PubSub Module Issues**
   ```elixir
   # Verify PubSub module exists and is started
   Process.whereis(MyApp.PubSub)
   ```

4. **Batch Size Too Large**
   ```elixir
   # Start with small batch sizes and increase gradually
   processing_config: %{batch_size: 10}
   ```

### Configuration Debugging

Enable debug mode to see detailed configuration:

```elixir
config = %{
  # ... your config
  processing_config: %{
    debug_mode: true,
    enable_detailed_logging: true
  }
}
```

This will log the complete configuration at sync start (with sensitive data masked).

## Support

For configuration help:

- Check the [Installation Guide](installation.md) for setup issues
- Review the [Quickstart Guide](quickstart.md) for basic configuration
- See [GitHub Issues](https://github.com/shotleybuilder/ncdb_2_phx/issues) for known configuration problems
- Ask questions in [GitHub Discussions](https://github.com/shotleybuilder/ncdb_2_phx/discussions)