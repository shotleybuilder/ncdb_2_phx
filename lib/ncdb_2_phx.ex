defmodule NCDB2Phx do
  @moduledoc """
  NCDB2Phx - A no-code database to Phoenix import engine with Ash Framework.
  
  This package provides a complete, generic sync system that can be used in any
  Phoenix/Ash application. It includes all the resources, utilities, and
  interfaces needed for sync operations.
  
  ## Features
  
  - Generic sync engine with pluggable adapters
  - Universal progress tracking and monitoring
  - Real-time LiveView components
  - Comprehensive error handling and recovery
  - Domain-agnostic Ash resources
  - Event-driven architecture with PubSub
  
  ## Usage in Host Applications
  
      # Add to your application's domain
      defmodule MyApp.Sync do
        use Ash.Domain
        
        resources do
          # Use generic resources directly
          resource NCDB2Phx.Resources.SyncSession
          resource NCDB2Phx.Resources.SyncBatch
          resource NCDB2Phx.Resources.SyncLog
          
          # Or extend them for your domain
          resource MyApp.Sync.CustomSyncSession
        end
      end
      
      # Configure sync operations
      config = %{
        source_adapter: MyApp.Adapters.CsvAdapter,
        source_config: %{file_path: "/data/users.csv"},
        target_resource: MyApp.Accounts.User,
        target_config: %{unique_field: :email},
        processing_config: %{batch_size: 100, limit: 1000},
        pubsub_config: %{module: MyApp.PubSub, topic: "sync_progress"},
        session_config: %{sync_type: :import_users}
      }
      
      # Execute sync
      {:ok, result} = NCDB2Phx.execute_sync(config)
  
  ## Architecture Components
  
  ### Core Engine
  - `SyncEngine` - Main sync orchestration
  - `SourceAdapter` - Pluggable data source interface
  - `TargetProcessor` - Generic Ash resource processing
  - `ConfigValidator` - Configuration validation
  
  ### Progress & Events
  - `ProgressTracker` - Real-time progress monitoring
  - `EventSystem` - Universal PubSub event broadcasting
  - `Components` - Reusable LiveView components
  
  ### Error Handling
  - `ErrorHandler` - Generic error handling and recovery
  - `RecordValidator` - Configurable record validation
  - `RecordTransformer` - Data transformation pipeline
  
  ### Resources
  - `SyncSession` - Session tracking
  - `SyncBatch` - Batch-level progress
  - `SyncLog` - Comprehensive logging
  
  ### Adapters
  - `AirtableAdapter` - Production-ready Airtable integration
  - Extensible adapter system for other data sources
  
  ## Package Features
  
  1. **Zero Host Coupling**: Works with any Ash resource
  2. **Pluggable Architecture**: Easy to extend and customize
  3. **Configuration Driven**: All behavior configurable
  4. **Universal UI Components**: Work in any Phoenix app
  5. **Comprehensive Testing**: Full test coverage included
  6. **Production Ready**: Used in real applications
  """
  
  use Ash.Domain

  resources do
    resource NCDB2Phx.Resources.SyncSession
    resource NCDB2Phx.Resources.SyncBatch  
    resource NCDB2Phx.Resources.SyncLog
  end

  # Domain-level code interface for easy access
  
  def create_sync_session(attrs, opts \\ []) do
    NCDB2Phx.Resources.SyncSession.create_session(attrs, opts)
  end

  def start_sync_session(attrs, opts \\ []) do
    NCDB2Phx.Resources.SyncSession.start_session(attrs, opts)
  end

  def get_sync_session(session_id, opts \\ []) do
    NCDB2Phx.Resources.SyncSession.get_session(session_id, opts)
  end

  def list_active_sessions(opts \\ []) do
    NCDB2Phx.Resources.SyncSession.list_active_sessions(opts)
  end

  def create_sync_batch(attrs, opts \\ []) do
    NCDB2Phx.Resources.SyncBatch.create_batch(attrs, opts)
  end

  def log_sync_event(attrs, opts \\ []) do
    NCDB2Phx.Resources.SyncLog.log_event(attrs, opts)
  end

  def log_sync_error(attrs, opts \\ []) do
    NCDB2Phx.Resources.SyncLog.log_error(attrs, opts)
  end

  # High-level sync operations

  @doc """
  Execute a complete sync operation with the generic engine.
  
  This is the main entry point for sync operations using the generic
  architecture. It handles configuration validation, adapter initialization,
  progress tracking, and error handling.
  
  ## Example
  
      config = %{
        source_adapter: NCDB2Phx.Adapters.AirtableAdapter,
        source_config: %{
          api_key: "key123",
          base_id: "app123", 
          table_id: "tbl123"
        },
        target_resource: MyApp.Cases.Case,
        target_config: %{unique_field: :regulator_id},
        processing_config: %{batch_size: 100, limit: 1000},
        pubsub_config: %{module: MyApp.PubSub, topic: "sync_progress"},
        session_config: %{sync_type: :import_cases}
      }
      
      {:ok, result} = NCDB2Phx.execute_sync(config, actor: admin_user)
  """
  def execute_sync(config, opts \\ []) do
    NCDB2Phx.SyncEngine.execute_sync(config, opts)
  end

  def stream_sync_records(config, opts \\ []) do
    NCDB2Phx.SyncEngine.stream_and_process(config, opts)
  end

  def get_sync_status(session_id) do
    NCDB2Phx.SyncEngine.get_sync_status(session_id)
  end

  def cancel_sync(session_id) do
    NCDB2Phx.SyncEngine.cancel_sync(session_id)
  end

  # Event system operations

  def broadcast_sync_event(event_type, event_data, opts \\ []) do
    NCDB2Phx.Systems.EventSystem.broadcast_sync_event(event_type, event_data, opts)
  end

  def subscribe_to_sync_events(topic) do
    NCDB2Phx.Systems.EventSystem.subscribe(topic)
  end

  def stream_sync_events(topic, opts \\ []) do
    NCDB2Phx.Systems.EventSystem.stream_events(topic, opts)
  end

  # Utility functions for package users

  @doc """
  Create a new source adapter for custom data sources.
  
  Returns a test adapter that can be used for development and testing.
  """
  def create_test_adapter(opts \\ []) do
    NCDB2Phx.Utilities.SourceAdapter.create_test_adapter(opts)
  end

  @doc """
  Validate sync configuration before execution.
  
  Useful for validating configuration in forms or APIs before
  starting sync operations.
  """
  def validate_sync_config(config, opts \\ []) do
    NCDB2Phx.Utilities.ConfigValidator.validate_sync_config(config, opts)
  end

  @doc """
  Get comprehensive sync metrics and statistics.
  
  Returns detailed information about sync performance, error rates,
  and operational metrics.
  """
  def get_sync_metrics(session_id_or_filter, opts \\ []) do
    case session_id_or_filter do
      session_id when is_binary(session_id) ->
        get_session_metrics(session_id, opts)
        
      filter when is_list(filter) ->
        get_aggregate_metrics(filter, opts)
        
      _ ->
        {:error, :invalid_metrics_query}
    end
  end

  # Package information and metadata

  def package_info do
    %{
      name: "ncdb_2_phx",
      version: "1.0.0",
      description: "No-code database to Phoenix import engine with Ash Framework",
      features: [
        "Pluggable source adapters",
        "Real-time progress tracking", 
        "LiveView components",
        "Comprehensive error handling",
        "Event-driven architecture",
        "Domain-agnostic resources"
      ],
      requirements: [
        "Phoenix >= 1.7.0",
        "Ash >= 3.0.0", 
        "AshPostgres >= 2.0.0",
        "AshPhoenix >= 2.0.0"
      ],
      example_adapters: [
        "Airtable (included)",
        "CSV files",
        "REST APIs",
        "Database sources"
      ]
    }
  end

  # Private helper functions

  defp get_session_metrics(session_id, _opts) do
    with {:ok, session} <- get_sync_session(session_id),
         {:ok, batches} <- NCDB2Phx.Resources.SyncBatch.list_session_batches(session_id),
         {:ok, logs} <- NCDB2Phx.Resources.SyncLog.list_session_logs(session_id) do
      
      %{
        session: NCDB2Phx.Resources.SyncSession.get_session_summary(session),
        batch_summary: %{
          total_batches: length(batches),
          completed_batches: Enum.count(batches, &(&1.status == :completed)),
          failed_batches: Enum.count(batches, &(&1.status == :failed)),
          average_batch_time: calculate_average_batch_time(batches)
        },
        log_summary: NCDB2Phx.Resources.SyncLog.get_session_log_summary(session_id),
        performance_metrics: calculate_performance_metrics(session, batches, logs)
      }
    else
      error -> error
    end
  end

  defp get_aggregate_metrics(_filter, _opts) do
    # This would implement aggregate metrics across multiple sessions
    # For now, return a placeholder
    %{
      total_sessions: 0,
      active_sessions: 0,
      average_success_rate: 0.0,
      total_records_processed: 0
    }
  end

  defp calculate_average_batch_time(batches) do
    completed_batches = Enum.filter(batches, &(&1.processing_time_ms != nil))
    
    if length(completed_batches) > 0 do
      total_time = Enum.reduce(completed_batches, 0, &(&2 + &1.processing_time_ms))
      Float.round(total_time / length(completed_batches), 2)
    else
      0.0
    end
  end

  defp calculate_performance_metrics(session, batches, logs) do
    %{
      records_per_second: calculate_records_per_second(session),
      error_rate: calculate_error_rate(session),
      batch_success_rate: calculate_batch_success_rate(batches),
      log_error_rate: calculate_log_error_rate(logs)
    }
  end

  defp calculate_records_per_second(session) do
    NCDB2Phx.Resources.SyncSession.get_processing_speed(session)
  end

  defp calculate_error_rate(session) do
    case {Map.get(session.progress_stats, :processed, 0), session.error_count} do
      {0, _} -> 0.0
      {processed, errors} -> Float.round(errors / processed * 100, 2)
    end
  end

  defp calculate_batch_success_rate(batches) do
    if length(batches) > 0 do
      successful = Enum.count(batches, &(&1.status == :completed))
      Float.round(successful / length(batches) * 100, 2)
    else
      0.0
    end
  end

  defp calculate_log_error_rate(logs) do
    if length(logs) > 0 do
      errors = Enum.count(logs, &(&1.level == :error))
      Float.round(errors / length(logs) * 100, 2)
    else
      0.0
    end
  end
end