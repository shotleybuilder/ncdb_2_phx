# NCDB2Phx

[![Hex.pm](https://img.shields.io/hexpm/v/ncdb_2_phx.svg)](https://hex.pm/packages/ncdb_2_phx)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/ncdb_2_phx)
[![License](https://img.shields.io/hexpm/l/ncdb_2_phx.svg)](LICENSE)

**A comprehensive, production-ready import engine for Phoenix applications using Ash Framework**

NCDB2Phx is a generic import package that enables Phoenix applications to import data from no-code databases (Airtable, Baserow, Notion) and other sources (CSV, APIs, databases) into Ash resources with real-time progress tracking, comprehensive error handling, and a complete LiveView admin interface.

## 🚀 Features

- **🔌 Pluggable Architecture**: Work with any data source through adapter pattern
- **⚡ Real-time Progress**: Live progress tracking with Phoenix PubSub
- **🎛️ LiveView Admin Interface**: Complete web interface for sync management  
- **🛡️ Comprehensive Error Handling**: Automatic retry, recovery, and error classification
- **📊 Detailed Analytics**: Performance metrics, success rates, and operational insights
- **🏗️ Zero Host Coupling**: Works with any Ash resource out of the box
- **🔧 Configuration Driven**: All behavior controlled through configuration
- **✅ Production Battle-Tested**: Used in real applications processing 10,000+ records

## 📦 Installation

Add `ncdb_2_phx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ncdb_2_phx, "~> 1.0"},
    {:ash, "~> 3.0"},
    {:ash_postgres, "~> 2.0"},
    {:ash_phoenix, "~> 2.0"}
  ]
end
```

Then run:

```bash
mix deps.get
mix ash.codegen --check
mix ash.migrate
```

## 🚀 Quick Start

### 1. Add Resources to Your Domain

```elixir
defmodule MyApp.Sync do
  use Ash.Domain
  
  resources do
    # Use the package's generic sync resources
    resource NCDB2Phx.Resources.SyncSession
    resource NCDB2Phx.Resources.SyncBatch  
    resource NCDB2Phx.Resources.SyncLog
  end
end
```

### 2. Configure Your Sync Operation

```elixir
config = %{
  # Source configuration
  source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
  source_config: %{
    api_key: System.get_env("AIRTABLE_API_KEY"),
    base_id: "appXXXXXXXXXXXXXX",
    table_id: "tblXXXXXXXXXXXXXX"
  },
  
  # Target Ash resource configuration
  target_resource: MyApp.Cases.Case,
  target_config: %{
    unique_field: :external_id,  # Field to check for duplicates
    create_action: :create,      # Ash action for creating records
    update_action: :update       # Ash action for updating records
  },
  
  # Processing configuration
  processing_config: %{
    batch_size: 100,                    # Records per batch
    limit: 1000,                        # Total record limit
    enable_error_recovery: true,        # Retry failed records
    enable_progress_tracking: true      # Real-time progress updates
  },
  
  # PubSub configuration for real-time updates
  pubsub_config: %{
    module: MyApp.PubSub,
    topic: "sync_progress"
  },
  
  # Session configuration
  session_config: %{
    sync_type: :import_cases,
    description: "Import cases from Airtable"
  }
}
```

### 3. Execute Sync

```elixir
# Simple sync execution
{:ok, result} = NCDB2Phx.execute_sync(config, actor: current_user)

# Stream records for custom processing
NCDB2Phx.stream_sync_records(config, actor: current_user)
|> Stream.each(fn
  {:created, record} -> IO.puts("Created: #{record.id}")
  {:updated, record} -> IO.puts("Updated: #{record.id}")  
  {:exists, record} -> IO.puts("Exists: #{record.id}")
  {:error, error} -> IO.puts("Error: #{inspect(error)}")
end)
|> Stream.run()
```

### 4. Add Admin Interface (Optional)

Add sync management routes to your router:

```elixir
# router.ex
import NCDB2Phx.Router

scope "/admin", MyAppWeb.Admin do
  pipe_through [:browser, :admin_required]
  
  ncdb_sync_routes "/sync"
end
```

This provides a complete admin interface at `/admin/sync` with:
- One-click sync triggering
- Real-time progress monitoring  
- Error handling and recovery
- Sync history and analytics
- Configuration management

## 🏗️ Architecture

### Core Components

- **SyncEngine**: Main orchestration engine
- **SourceAdapter**: Pluggable interface for data sources
- **TargetProcessor**: Generic Ash resource processing
- **ProgressTracker**: Real-time progress monitoring
- **EventSystem**: PubSub event broadcasting
- **ErrorHandler**: Comprehensive error handling

### Resource Tracking

- **SyncSession**: Track sync operations and their lifecycle
- **SyncBatch**: Monitor batch-level progress and performance
- **SyncLog**: Comprehensive logging for debugging and analytics

### Adapters (Extensible)

- **AirtableAdapter**: Production-ready Airtable integration (included)
- **CSVAdapter**: File-based sync (example in docs)
- **APIAdapter**: REST API sync (example in docs)
- **DatabaseAdapter**: Database-to-database sync (example in docs)

## 📋 Usage Examples

### Basic Airtable Sync

```elixir
# Configure for Airtable sync
config = %{
  source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
  source_config: %{
    api_key: "keyXXXXXXXXXXXXXX",
    base_id: "appXXXXXXXXXXXXXX", 
    table_id: "tblXXXXXXXXXXXXXX"
  },
  target_resource: MyApp.Customers.Customer,
  target_config: %{unique_field: :email},
  processing_config: %{batch_size: 50, limit: 500},
  pubsub_config: %{module: MyApp.PubSub, topic: "customer_sync"}
}

# Execute sync with progress tracking
{:ok, session} = NCDB2Phx.execute_sync(config, actor: admin_user)

# Get sync status
status = NCDB2Phx.get_sync_status(session.session_id)
# => %{status: :completed, progress: 100.0, records_processed: 450}
```

### Custom Data Source Adapter

```elixir
defmodule MyApp.Adapters.CSVAdapter do
  @behaviour NCDB2Phx.Utilities.SourceAdapter
  
  def stream_records(config, _opts) do
    config.file_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Stream.with_index()
    |> Stream.map(fn {row, index} -> 
      {:ok, %{data: row, source_record_id: "csv_#{index}"}}
    end)
  end
  
  def count_records(config, _opts) do
    {:ok, config.file_path |> File.stream!() |> Enum.count() - 1}
  end
end

# Use custom adapter
config = %{
  source_adapter: MyApp.Adapters.CSVAdapter,
  source_config: %{file_path: "/data/customers.csv"},
  target_resource: MyApp.Customers.Customer,
  # ... rest of config
}
```

### Real-time Progress Monitoring

```elixir
defmodule MyAppWeb.SyncLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    # Subscribe to sync progress events
    NCDB2Phx.subscribe_to_sync_events("sync_progress")
    
    {:ok, assign(socket, progress: 0, status: :idle)}
  end
  
  def handle_info({:sync_progress, %{progress: progress, status: status}}, socket) do
    {:noreply, assign(socket, progress: progress, status: status)}
  end
  
  def handle_event("start_sync", _params, socket) do
    # Start sync operation
    config = build_sync_config()
    Task.start(fn -> NCDB2Phx.execute_sync(config) end)
    
    {:noreply, assign(socket, status: :starting)}
  end
end
```

### Error Handling and Recovery

```elixir
# Configure comprehensive error handling
config = %{
  # ... other config
  processing_config: %{
    batch_size: 100,
    enable_error_recovery: true,
    max_retries: 3,
    retry_backoff: :exponential,
    stop_on_error: false,  # Continue processing despite errors
    error_threshold: 0.1   # Stop if >10% error rate
  }
}

# Execute with error handling
case NCDB2Phx.execute_sync(config) do
  {:ok, %{status: :completed} = result} ->
    IO.puts("Sync completed successfully: #{result.records_processed} records")
    
  {:ok, %{status: :completed_with_errors} = result} ->
    IO.puts("Sync completed with errors: #{result.error_count} errors")
    
  {:error, %{reason: :error_threshold_exceeded}} ->
    IO.puts("Sync stopped due to high error rate")
    
  {:error, reason} ->
    IO.puts("Sync failed: #{inspect(reason)}")
end
```

### Performance Analytics

```elixir
# Get comprehensive sync metrics
{:ok, metrics} = NCDB2Phx.get_sync_metrics(session_id)

# Metrics include:
# %{
#   session: %{status: :completed, duration_seconds: 45.2, records_processed: 1000},
#   batch_summary: %{total_batches: 10, completed_batches: 10, average_batch_time: 4520.0},
#   log_summary: %{total_logs: 1050, error_logs: 5, warning_logs: 12},
#   performance_metrics: %{
#     records_per_second: 22.1,
#     error_rate: 0.5,
#     batch_success_rate: 100.0,
#     log_error_rate: 0.48
#   }
# }
```

## 🎛️ Admin Interface

The package includes a complete LiveView admin interface for sync management:

### Features

- **Sync Configuration Panel**: Configure batch size, limits, sync type
- **One-click Sync Triggers**: Start syncs for different data types
- **Real-time Progress**: Live progress bars and statistics
- **Error Management**: View, classify, and retry failed records
- **Sync History**: Complete audit trail of all sync operations
- **Performance Dashboard**: Charts and metrics for sync performance

### Screenshots

*TODO: Add screenshots of admin interface*

### Customization

The admin interface is built with reusable components that can be customized:

```elixir
# Custom sync page with your branding
defmodule MyAppWeb.CustomSyncLive do
  use MyAppWeb, :live_view
  import NCDB2Phx.Components.SyncComponents
  
  def render(assigns) do
    ~H"""
    <div class="my-custom-layout">
      <.sync_progress_panel progress={@progress} />
      <.sync_configuration_panel config={@config} />
      <.sync_history_table sessions={@recent_sessions} />
    </div>
    """
  end
end
```

## ⚙️ Configuration

### Environment Variables

```bash
# Required for Airtable adapter
export AIRTABLE_API_KEY="keyXXXXXXXXXXXXXX"

# Optional: Default configuration
export AIRTABLE_BASE_ID="appXXXXXXXXXXXXXX"
export AIRTABLE_DEFAULT_BATCH_SIZE="100"
```

### Application Configuration

```elixir
# config/config.exs
config :ncdb_2_phx,
  # Default adapter configuration
  default_adapter: NCDB2Phx.Adapters.AirtableAdapter,
  default_batch_size: 100,
  default_timeout: 30_000,
  
  # PubSub configuration
  pubsub_module: MyApp.PubSub,
  default_progress_topic: "sync_progress",
  
  # Error handling defaults
  enable_error_recovery: true,
  max_retries: 3,
  retry_backoff: :exponential,
  
  # Performance tuning
  enable_progress_tracking: true,
  enable_detailed_logging: true,
  
  # Admin interface
  enable_admin_interface: true,
  admin_route_prefix: "/admin/sync"
```

### Per-Environment Configuration

```elixir
# config/dev.exs
config :ncdb_2_phx,
  default_batch_size: 50,  # Smaller batches for development
  enable_detailed_logging: true
  
# config/prod.exs  
config :ncdb_2_phx,
  default_batch_size: 500,  # Larger batches for production
  enable_detailed_logging: false,
  timeout: 60_000
```

## 🧪 Testing

### Test Adapter

The package includes a test adapter for easy testing:

```elixir
defmodule MyApp.SyncTest do
  use MyApp.DataCase
  
  test "sync creates records from test data" do
    # Use test adapter with predefined data
    config = %{
      source_adapter: NCDB2Phx.create_test_adapter(),
      source_config: %{
        test_data: [
          %{name: "John Doe", email: "john@example.com"},
          %{name: "Jane Smith", email: "jane@example.com"}
        ]
      },
      target_resource: MyApp.Users.User,
      target_config: %{unique_field: :email},
      processing_config: %{batch_size: 10}
    }
    
    {:ok, result} = NCDB2Phx.execute_sync(config)
    
    assert result.status == :completed
    assert result.records_processed == 2
    assert result.records_created == 2
  end
end
```

### Mock External Services

```elixir
# Mock Airtable responses for testing
defmodule MyApp.MockAirtableAdapter do
  @behaviour NCDB2Phx.Utilities.SourceAdapter
  
  def stream_records(_config, _opts) do
    [
      {:ok, %{id: "rec1", fields: %{name: "Test Record 1"}}},
      {:ok, %{id: "rec2", fields: %{name: "Test Record 2"}}}
    ]
    |> Stream.map(& &1)
  end
  
  def count_records(_config, _opts), do: {:ok, 2}
end
```

## 🔧 Extending the Package

### Custom Source Adapters

Create adapters for any data source by implementing the `SourceAdapter` behaviour:

```elixir
defmodule MyApp.Adapters.APIAdapter do
  @behaviour NCDB2Phx.Utilities.SourceAdapter
  
  def stream_records(config, opts) do
    config.api_url
    |> HTTPoison.get!(headers: auth_headers(config))
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("data", [])
    |> Stream.map(fn record -> 
      {:ok, %{data: record, source_record_id: record["id"]}}
    end)
  end
  
  def count_records(config, _opts) do
    # Implement record counting logic
    {:ok, get_total_count(config)}
  end
  
  defp auth_headers(config) do
    [{"Authorization", "Bearer #{config.api_token}"}]
  end
end
```

### Custom Record Transformers

Transform data during sync with custom transformers:

```elixir
defmodule MyApp.Transformers.CustomerTransformer do
  @behaviour NCDB2Phx.Utilities.RecordTransformer
  
  def transform_record(source_record, target_resource, _config) do
    {:ok, %{
      name: clean_name(source_record.fields["Name"]),
      email: String.downcase(source_record.fields["Email"]),
      phone: normalize_phone(source_record.fields["Phone"]),
      # Add computed fields
      full_name: build_full_name(source_record.fields),
      created_from_sync: true
    }}
  end
  
  defp clean_name(name), do: String.trim(name || "")
  defp normalize_phone(phone), do: Regex.replace(~r/\D/, phone || "", "")
  defp build_full_name(fields), do: "#{fields["First"]} #{fields["Last"]}"
end

# Use in sync configuration
config = %{
  # ... other config
  processing_config: %{
    record_transformer: MyApp.Transformers.CustomerTransformer,
    # ... other processing config
  }
}
```

### Custom Error Handlers

Implement custom error handling logic:

```elixir
defmodule MyApp.ErrorHandlers.SlackNotifier do
  @behaviour NCDB2Phx.Utilities.ErrorHandler
  
  def handle_error(error, context, _config) do
    case error_severity(error) do
      :critical -> 
        SlackAPI.send_alert("🚨 Critical sync error: #{inspect(error)}")
        {:stop, error}
        
      :warning ->
        SlackAPI.send_warning("⚠️ Sync warning: #{inspect(error)}")
        {:continue, error}
        
      :info ->
        Logger.info("Sync info: #{inspect(error)}")
        {:continue, error}
    end
  end
  
  defp error_severity(%{type: :validation_error}), do: :warning
  defp error_severity(%{type: :network_error}), do: :critical  
  defp error_severity(_), do: :info
end
```

## 📚 Advanced Usage

### Batch Processing with Custom Logic

```elixir
# Stream records with custom batch processing
config
|> NCDB2Phx.stream_sync_records(actor: user)
|> Stream.chunk_every(50)  # Custom batch size
|> Stream.with_index()
|> Stream.each(fn {batch, batch_number} ->
  # Custom processing logic per batch
  Logger.info("Processing batch #{batch_number} with #{length(batch)} records")
  
  # Custom validation
  validate_batch(batch)
  
  # Custom transformation
  transformed_batch = Enum.map(batch, &transform_record/1)
  
  # Bulk insert with custom logic
  insert_batch_with_retry(transformed_batch)
end)
|> Stream.run()
```

### Multi-Resource Sync

```elixir
# Sync multiple resources in sequence
resources_config = [
  %{
    target_resource: MyApp.Customers.Customer,
    source_config: %{table_id: "tblCustomers"},
    target_config: %{unique_field: :external_id}
  },
  %{
    target_resource: MyApp.Orders.Order, 
    source_config: %{table_id: "tblOrders"},
    target_config: %{unique_field: :order_number}
  }
]

results = Enum.map(resources_config, fn resource_config ->
  config = Map.merge(base_config, resource_config)
  NCDB2Phx.execute_sync(config, actor: admin_user)
end)
```

### Conditional Sync Logic

```elixir
# Conditional sync based on data analysis
config = %{
  # ... base config
  processing_config: %{
    batch_size: 100,
    pre_sync_validation: fn source_data, _config ->
      record_count = Enum.count(source_data)
      
      cond do
        record_count == 0 -> 
          {:skip, "No records to sync"}
          
        record_count > 10_000 ->
          {:confirm, "Large sync detected: #{record_count} records"}
          
        true ->
          {:continue, "Normal sync: #{record_count} records"}
      end
    end,
    
    record_filter: fn record, _config ->
      # Only sync records modified in last 30 days
      case Date.from_iso8601(record.fields["Modified"]) do
        {:ok, modified_date} ->
          Date.diff(Date.utc_today(), modified_date) <= 30
        _ ->
          false
      end
    end
  }
}
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/shotleybuilder/ncdb_2_phx.git
cd ncdb_2_phx
mix deps.get
mix ash.setup
mix test
```

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix coveralls

# Run specific test files
mix test test/ncdb_2_phx/sync_engine_test.exs
```

## 📖 Documentation

- [Installation Guide](guides/installation.md)
- [Quick Start Guide](guides/quickstart.md)
- [Adapter Development](guides/adapters.md)
- [Configuration Reference](guides/configuration.md)
- [API Documentation](https://hexdocs.pm/ncdb_2_phx)

## 🆘 Support

- **Documentation**: [HexDocs](https://hexdocs.pm/ncdb_2_phx)
- **Issues**: [GitHub Issues](https://github.com/shotleybuilder/ncdb_2_phx/issues)
- **Discussions**: [GitHub Discussions](https://github.com/shotleybuilder/ncdb_2_phx/discussions)

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- Built for the Phoenix and Ash Framework communities
- Inspired by real-world sync challenges in production applications
- Special thanks to the EHS Enforcement project for providing the use case and testing ground

---

**Built with ❤️ using Phoenix, Ash Framework, and LiveView**