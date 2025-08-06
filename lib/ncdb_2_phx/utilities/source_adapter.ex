defmodule NCDB2Phx.Utilities.SourceAdapter do
  @moduledoc """
  Behaviour and utilities for pluggable source adapters in the NCDB2Phx package.
  
  This module defines the interface that all source adapters must implement
  to work with the generic sync engine. Source adapters are responsible for
  streaming records from external data sources (Airtable, CSV files, REST APIs, databases, etc.).
  
  ## Overview
  
  The SourceAdapter behaviour provides a standardized interface for connecting to and 
  streaming data from various external sources. This enables the sync engine to work 
  with any data source through a consistent API.
  
  ## Adapter Lifecycle
  
  1. **Initialize**: Set up connection and validate configuration
  2. **Validate Connection**: Ensure the adapter can connect to the data source
  3. **Get Total Count**: Provide record count for progress tracking
  4. **Stream Records**: Stream records in a memory-efficient manner
  5. **Cleanup**: Optional cleanup when sync completes
  
  ## Example Implementation
  
  Here's a complete example of a CSV file adapter:
  
      defmodule MyApp.Adapters.CsvAdapter do
        @behaviour NCDB2Phx.Utilities.SourceAdapter
        
        @impl true
        def initialize(config) do
          # Validate required configuration
          with :ok <- validate_config(config),
               :ok <- validate_file_exists(config.file_path) do
            {:ok, %{
              csv_path: config.file_path, 
              headers: Map.get(config, :headers, true),
              delimiter: Map.get(config, :delimiter, ",")
            }}
          end
        end
        
        @impl true
        def stream_records(adapter_state) do
          adapter_state.csv_path
          |> File.stream!()
          |> CSV.decode!(
            headers: adapter_state.headers,
            separator: adapter_state.delimiter
          )
          |> Stream.with_index()
          |> Stream.map(&normalize_csv_record/1)
        end
        
        @impl true
        def validate_connection(adapter_state) do
          case File.stat(adapter_state.csv_path) do
            {:ok, %{type: :regular}} -> :ok
            {:ok, %{type: type}} -> {:error, {:invalid_file_type, type}}
            {:error, reason} -> {:error, {:file_access_error, reason}}
          end
        end
        
        @impl true
        def get_total_count(adapter_state) do
          try do
            count = adapter_state.csv_path
            |> File.stream!()
            |> Enum.count()
            |> case do
              count when adapter_state.headers -> count - 1  # Subtract header
              count -> count
            end
            
            {:ok, count}
          rescue
            error -> {:error, {:count_failed, error}}
          end
        end
        
        # Optional: Implement cleanup if needed
        @impl true  
        def cleanup(adapter_state) do
          # Close file handles, cleanup temp files, etc.
          :ok
        end
        
        defp normalize_csv_record({row_data, index}) do
          %{
            data: row_data,
            source_record_id: "csv_row_\#{index}",
            source_metadata: %{
              row_number: index + 1,
              source_type: :csv_file
            }
          }
        end
        
        defp validate_config(%{file_path: path}) when is_binary(path), do: :ok
        defp validate_config(_), do: {:error, :missing_file_path}
        
        defp validate_file_exists(path) do
          if File.exists?(path), do: :ok, else: {:error, :file_not_found}
        end
      end
  
  ## REST API Adapter Example
  
  Here's an example adapter for REST APIs:
  
      defmodule MyApp.Adapters.ApiAdapter do
        @behaviour NCDB2Phx.Utilities.SourceAdapter
        
        @impl true
        def initialize(config) do
          # Setup HTTP client and validate API credentials
          client = Tesla.client([
            {Tesla.Middleware.BaseUrl, config.base_url},
            {Tesla.Middleware.Headers, [{"Authorization", "Bearer \#{config.api_token}"}]},
            Tesla.Middleware.JSON
          ])
          
          {:ok, %{client: client, endpoint: config.endpoint}}
        end
        
        @impl true
        def stream_records(adapter_state) do
          Stream.unfold({adapter_state, 1}, fn
            {state, page} ->
              case fetch_page(state, page) do
                {:ok, %{data: [], has_more: false}} -> nil
                {:ok, %{data: records, has_more: true}} -> 
                  {records, {state, page + 1}}
                {:ok, %{data: records, has_more: false}} -> 
                  {records, nil}
                {:error, _} -> nil
              end
          end)
          |> Stream.flat_map(& &1)
          |> Stream.map(&normalize_api_record/1)
        end
        
        @impl true
        def validate_connection(adapter_state) do
          case Tesla.get(adapter_state.client, "/health") do
            {:ok, %{status: 200}} -> :ok
            {:ok, %{status: status}} -> {:error, {:api_error, status}}
            {:error, reason} -> {:error, {:connection_failed, reason}}
          end
        end
        
        @impl true
        def get_total_count(adapter_state) do
          case Tesla.get(adapter_state.client, "\#{adapter_state.endpoint}/count") do
            {:ok, %{body: %{"count" => count}}} -> {:ok, count}
            {:error, reason} -> {:error, {:count_failed, reason}}
          end
        end
        
        defp fetch_page(state, page) do
          Tesla.get(state.client, state.endpoint, query: [page: page, per_page: 100])
        end
        
        defp normalize_api_record(record) do
          %{
            data: record,
            source_record_id: record["id"],
            source_metadata: %{
              source_type: :rest_api,
              api_version: record["api_version"]
            }
          }
        end
      end
  
  ## Built-in Adapters
  
  The package includes these production-ready adapters:
  
  - `NCDB2Phx.Adapters.AirtableAdapter` - Full-featured Airtable integration
  - `NCDB2Phx.Adapters.TestAdapter` - For testing and development
  
  ## Error Handling
  
  Adapters should return consistent error tuples for different failure scenarios:
  
  - `{:error, :invalid_config}` - Configuration validation failed
  - `{:error, :connection_failed}` - Cannot connect to data source
  - `{:error, :authentication_failed}` - Invalid credentials
  - `{:error, :rate_limited}` - API rate limit exceeded
  - `{:error, :not_found}` - Requested resource doesn't exist
  - `{:error, {:custom_error, details}}` - Adapter-specific errors
  
  ## Performance Considerations
  
  - Use `Stream` for memory-efficient record processing
  - Implement proper connection pooling for HTTP-based adapters
  - Handle rate limiting gracefully with exponential backoff
  - Provide accurate total counts for progress tracking
  - Consider pagination for large datasets
  - Implement connection reuse where possible
  
  ## Testing Your Adapter
  
  Use the provided test utilities to validate your adapter:
  
      defmodule MyApp.Adapters.CsvAdapterTest do
        use ExUnit.Case
        alias NCDB2Phx.Utilities.SourceAdapter
        
        test "csv adapter implements required behaviour" do
          adapter = MyApp.Adapters.CsvAdapter
          config = %{file_path: "test/fixtures/test_data.csv"}
          
          assert {:ok, state} = adapter.initialize(config)
          assert :ok = adapter.validate_connection(state)
          assert {:ok, count} = adapter.get_total_count(state)
          assert is_integer(count)
          
          records = adapter.stream_records(state) |> Enum.take(10)
          assert length(records) <= 10
          assert Enum.all?(records, &valid_record_format?/1)
        end
        
        defp valid_record_format?(%{data: _, source_record_id: _}), do: true
        defp valid_record_format?(_), do: false
      end
  """
  
  @type adapter_config :: map()
  @type adapter_state :: any()
  @type source_record :: %{
    data: map(),
    source_record_id: String.t(),
    source_metadata: map()
  }
  
  @doc """
  Initialize the adapter with the provided configuration.
  
  This function is called once during sync engine initialization to set up the adapter.
  It should validate the configuration, establish any necessary connections, and
  return the adapter state that will be passed to other callbacks.
  
  ## Parameters
  
  * `config` - Adapter-specific configuration map
  
  ## Returns
  
  * `{:ok, adapter_state}` - Success with initialized adapter state  
  * `{:error, reason}` - Initialization failed with error details
  
  ## Example
  
      def initialize(config) do
        with :ok <- validate_required_config(config),
             {:ok, connection} <- establish_connection(config) do
          {:ok, %{connection: connection, config: config}}
        end
      end
  """
  @callback initialize(adapter_config()) :: {:ok, adapter_state()} | {:error, any()}
  
  @doc """
  Stream records from the data source in a memory-efficient manner.
  
  This function should return a stream of normalized records that can be processed
  by the sync engine. Each record should include the source data, a unique identifier,
  and optional metadata about the record source.
  
  ## Parameters
  
  * `adapter_state` - State returned from initialize/1
  
  ## Returns
  
  * `Stream.t(source_record())` - Stream of normalized source records
  
  ## Record Format
  
  Each record in the stream should be a map with these keys:
  
  * `data` - The actual record data as a map
  * `source_record_id` - Unique identifier for the record in the source system
  * `source_metadata` - Optional metadata about the record (timestamps, version, etc.)
  
  ## Example
  
      def stream_records(adapter_state) do
        adapter_state.connection
        |> fetch_records_stream()
        |> Stream.map(fn raw_record ->
          %{
            data: raw_record.fields,
            source_record_id: raw_record.id,
            source_metadata: %{
              created_time: raw_record.created_time,
              source_type: :airtable
            }
          }
        end)
      end
  """
  @callback stream_records(adapter_state()) :: Stream.t(source_record())
  
  @doc """
  Validate that the adapter can successfully connect to and read from the data source.
  
  This function is called during sync initialization to ensure the source is available
  and accessible before starting the sync process. It should perform a lightweight
  test of connectivity and permissions.
  
  ## Parameters
  
  * `adapter_state` - State returned from initialize/1
  
  ## Returns
  
  * `:ok` - Connection is valid and functional
  * `{:error, reason}` - Connection failed with error details
  
  ## Example
  
      def validate_connection(adapter_state) do
        case test_connection(adapter_state.connection) do
          {:ok, _response} -> :ok
          {:error, reason} -> {:error, {:connection_failed, reason}}
        end
      end
  """
  @callback validate_connection(adapter_state()) :: :ok | {:error, any()}
  
  @doc """
  Get the total count of records available from the source (optional).
  
  This is used for progress tracking and time estimation during sync operations.
  If the source doesn't support efficient counting, you can return `{:error, :not_supported}`
  and the sync engine will work without progress estimates.
  
  ## Parameters
  
  * `adapter_state` - State returned from initialize/1
  
  ## Returns
  
  * `{:ok, count}` - Total record count as a non-negative integer
  * `{:error, reason}` - Count unavailable, not supported, or failed
  
  ## Example
  
      def get_total_count(adapter_state) do
        case count_records(adapter_state.connection) do
          {:ok, count} when is_integer(count) and count >= 0 -> {:ok, count}
          {:error, reason} -> {:error, {:count_failed, reason}}
        end
      end
  """
  @callback get_total_count(adapter_state()) :: {:ok, non_neg_integer()} | {:error, any()}
  
  @doc """
  Clean up adapter resources when sync completes (optional).
  
  This function is called after sync completion (successful or failed) to allow
  the adapter to clean up any resources, close connections, or perform final
  housekeeping tasks.
  
  ## Parameters
  
  * `adapter_state` - State returned from initialize/1
  
  ## Returns
  
  * `:ok` - Cleanup completed successfully
  * `{:error, reason}` - Cleanup failed (errors are logged but don't fail sync)
  """
  @callback cleanup(adapter_state()) :: :ok | {:error, any()}
  
  @optional_callbacks [get_total_count: 1, cleanup: 1]

  @doc """
  Normalize a record to the standard format expected by the sync engine.
  
  This utility function helps adapters convert source-specific record
  formats to the standard format used by the sync engine.
  
  ## Standard Format
  
      %{
        "id" => "unique_record_id",
        "fields" => %{
          "field1" => "value1",
          "field2" => "value2"
        },
        "created_at" => "2023-01-01T00:00:00Z",
        "updated_at" => "2023-01-01T00:00:00Z"
      }
  """
  @spec normalize_record(any(), keyword()) :: map()
  def normalize_record(source_record, opts \\ []) do
    id_field = Keyword.get(opts, :id_field, :id)
    fields_mapping = Keyword.get(opts, :fields_mapping, %{})
    
    # Extract ID
    record_id = extract_field(source_record, id_field)
    
    # Extract and map fields
    fields = if map_size(fields_mapping) > 0 do
      map_fields_with_mapping(source_record, fields_mapping)
    else
      extract_all_fields(source_record)
    end
    
    # Build normalized record
    %{
      "id" => record_id,
      "fields" => fields,
      "created_at" => extract_field(source_record, :created_at),
      "updated_at" => extract_field(source_record, :updated_at)
    }
    |> remove_nil_values()
  end

  @doc """
  Create a test adapter for development and testing purposes.
  
  This adapter generates synthetic records for testing the sync engine
  without requiring external data sources. Useful for development, testing,
  and demonstrating sync functionality.
  
  ## Options
  
  * `:record_count` - Number of test records to generate (default: 100)
  * `:record_template` - Function to generate record data (default: built-in template)
  * `:delay_ms` - Milliseconds to delay between records (default: 0, for testing rate limiting)
  
  ## Example
  
      {:ok, test_adapter} = NCDB2Phx.Utilities.SourceAdapter.create_test_adapter(
        record_count: 50,
        record_template: fn index ->
          %{
            data: %{
              name: "Customer \#{index}",
              email: "customer\#{index}@example.com",
              plan: Enum.random(["basic", "premium", "enterprise"])
            },
            source_record_id: "test_\#{index}",
            source_metadata: %{
              created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
              source_type: :test_data
            }
          }
        end
      )
      
      # Use in sync configuration
      config = %{
        source_adapter: test_adapter,
        source_config: %{},
        # ... other config
      }
  """
  @spec create_test_adapter(keyword()) :: {:ok, atom()}
  def create_test_adapter(opts \\ []) do
    record_count = Keyword.get(opts, :record_count, 100)
    record_template = Keyword.get(opts, :record_template, &default_test_record/1)
    delay_ms = Keyword.get(opts, :delay_ms, 0)
    
    # Create a unique module name based on options
    module_name = String.to_atom("Elixir.TestAdapter#{:crypto.strong_rand_bytes(8) |> Base.encode16()}")
    
    module_code = quote do
      @behaviour NCDB2Phx.Utilities.SourceAdapter
      
      def initialize(config) do
        {:ok, Map.merge(%{
          record_count: unquote(record_count),
          record_template: unquote(record_template),
          delay_ms: unquote(delay_ms)
        }, config)}
      end
      
      def stream_records(state) do
        1..state.record_count
        |> Stream.map(fn index ->
          if state.delay_ms > 0 do
            Process.sleep(state.delay_ms)
          end
          state.record_template.(index)
        end)
      end
      
      def validate_connection(_state) do
        :ok
      end
      
      def get_total_count(state) do
        {:ok, state.record_count}
      end
      
      def cleanup(_state) do
        :ok
      end
    end
    
    # Create the module dynamically
    Module.create(module_name, module_code, Macro.Env.location(__ENV__))
    {:ok, module_name}
  end

  # Private utility functions

  defp extract_field(record, field) when is_map(record) do
    case field do
      field when is_atom(field) ->
        Map.get(record, field) || Map.get(record, to_string(field))
      field when is_binary(field) ->
        Map.get(record, field) || Map.get(record, String.to_atom(field))
      [:fields, subfield] ->
        get_in(record, ["fields", subfield]) || get_in(record, [:fields, subfield])
      path when is_list(path) ->
        get_in(record, path)
      _ ->
        nil
    end
  end
  defp extract_field(_record, _field), do: nil

  defp extract_all_fields(record) when is_map(record) do
    # If record has a "fields" key, use that; otherwise use the entire record
    case Map.get(record, "fields") || Map.get(record, :fields) do
      nil -> 
        # Remove metadata fields and use the rest as fields
        Map.drop(record, ["id", :id, "created_at", :created_at, "updated_at", :updated_at])
      fields when is_map(fields) ->
        fields
      _ ->
        %{}
    end
  end
  defp extract_all_fields(_record), do: %{}

  defp map_fields_with_mapping(record, fields_mapping) do
    Enum.reduce(fields_mapping, %{}, fn {target_field, source_path}, acc ->
      value = extract_field(record, source_path)
      if value != nil do
        Map.put(acc, to_string(target_field), value)
      else
        acc
      end
    end)
  end

  defp remove_nil_values(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> v == nil end)
    |> Map.new()
  end

  defp default_test_record(index) do
    %{
      data: %{
        name: "Test Record \#{index}",
        description: "Generated test record number \#{index}",
        status: Enum.random(["active", "inactive", "pending"]),
        category: Enum.random(["category_a", "category_b", "category_c"]),
        sequence_number: index,
        created_at: DateTime.utc_now() |> DateTime.to_iso8601()
      },
      source_record_id: "test_record_\#{index}",
      source_metadata: %{
        generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        source_type: :test_adapter,
        record_index: index
      }
    }
  end
end