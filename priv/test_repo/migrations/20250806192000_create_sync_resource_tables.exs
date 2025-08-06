defmodule NCDB2Phx.TestRepo.Migrations.CreateSyncResourceTables do
  @moduledoc """
  Creates the required tables for NCDB2Phx Ash resources.
  
  This migration manually creates the tables that should be auto-generated
  by `mix ash.codegen` but aren't being detected properly.
  """
  
  use Ecto.Migration

  def up do
    # Create airtable_sync_sessions table (from SyncSession resource)
    create table(:airtable_sync_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :session_id, :string, null: false, size: 100
      add :sync_type, :string, null: false
      add :target_resource, :string, null: false, size: 255
      add :source_adapter, :string, null: false, size: 255
      add :status, :string, null: false, default: "pending"
      add :progress_stats, :map, default: %{}
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :duration_ms, :integer
      add :error_count, :integer, null: false, default: 0
      add :error_details, :map, default: %{}
      add :last_error, :string, size: 1000
      add :config, :map, null: false, default: %{}
      add :metadata, :map, default: %{}
      add :initiated_by, :string, size: 255
      add :estimated_total, :integer
      add :actual_total, :integer
      
      timestamps(type: :utc_datetime_usec)
    end

    # Create generic_sync_batches table (from SyncBatch resource)
    create table(:generic_sync_batches, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :session_id, :string, null: false, size: 255
      add :batch_number, :integer, null: false
      add :batch_size, :integer, null: false
      add :status, :string, null: false, default: "pending"
      add :source_ids, {:array, :string}, default: []
      add :records_processed, :integer, null: false, default: 0
      add :records_created, :integer, null: false, default: 0
      add :records_updated, :integer, null: false, default: 0
      add :records_existing, :integer, null: false, default: 0
      add :records_failed, :integer, null: false, default: 0
      add :error_details, :map
      add :retry_count, :integer, null: false, default: 0
      add :recovery_attempted, :boolean, null: false, default: false
      add :recovery_successful, :boolean
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :processing_time_ms, :integer
      add :metadata, :map, default: %{}
      
      timestamps(type: :utc_datetime_usec)
    end

    # Create generic_sync_logs table (from SyncLog resource)  
    create table(:generic_sync_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :session_id, :string, size: 255
      add :batch_id, :binary_id
      add :level, :string, null: false, default: "info"
      add :event_type, :string, null: false
      add :message, :string, null: false, size: 2000
      add :data, :map, default: %{}
      add :context, :map, default: %{}
      add :error_details, :map
      add :error_category, :string, size: 100
      add :duration_ms, :integer
      add :performance_metrics, :map
      add :source_module, :string, size: 500
      add :source_function, :string, size: 200
      add :source_line, :integer
      add :correlation_id, :string, size: 255
      add :trace_id, :string, size: 255
      add :node_name, :string, size: 255
      add :process_pid, :string, size: 100
      add :logged_at, :utc_datetime_usec, null: false
      
      timestamps(type: :utc_datetime_usec)
    end

    # Create indexes
    
    # SyncSession indexes
    create unique_index(:airtable_sync_sessions, [:session_id])
    
    # SyncBatch indexes
    create index(:generic_sync_batches, [:session_id])
    create unique_index(:generic_sync_batches, [:session_id, :batch_number])
    create index(:generic_sync_batches, [:status])
    create index(:generic_sync_batches, [:started_at])
    create index(:generic_sync_batches, [:completed_at])
    create index(:generic_sync_batches, [:session_id, :status])
    
    # SyncLog indexes
    create index(:generic_sync_logs, [:session_id])
    create index(:generic_sync_logs, [:level])
    create index(:generic_sync_logs, [:event_type])
    create index(:generic_sync_logs, [:logged_at])
    create index(:generic_sync_logs, [:session_id, :logged_at])
    create index(:generic_sync_logs, [:level, :logged_at])
    create index(:generic_sync_logs, [:event_type, :logged_at])
    # Note: Full-text search index on message would need CREATE EXTENSION if not exists pg_trgm
    # create index(:generic_sync_logs, [:message], using: "gin")
  end

  def down do
    drop table(:generic_sync_logs)
    drop table(:generic_sync_batches) 
    drop table(:airtable_sync_sessions)
  end
end