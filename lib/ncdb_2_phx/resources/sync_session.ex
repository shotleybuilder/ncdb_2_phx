defmodule NCDB2Phx.Resources.SyncSession do
  @moduledoc """
  Generic Ash resource for tracking sync sessions across any application.
  
  This resource provides a domain-agnostic way to track sync operations
  that can work with any Ash-based application. It's designed to be used
  as part of the `ncdb_2_phx` package with minimal coupling to
  the host application.
  
  ## Features
  
  - Generic sync session tracking for any resource type
  - Configurable sync types and statuses
  - Progress tracking with statistics
  - Error information storage
  - Flexible metadata storage
  - Time-based queries and filtering
  - Audit trail capabilities
  
  ## Resource Configuration
  
  Host applications can customize this resource by:
  
  1. **Extending sync types**: Add application-specific sync types
  2. **Custom validations**: Add domain-specific validation rules
  3. **Additional fields**: Extend with application-specific metadata
  4. **Custom actions**: Add specialized actions for the domain
  5. **Policies**: Configure authorization policies
  
  ## Example Usage
  
      # Create a new sync session
      {:ok, session} = Ash.create(NCDB2Phx.Resources.SyncSession, %{
        session_id: "sync_abc123",
        sync_type: :import_users,
        target_resource: "MyApp.Accounts.User",
        source_adapter: "MyApp.Sync.Adapters.CsvAdapter",
        initiated_by: "admin@example.com",
        estimated_total: 1000,
        config: %{
          batch_size: 100,
          enable_error_recovery: true
        }
      })
      
      # Update session progress
      {:ok, updated_session} = Ash.update(session, %{
        status: :running,
        progress_stats: %{
          processed: 150,
          created: 50,
          updated: 75,
          existing: 20,
          errors: 5
        }
      })
  """
  
  use Ash.Resource,
    domain: NCDB2Phx,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPhoenix.Form]

  require Ash.Query
  import Ash.Expr

  postgres do
    table "airtable_sync_sessions"
    if Mix.env() in [:test, :dev] do
      repo NCDB2Phx.TestRepo
    end
  end

  attributes do
    uuid_primary_key :id
    
    # Core session identification
    attribute :session_id, :string do
      allow_nil? false
      constraints max_length: 100
      description "Unique identifier for the sync session"
    end
    
    # Sync operation metadata
    attribute :sync_type, :atom do
      allow_nil? false
      constraints one_of: [
        :import_airtable,
        :export_airtable,
        :bidirectional_sync,
        :import_csv,
        :import_api,
        :import_database,
        :custom_sync
      ]
      description "Type of sync operation being performed"
    end
    
    attribute :target_resource, :string do
      allow_nil? false
      constraints max_length: 255
      description "Full module name of the target Ash resource"
    end
    
    attribute :source_adapter, :string do
      allow_nil? false
      constraints max_length: 255
      description "Full module name of the source adapter"
    end
    
    # Session status and progress
    attribute :status, :atom do
      allow_nil? false
      default :pending
      constraints one_of: [
        :pending,
        :initializing,
        :running,
        :paused,
        :completed,
        :failed,
        :cancelled
      ]
      description "Current status of the sync session"
    end
    
    attribute :progress_stats, :map do
      default %{}
      description "Statistics about sync progress (processed, created, updated, etc.)"
    end
    
    # Timing information
    attribute :started_at, :utc_datetime do
      description "When the sync session was started"
    end
    
    attribute :completed_at, :utc_datetime do
      description "When the sync session was completed"
    end
    
    attribute :duration_ms, :integer do
      constraints min: 0
      description "Total duration of the sync session in milliseconds"
    end
    
    # Error and logging information
    attribute :error_count, :integer do
      allow_nil? false
      default 0
      constraints min: 0
      description "Total number of errors encountered during sync"
    end
    
    attribute :error_details, :map do
      default %{}
      description "Detailed error information and context"
    end
    
    attribute :last_error, :string do
      constraints max_length: 1000
      description "Most recent error message"
    end
    
    # Configuration and metadata
    attribute :config, :map do
      allow_nil? false
      default %{}
      description "Configuration parameters used for this sync session"
    end
    
    attribute :metadata, :map do
      default %{}
      description "Additional metadata for host application use"
    end
    
    # User and audit information
    attribute :initiated_by, :string do
      constraints max_length: 255
      description "User or system that initiated the sync session"
    end
    
    # Estimated totals for progress calculation
    attribute :estimated_total, :integer do
      constraints min: 0
      description "Estimated total number of records to process"
    end
    
    attribute :actual_total, :integer do
      constraints min: 0
      description "Actual total number of records processed"
    end
    
    # Standard timestamps
    timestamps()
  end

  identities do
    identity :unique_session_id, [:session_id]
  end

  relationships do
    has_many :sync_batches, NCDB2Phx.Resources.SyncBatch do
      destination_attribute :session_id
      source_attribute :session_id
    end
    
    has_many :sync_logs, NCDB2Phx.Resources.SyncLog do
      destination_attribute :session_id
      source_attribute :session_id
    end
  end

  calculations do
    calculate :processing_speed, :float, expr(
      if actual_total > 0 and duration_ms > 0 do
        actual_total * 1000.0 / duration_ms
      else
        0.0
      end
    ) do
      description "Records processed per second"
    end
    
    calculate :progress_percentage, :float, expr(
      if estimated_total > 0 do
        get_path(progress_stats, [:processed]) * 100.0 / estimated_total
      else
        0.0
      end
    ) do
      description "Completion percentage based on estimated total"
    end
    
    calculate :error_rate, :float, expr(
      if actual_total > 0 do
        error_count * 100.0 / actual_total
      else
        0.0
      end
    ) do
      description "Error rate as percentage of total processed"
    end
    
    calculate :is_active, :boolean, expr(status in [:pending, :initializing, :running, :paused]) do
      description "Whether the sync session is currently active"
    end
    
    calculate :success_rate, :float, expr(
      if actual_total > 0 do
        (actual_total - error_count) * 100.0 / actual_total
      else
        0.0
      end
    ) do
      description "Success rate as percentage of total processed"
    end
  end

  aggregates do
    count :total_batches, :sync_batches do
      description "Total number of batches processed in this session"
    end
    
    count :completed_batches, :sync_batches do
      filter expr(status == :completed)
      description "Number of successfully completed batches"
    end
    
    count :failed_batches, :sync_batches do
      filter expr(status == :failed)
      description "Number of failed batches"
    end
    
    sum :total_batch_records, :sync_batches, :records_processed do
      description "Total records processed across all batches"
    end
    
    count :total_log_entries, :sync_logs do
      description "Total number of log entries for this session"
    end
    
    count :error_log_entries, :sync_logs do
      filter expr(level == :error)
      description "Number of error log entries"
    end
  end

  actions do
    defaults [:read, :destroy]
    
    read :get_session do
      argument :session_id, :string, allow_nil?: false
      filter expr(session_id == ^arg(:session_id))
    end
    
    create :create do
      accept [
        :session_id,
        :sync_type,
        :target_resource,
        :source_adapter,
        :config,
        :metadata,
        :initiated_by,
        :estimated_total
      ]
      
      change set_attribute(:status, :pending)
      change set_attribute(:started_at, &DateTime.utc_now/0)
    end
    
    create :create_session do
      accept [
        :session_id,
        :sync_type,
        :target_resource,
        :source_adapter,
        :config,
        :metadata,
        :initiated_by,
        :estimated_total
      ]
      
      argument :actor, :map, allow_nil?: true
      
      change set_attribute(:status, :pending)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change fn changeset, _context ->
        if actor = Ash.Changeset.get_argument(changeset, :actor) do
          user_identifier = extract_user_identifier(actor)
          Ash.Changeset.change_attribute(changeset, :initiated_by, user_identifier)
        else
          changeset
        end
      end
    end
    
    create :start_session do
      accept [
        :session_id,
        :sync_type,
        :target_resource,
        :source_adapter,
        :config,
        :metadata,
        :estimated_total
      ]
      
      argument :actor, :map, allow_nil?: true
      
      change set_attribute(:status, :running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change fn changeset, _context ->
        if actor = Ash.Changeset.get_argument(changeset, :actor) do
          user_identifier = extract_user_identifier(actor)
          Ash.Changeset.change_attribute(changeset, :initiated_by, user_identifier)
        else
          changeset
        end
      end
    end
    
    update :update do
      require_atomic? false
      accept [
        :status,
        :progress_stats,
        :error_count,
        :error_details,
        :last_error,
        :metadata,
        :actual_total
      ]
      
      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :status) do
          status when status in [:completed, :failed, :cancelled] ->
            changeset
            |> Ash.Changeset.change_attribute(:completed_at, DateTime.utc_now())
            |> calculate_duration()
            
          _ ->
            changeset
        end
      end
    end
    
    update :mark_running do
      require_atomic? false
      change set_attribute(:status, :running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
    end
    
    update :mark_completed do
      require_atomic? false
      argument :final_stats, :map, allow_nil?: false
      
      change set_attribute(:status, :completed)
      change set_attribute(:completed_at, &DateTime.utc_now/0)
      change fn changeset, _context ->
        final_stats = Ash.Changeset.get_argument(changeset, :final_stats)
        changeset
        |> Ash.Changeset.change_attribute(:progress_stats, final_stats)
        |> Ash.Changeset.change_attribute(:actual_total, Map.get(final_stats, :total_processed, 0))
        |> calculate_duration()
      end
    end
    
    update :mark_failed do
      require_atomic? false
      argument :error_info, :map, allow_nil?: false
      
      change set_attribute(:status, :failed)
      change set_attribute(:completed_at, &DateTime.utc_now/0)
      change fn changeset, _context ->
        error_info = Ash.Changeset.get_argument(changeset, :error_info)
        changeset
        |> Ash.Changeset.change_attribute(:error_details, error_info)
        |> Ash.Changeset.change_attribute(:last_error, Map.get(error_info, :message, "Unknown error"))
        |> calculate_duration()
      end
    end
    
    update :update_progress do
      require_atomic? false
      argument :progress_update, :map, allow_nil?: false
      
      change fn changeset, _context ->
        progress_update = Ash.Changeset.get_argument(changeset, :progress_update)
        current_stats = Ash.Changeset.get_attribute(changeset, :progress_stats) || %{}
        updated_stats = Map.merge(current_stats, progress_update)
        
        changeset
        |> Ash.Changeset.change_attribute(:progress_stats, updated_stats)
        |> Ash.Changeset.change_attribute(:actual_total, Map.get(updated_stats, :processed, 0))
      end
    end
    
    update :increment_errors do
      require_atomic? false
      argument :error_details, :map, allow_nil?: true
      
      change fn changeset, _context ->
        current_error_count = Ash.Changeset.get_attribute(changeset, :error_count) || 0
        error_details = Ash.Changeset.get_argument(changeset, :error_details)
        
        updated_changeset = Ash.Changeset.change_attribute(changeset, :error_count, current_error_count + 1)
        
        if error_details do
          current_error_details = Ash.Changeset.get_attribute(changeset, :error_details) || %{}
          updated_error_details = Map.merge(current_error_details, error_details)
          
          updated_changeset
          |> Ash.Changeset.change_attribute(:error_details, updated_error_details)
          |> Ash.Changeset.change_attribute(:last_error, Map.get(error_details, :message, "Error details provided"))
        else
          Ash.Changeset.change_attribute(updated_changeset, :last_error, "Error occurred without details")
        end
      end
    end
  end

  code_interface do
    define :create_session, args: [:session_id, :sync_type, :target_resource, :source_adapter]
    define :start_session, args: [:session_id, :sync_type, :target_resource, :source_adapter]
    define :get_session, get_by: [:session_id]
    define :mark_running
    define :mark_completed, args: [:final_stats]
    define :mark_failed, args: [:error_info]
    define :update_progress, args: [:progress_update]
    define :increment_errors, args: [:error_details]
  end

  validations do
    validate present([:session_id, :sync_type, :target_resource, :source_adapter])
    
    validate fn changeset, _context ->
      session_id = Ash.Changeset.get_attribute(changeset, :session_id)
      
      if String.match?(session_id || "", ~r/^[a-zA-Z0-9_-]+$/) do
        :ok
      else
        {:error, field: :session_id, message: "must contain only letters, numbers, hyphens, and underscores"}
      end
    end
    
    validate fn changeset, _context ->
      estimated_total = Ash.Changeset.get_attribute(changeset, :estimated_total)
      actual_total = Ash.Changeset.get_attribute(changeset, :actual_total)
      
      cond do
        is_nil(estimated_total) and is_nil(actual_total) ->
          :ok
          
        not is_nil(estimated_total) and estimated_total < 0 ->
          {:error, field: :estimated_total, message: "must be non-negative"}
          
        not is_nil(actual_total) and actual_total < 0 ->
          {:error, field: :actual_total, message: "must be non-negative"}
          
        true ->
          :ok
      end
    end
  end

  # Helper functions for changes

  defp calculate_duration(changeset) do
    started_at = Ash.Changeset.get_attribute(changeset, :started_at)
    completed_at = Ash.Changeset.get_attribute(changeset, :completed_at)
    
    if started_at and completed_at do
      duration_ms = DateTime.diff(completed_at, started_at, :millisecond)
      Ash.Changeset.change_attribute(changeset, :duration_ms, duration_ms)
    else
      changeset
    end
  end

  defp extract_user_identifier(nil), do: "system"
  defp extract_user_identifier(actor) when is_map(actor) do
    Map.get(actor, :email, Map.get(actor, :username, Map.get(actor, :id, "unknown_user")))
  end
  defp extract_user_identifier(actor), do: to_string(actor)

  # Code interface helper functions

  def list_active_sessions(opts \\ []) do
    NCDB2Phx.Resources.SyncSession
    |> Ash.Query.filter(is_active == true)
    |> Ash.read(opts)
  end

  def get_session_summary(session) do
    %{
      session_id: session.session_id,
      sync_type: session.sync_type,
      status: session.status,
      progress_percentage: session.progress_percentage,
      processing_speed: session.processing_speed,
      error_rate: session.error_rate,
      duration_ms: session.duration_ms,
      started_at: session.started_at,
      completed_at: session.completed_at
    }
  end

  def get_processing_speed(session) do
    if session.actual_total && session.actual_total > 0 && session.duration_ms && session.duration_ms > 0 do
      session.actual_total * 1000.0 / session.duration_ms
    else
      0.0
    end
  end
end