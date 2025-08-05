# Adapter Development Guide

This guide covers how to create custom source adapters for AirtableSyncPhoenix, enabling sync from any data source.

## Overview

Adapters are the bridge between external data sources and the sync engine. They implement a standardized interface that allows the sync engine to work with any data source in a consistent way.

## Adapter Interface

All adapters must implement the `AirtableSyncPhoenix.Utilities.SourceAdapter` behaviour:

```elixir
@behaviour AirtableSyncPhoenix.Utilities.SourceAdapter

# Required callbacks
def initialize(config)
def stream_records(adapter_state)
def validate_connection(adapter_state)

# Optional callbacks
def get_total_count(adapter_state)  # For progress tracking
def cleanup(adapter_state)          # For resource cleanup
```

## Built-in Adapters

### AirtableAdapter

The package includes a production-ready Airtable adapter:

```elixir
config = %{
  source_adapter: AirtableSyncPhoenix.Adapters.AirtableAdapter,
  source_config: %{
    api_key: "patXXXXXXXXXXXXXX",
    base_id: "appXXXXXXXXXXXXXX",
    table_id: "tblXXXXXXXXXXXXXX",
    view_id: "viwXXXXXXXXXXXXXX",  # Optional: specific view
    fields: ["Name", "Email"],      # Optional: specific fields
    max_records: 1000               # Optional: record limit
  }
}
```

### TestAdapter

For development and testing:

```elixir
{:ok, test_adapter} = AirtableSyncPhoenix.Utilities.SourceAdapter.create_test_adapter(
  record_count: 100,
  record_template: fn index ->
    %{
      data: %{name: "Test User #{index}", email: "user#{index}@test.com"},
      source_record_id: "test_#{index}",
      source_metadata: %{source_type: :test_data}
    }
  end
)
```

## Creating Custom Adapters

### Example: CSV File Adapter

Here's a complete CSV adapter implementation:

```elixir
defmodule MyApp.Adapters.CsvAdapter do
  @moduledoc """
  Adapter for syncing data from CSV files.
  
  Configuration:
  - file_path: Path to CSV file
  - headers: true/false - whether first row contains headers
  - delimiter: Field delimiter (default: ",")
  - encoding: File encoding (default: :utf8)
  """
  
  @behaviour AirtableSyncPhoenix.Utilities.SourceAdapter
  
  require Logger
  
  @impl true
  def initialize(config) do
    with :ok <- validate_config(config),
         :ok <- validate_file_access(config.file_path),
         {:ok, headers} <- extract_headers(config) do
      
      state = %{
        file_path: config.file_path,
        headers: headers,
        delimiter: Map.get(config, :delimiter, ","),
        encoding: Map.get(config, :encoding, :utf8),
        skip_header_row: Map.get(config, :headers, true)
      }
      
      Logger.info("CSV adapter initialized: #{config.file_path}")
      {:ok, state}
    else
      error -> error
    end
  end
  
  @impl true
  def stream_records(state) do
    state.file_path
    |> File.stream!([], state.encoding)
    |> CSV.decode!(separator: state.delimiter, headers: state.headers)
    |> Stream.with_index()
    |> Stream.map(fn {row, index} -> 
      normalize_csv_record(row, index, state)
    end)
    |> Stream.drop(if state.skip_header_row, do: 1, else: 0)
  end
  
  @impl true
  def validate_connection(state) do
    case File.stat(state.file_path) do
      {:ok, %File.Stat{type: :regular, access: access}} ->
        if access in [:read, :read_write] do
          :ok
        else
          {:error, {:permission_denied, state.file_path}}
        end
        
      {:ok, %File.Stat{type: type}} ->
        {:error, {:invalid_file_type, type}}
        
      {:error, reason} ->
        {:error, {:file_access_error, reason}}
    end
  end
  
  @impl true
  def get_total_count(state) do
    try do
      count = state.file_path
      |> File.stream!([], state.encoding)
      |> Enum.count()
      |> case do
        count when state.skip_header_row -> max(0, count - 1)
        count -> count
      end
      
      {:ok, count}
    rescue
      error -> {:error, {:count_failed, error}}
    end
  end
  
  @impl true
  def cleanup(_state) do
    # No cleanup needed for file reading
    :ok
  end
  
  # Private helper functions
  
  defp validate_config(%{file_path: path}) when is_binary(path) and path != "" do
    :ok
  end
  defp validate_config(_) do
    {:error, :invalid_config, "file_path is required and must be a non-empty string"}
  end
  
  defp validate_file_access(file_path) do
    case File.exists?(file_path) do
      true -> :ok
      false -> {:error, :file_not_found, file_path}
    end
  end
  
  defp extract_headers(config) do
    if Map.get(config, :headers, true) do
      # Extract headers from first row
      case File.stream!(config.file_path, [], Map.get(config, :encoding, :utf8)) |> Enum.take(1) do
        [header_line] ->
          headers = header_line
          |> String.trim()
          |> String.split(Map.get(config, :delimiter, ","))
          |> Enum.map(&String.trim/1)
          
          {:ok, headers}
          
        [] ->
          {:error, :empty_file}
      end
    else
      {:ok, false}
    end
  end
  
  defp normalize_csv_record(row_data, index, _state) do
    %{
      data: row_data,
      source_record_id: "csv_row_#{index}",
      source_metadata: %{
        row_number: index + 1,
        source_type: :csv_file
      }
    }
  end
end
```

### Usage:

```elixir
config = %{
  source_adapter: MyApp.Adapters.CsvAdapter,
  source_config: %{
    file_path: "/data/users.csv",
    headers: true,
    delimiter: ",",
    encoding: :utf8
  },
  # ... rest of sync config
}
```

### Example: REST API Adapter

Here's an adapter for generic REST APIs:

```elixir
defmodule MyApp.Adapters.RestApiAdapter do
  @moduledoc """
  Adapter for syncing data from REST APIs.
  
  Configuration:
  - base_url: API base URL
  - endpoint: Specific endpoint path
  - api_key: Authentication key
  - headers: Additional HTTP headers
  - pagination: Pagination configuration
  """
  
  @behaviour AirtableSyncPhoenix.Utilities.SourceAdapter
  
  require Logger
  
  @impl true
  def initialize(config) do
    with :ok <- validate_config(config),
         {:ok, client} <- setup_http_client(config) do
      
      state = %{
        client: client,
        endpoint: config.endpoint,
        pagination: Map.get(config, :pagination, %{type: :page, per_page: 100}),
        rate_limit: Map.get(config, :rate_limit, %{requests_per_second: 10})
      }
      
      Logger.info("REST API adapter initialized: #{config.base_url}#{config.endpoint}")
      {:ok, state}
    else
      error -> error
    end
  end
  
  @impl true
  def stream_records(state) do
    Stream.unfold({state, 1}, fn
      nil -> nil
      {current_state, page} ->
        case fetch_page(current_state, page) do
          {:ok, %{data: [], has_more: false}} -> nil
          {:ok, %{data: records, has_more: true}} -> 
            {records, {current_state, page + 1}}
          {:ok, %{data: records, has_more: false}} -> 
            {records, nil}
          {:error, reason} -> 
            Logger.error("Failed to fetch page #{page}: #{inspect(reason)}")
            nil
        end
    end)
    |> Stream.flat_map(&(&1))
    |> Stream.map(&normalize_api_record/1)
  end
  
  @impl true
  def validate_connection(state) do
    case Tesla.get(state.client, "/health") do
      {:ok, %Tesla.Env{status: 200}} -> 
        :ok
      {:ok, %Tesla.Env{status: status, body: body}} -> 
        {:error, {:api_error, status, body}}
      {:error, reason} -> 
        {:error, {:connection_failed, reason}}
    end
  end
  
  @impl true
  def get_total_count(state) do
    case Tesla.get(state.client, "#{state.endpoint}/count") do
      {:ok, %Tesla.Env{status: 200, body: %{"total" => count}}} -> {:ok, count}
      {:ok, %Tesla.Env{status: 200, body: %{"count" => count}}} -> {:ok, count}
      {:error, reason} -> {:error, {:count_failed, reason}}
    end
  end
  
  @impl true
  def cleanup(state) do
    # Close HTTP connections if needed
    Tesla.Adapter.finch_close(state.client)
    :ok
  end
  
  # Private helper functions
  
  defp validate_config(config) do
    required_fields = [:base_url, :endpoint]
    missing = Enum.filter(required_fields, &(not Map.has_key?(config, &1)))
    
    case missing do
      [] -> :ok
      fields -> {:error, {:missing_config, fields}}
    end
  end
  
  defp setup_http_client(config) do
    middleware = [
      {Tesla.Middleware.BaseUrl, config.base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, build_headers(config)},
      {Tesla.Middleware.Timeout, timeout: 30_000}
    ]
    
    middleware = if config[:rate_limit] do
      [{Tesla.Middleware.Fuse, name: :api_adapter} | middleware]
    else
      middleware
    end
    
    client = Tesla.client(middleware)
    {:ok, client}
  end
  
  defp build_headers(config) do
    base_headers = [{"Content-Type", "application/json"}]
    
    auth_headers = case config[:api_key] do
      nil -> []
      key -> [{"Authorization", "Bearer #{key}"}]
    end
    
    custom_headers = Map.get(config, :headers, [])
    
    base_headers ++ auth_headers ++ custom_headers
  end
  
  defp fetch_page(state, page) do
    query_params = build_pagination_params(state.pagination, page)
    
    case Tesla.get(state.client, state.endpoint, query: query_params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        parse_api_response(body, state.pagination)
        
      {:ok, %Tesla.Env{status: 429}} ->
        # Rate limited - wait and retry
        Process.sleep(1000)
        fetch_page(state, page)
        
      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, {:api_error, status, body}}
        
      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end
  
  defp build_pagination_params(%{type: :page, per_page: per_page}, page) do
    [page: page, per_page: per_page]
  end
  defp build_pagination_params(%{type: :offset, limit: limit}, page) do
    [offset: (page - 1) * limit, limit: limit]
  end
  
  defp parse_api_response(body, pagination) do
    case body do
      %{"data" => data, "pagination" => %{"has_more" => has_more}} ->
        {:ok, %{data: data, has_more: has_more}}
        
      %{"items" => items, "total" => total} ->
        current_count = length(items)
        page_size = pagination[:per_page] || pagination[:limit] || 100
        has_more = current_count >= page_size
        {:ok, %{data: items, has_more: has_more}}
        
      data when is_list(data) ->
        {:ok, %{data: data, has_more: false}}
        
      _ ->
        {:error, {:invalid_response_format, body}}
    end
  end
  
  defp normalize_api_record(record) do
    %{
      data: record,
      source_record_id: record["id"] || record[:id] || generate_id(record),
      source_metadata: %{
        source_type: :rest_api,
        fetched_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    }
  end
  
  defp generate_id(record) do
    # Generate a deterministic ID based on record content
    :crypto.hash(:md5, inspect(record)) |> Base.encode16(case: :lower)
  end
end
```

### Usage:

```elixir
config = %{
  source_adapter: MyApp.Adapters.RestApiAdapter,
  source_config: %{
    base_url: "https://api.example.com",
    endpoint: "/users",
    api_key: System.get_env("API_KEY"),
    headers: [{"X-Client-Version", "1.0"}],
    pagination: %{type: :page, per_page: 50},
    rate_limit: %{requests_per_second: 5}
  },
  # ... rest of sync config
}
```

## Database-to-Database Adapter

For syncing between databases:

```elixir
defmodule MyApp.Adapters.DatabaseAdapter do
  @behaviour AirtableSyncPhoenix.Utilities.SourceAdapter
  
  @impl true
  def initialize(config) do
    # Set up database connection
    {:ok, pid} = Postgrex.start_link(
      hostname: config.hostname,
      username: config.username,
      password: config.password,
      database: config.database
    )
    
    state = %{
      connection: pid,
      table: config.table,
      query: config.query || "SELECT * FROM #{config.table}"
    }
    
    {:ok, state}
  end
  
  @impl true
  def stream_records(state) do
    # Stream large result sets efficiently
    Postgrex.stream(state.connection, state.query, [])
    |> Stream.map(fn %Postgrex.Result{rows: rows, columns: columns} ->
      Enum.map(rows, fn row ->
        data = Enum.zip(columns, row) |> Map.new()
        %{
          data: data,
          source_record_id: to_string(data["id"]),
          source_metadata: %{source_type: :database}
        }
      end)
    end)
    |> Stream.flat_map(& &1)
  end
  
  @impl true
  def validate_connection(state) do
    case Postgrex.query(state.connection, "SELECT 1", []) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:connection_failed, reason}}
    end
  end
  
  @impl true
  def get_total_count(state) do
    count_query = "SELECT COUNT(*) FROM #{state.table}"
    case Postgrex.query(state.connection, count_query, []) do
      {:ok, %Postgrex.Result{rows: [[count]]}} -> {:ok, count}
      {:error, reason} -> {:error, {:count_failed, reason}}
    end
  end
  
  @impl true
  def cleanup(state) do
    GenServer.stop(state.connection)
    :ok
  end
end
```

## Adapter Testing

### Basic Adapter Test Template

```elixir
defmodule MyApp.Adapters.CsvAdapterTest do
  use ExUnit.Case
  
  alias MyApp.Adapters.CsvAdapter
  
  setup do
    # Create test CSV file
    test_file = "/tmp/test_users.csv"
    csv_content = """
    name,email,age
    John Doe,john@example.com,30
    Jane Smith,jane@example.com,25
    """
    
    File.write!(test_file, csv_content)
    
    config = %{
      file_path: test_file,
      headers: true,
      delimiter: ","
    }
    
    on_exit(fn -> File.rm(test_file) end)
    
    %{config: config, test_file: test_file}
  end
  
  test "initialize/1 validates config and sets up state", %{config: config} do
    assert {:ok, state} = CsvAdapter.initialize(config)
    assert state.file_path == config.file_path
    assert state.headers == ["name", "email", "age"]
  end
  
  test "validate_connection/1 checks file access", %{config: config} do
    {:ok, state} = CsvAdapter.initialize(config)
    assert :ok = CsvAdapter.validate_connection(state)
  end
  
  test "get_total_count/1 returns correct count", %{config: config} do
    {:ok, state} = CsvAdapter.initialize(config)
    assert {:ok, 2} = CsvAdapter.get_total_count(state)  # 2 data rows
  end
  
  test "stream_records/1 returns normalized records", %{config: config} do
    {:ok, state} = CsvAdapter.initialize(config)
    
    records = CsvAdapter.stream_records(state) |> Enum.to_list()
    
    assert length(records) == 2
    
    first_record = Enum.at(records, 0)
    assert first_record.data["name"] == "John Doe"
    assert first_record.data["email"] == "john@example.com"
    assert first_record.source_record_id == "csv_row_0"
  end
  
  test "handles missing file gracefully", %{config: config} do
    bad_config = %{config | file_path: "/nonexistent/file.csv"}
    assert {:error, :file_not_found, _} = CsvAdapter.initialize(bad_config)
  end
end
```

### Integration Test with Sync Engine

```elixir
defmodule MyApp.Syncs.CsvSyncIntegrationTest do
  use MyApp.DataCase
  
  test "csv adapter integrates with sync engine" do
    # Create test CSV
    test_file = "/tmp/integration_test.csv"
    csv_content = """
    name,email
    Test User 1,test1@example.com
    Test User 2,test2@example.com
    """
    File.write!(test_file, csv_content)
    
    # Configure sync
    config = %{
      source_adapter: MyApp.Adapters.CsvAdapter,
      source_config: %{file_path: test_file, headers: true},
      target_resource: MyApp.Accounts.User,
      target_config: %{unique_field: :email},
      processing_config: %{batch_size: 10}
    }
    
    # Execute sync
    assert {:ok, result} = AirtableSyncPhoenix.execute_sync(config)
    assert result.records_processed == 2
    assert result.records_created == 2
    
    # Verify records were created
    users = MyApp.Accounts.User |> Ash.read!()
    assert length(users) == 2
    
    # Cleanup
    File.rm(test_file)
  end
end
```

## Advanced Adapter Features

### Rate Limiting

```elixir
defmodule RateLimitedAdapter do
  # Add rate limiting to your adapter
  defp rate_limit(state) do
    case state.rate_limit do
      %{requests_per_second: rps} ->
        delay_ms = trunc(1000 / rps)
        Process.sleep(delay_ms)
      _ -> 
        :ok
    end
  end
end
```

### Retry Logic

```elixir
defmodule RetryableAdapter do
  defp with_retry(fun, max_retries \\ 3) do
    Enum.reduce_while(0..max_retries, nil, fn attempt, _acc ->
      case fun.() do
        {:ok, result} -> {:halt, {:ok, result}}
        {:error, reason} when attempt < max_retries ->
          backoff_delay = :math.pow(2, attempt) * 1000
          Process.sleep(trunc(backoff_delay))
          {:cont, {:error, reason}}
        {:error, reason} -> 
          {:halt, {:error, reason}}
      end
    end)
  end
end
```

### Connection Pooling

```elixir
defmodule PooledAdapter do
  def initialize(config) do
    # Use a connection pool for HTTP adapters
    pool_config = [
      name: :api_pool,
      size: Map.get(config, :pool_size, 10),
      max_overflow: Map.get(config, :max_overflow, 5)
    ]
    
    {:ok, _pid} = :poolboy.start_link(pool_config, config)
    
    {:ok, %{pool: :api_pool, config: config}}
  end
  
  defp with_connection(state, fun) do
    :poolboy.transaction(state.pool, fun)
  end
end
```

## Best Practices

### 1. Configuration Validation

Always validate configuration thoroughly:

```elixir
defp validate_config(config) do
  with :ok <- validate_required_fields(config),
       :ok <- validate_field_types(config),
       :ok <- validate_business_rules(config) do
    :ok
  end
end
```

### 2. Error Handling

Return consistent error formats:

```elixir
# Good
{:error, {:connection_failed, %{reason: :timeout, details: "Request timed out after 30s"}}}

# Bad  
{:error, "couldn't connect"}
```

### 3. Logging

Add comprehensive logging:

```elixir
Logger.info("Adapter initialized", adapter: __MODULE__, config: sanitized_config)
Logger.debug("Fetching page", page: page, records_per_page: per_page)
Logger.error("Connection failed", error: reason, retry_attempt: attempt)
```

### 4. Resource Management

Always clean up resources:

```elixir
def cleanup(state) do
  close_connections(state)
  cleanup_temp_files(state)
  :ok
end
```

### 5. Performance

Stream data for memory efficiency:

```elixir
# Good - streams data
def stream_records(state) do
  state.data_source
  |> Stream.chunk_every(100)
  |> Stream.flat_map(&process_chunk/1)
end

# Bad - loads all into memory
def stream_records(state) do
  all_records = load_all_records(state)
  Stream.map(all_records, &normalize_record/1)
end
```

## Packaging Your Adapter

Consider publishing reusable adapters as separate packages:

```elixir
# my_csv_sync_adapter/mix.exs
defp deps do
  [
    {:airtable_sync_phoenix, "~> 1.0"}
  ]
end
```

This allows others to use your adapter and contributes to the ecosystem.

## Support

For help with adapter development:

- Review the [SourceAdapter behaviour documentation](https://hexdocs.pm/airtable_sync_phoenix/AirtableSyncPhoenix.Utilities.SourceAdapter.html)
- Check existing adapter implementations in the package source
- Ask questions in [GitHub Discussions](https://github.com/your-org/airtable_sync_phoenix/discussions)
- Report adapter-related issues on [GitHub Issues](https://github.com/your-org/airtable_sync_phoenix/issues)