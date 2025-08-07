defmodule NCDB2Phx.API.SessionController do
  use Phoenix.Controller, formats: [:json]

  action_fallback NCDB2Phx.API.FallbackController

  @doc """
  Get real-time progress data for a sync session.
  
  Returns JSON with current progress, metrics, and status.
  """
  def progress(conn, %{"id" => session_id}) do
    with {:ok, session} <- get_sync_session(session_id),
         progress_data <- build_progress_response(session) do
      json(conn, progress_data)
    end
  end

  @doc """
  Get paginated logs for a specific sync session.
  
  Supports filtering by log level and pagination parameters.
  """
  def logs(conn, %{"id" => session_id} = params) do
    log_params = extract_log_params(params)
    
    with {:ok, logs} <- list_session_logs(session_id, log_params),
         pagination <- build_pagination(logs, log_params) do
      json(conn, %{
        logs: format_logs_for_api(logs),
        pagination: pagination,
        session_id: session_id
      })
    end
  end

  @doc """
  Cancel a running or pending sync session.
  
  Returns the updated session status.
  """
  def cancel(conn, %{"id" => session_id}) do
    with {:ok, session} <- get_sync_session(session_id),
         :ok <- validate_cancellable_status(session.status),
         {:ok, updated_session} <- cancel_sync_session(session_id) do
      json(conn, %{
        status: "cancelled",
        session: format_session_for_api(updated_session),
        message: "Session cancelled successfully"
      })
    end
  end

  @doc """
  Retry a failed or cancelled sync session.
  
  Creates a new session with the same configuration.
  """
  def retry(conn, %{"id" => session_id}) do
    with {:ok, session} <- get_sync_session(session_id),
         :ok <- validate_retryable_status(session.status),
         {:ok, new_session} <- retry_sync_session(session_id) do
      json(conn, %{
        status: "retrying",
        original_session_id: session_id,
        new_session: format_session_for_api(new_session),
        message: "Session retry initiated successfully"
      })
    end
  end

  # Private functions

  defp get_sync_session(session_id) do
    # TODO: Load session from NCDB2Phx.Resources.SyncSession
    case session_id do
      nil -> {:error, :not_found}
      "" -> {:error, :not_found}
      _ -> {:ok, mock_session(session_id)}
    end
  end

  defp build_progress_response(session) do
    %{
      session_id: session.id,
      status: session.status,
      progress: %{
        percentage: session.progress || 0,
        current_batch: session.current_batch || 0,
        total_batches: session.total_batches || 0,
        processed_records: session.processed_records || 0,
        total_records: session.total_records || 0,
        failed_records: session.failed_records || 0
      },
      metrics: %{
        records_per_second: calculate_records_per_second(session),
        avg_processing_time: calculate_avg_processing_time(session),
        error_rate: calculate_error_rate(session),
        estimated_time_remaining: calculate_eta(session)
      },
      timestamps: %{
        started_at: session.inserted_at,
        updated_at: session.updated_at,
        estimated_completion: calculate_estimated_completion(session)
      }
    }
  end

  defp list_session_logs(session_id, params) do
    # TODO: Load from NCDB2Phx.Resources.SyncLog with filtering and pagination
    {:ok, mock_logs(session_id, params)}
  end

  defp extract_log_params(params) do
    %{
      level: params["level"],
      limit: parse_int_param(params["limit"], 50),
      offset: parse_int_param(params["offset"], 0),
      search: params["search"]
    }
  end

  defp build_pagination(logs, params) do
    %{
      limit: params.limit,
      offset: params.offset,
      total: length(logs), # TODO: Get actual total count
      has_more: length(logs) == params.limit
    }
  end

  defp format_logs_for_api(logs) do
    Enum.map(logs, fn log ->
      %{
        id: log.id,
        level: log.level,
        message: log.message,
        timestamp: log.timestamp,
        session_id: log.session_id,
        batch_id: log.batch_id,
        context: log.context || %{},
        stack_trace: log.stack_trace
      }
    end)
  end

  defp validate_cancellable_status(status) when status in [:running, :pending] do
    :ok
  end
  defp validate_cancellable_status(_status) do
    {:error, :not_cancellable}
  end

  defp validate_retryable_status(status) when status in [:failed, :cancelled] do
    :ok
  end
  defp validate_retryable_status(_status) do
    {:error, :not_retryable}
  end

  defp cancel_sync_session(session_id) do
    # TODO: Implement session cancellation via NCDB2Phx.cancel_sync/1
    {:ok, mock_session(session_id, %{status: :cancelled})}
  end

  defp retry_sync_session(session_id) do
    # TODO: Implement session retry via NCDB2Phx.retry_sync_session/1
    new_session_id = "#{session_id}_retry_#{System.system_time(:second)}"
    {:ok, mock_session(new_session_id, %{status: :pending})}
  end

  defp format_session_for_api(session) do
    %{
      id: session.id,
      name: session.name,
      status: session.status,
      progress: session.progress,
      inserted_at: session.inserted_at,
      updated_at: session.updated_at,
      config: session.config
    }
  end

  defp parse_int_param(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end
  defp parse_int_param(_value, default), do: default

  defp calculate_records_per_second(session) do
    # TODO: Calculate based on actual session data
    if session.status == :running do
      125
    else
      0
    end
  end

  defp calculate_avg_processing_time(_session) do
    # TODO: Calculate from batch processing times
    150
  end

  defp calculate_error_rate(session) do
    # TODO: Calculate from session statistics
    processed = session.processed_records || 0
    failed = session.failed_records || 0
    
    if processed + failed > 0 do
      failed / (processed + failed)
    else
      0.0
    end
  end

  defp calculate_eta(session) do
    # TODO: Calculate estimated time remaining
    if session.status == :running and session.progress do
      remaining_percentage = 100 - (session.progress || 0)
      estimated_seconds = div(remaining_percentage * 300, 100) # Mock calculation
      estimated_seconds
    else
      nil
    end
  end

  defp calculate_estimated_completion(session) do
    case calculate_eta(session) do
      nil -> nil
      seconds -> DateTime.add(DateTime.utc_now(), seconds, :second)
    end
  end

  # Mock data functions - TODO: Remove when real implementation is ready

  defp mock_session(session_id, overrides \\ %{}) do
    base_session = %{
      id: session_id,
      name: "Mock Session",
      status: :running,
      progress: 65,
      current_batch: 7,
      total_batches: 10,
      processed_records: 3250,
      total_records: 5000,
      failed_records: 15,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      config: %{
        source_adapter: "AirtableAdapter",
        batch_size: 100
      }
    }

    Map.merge(base_session, overrides)
  end

  defp mock_logs(session_id, params) do
    base_logs = [
      %{
        id: "log_1",
        level: :info,
        message: "Processing batch 7 of 10",
        timestamp: DateTime.utc_now(),
        session_id: session_id,
        batch_id: "batch_7",
        context: %{batch_size: 100, records_processed: 650}
      },
      %{
        id: "log_2", 
        level: :warn,
        message: "Retrying failed record due to timeout",
        timestamp: DateTime.add(DateTime.utc_now(), -30, :second),
        session_id: session_id,
        batch_id: "batch_6",
        context: %{record_id: "rec_123", retry_attempt: 2}
      },
      %{
        id: "log_3",
        level: :info,
        message: "Batch 6 completed successfully",
        timestamp: DateTime.add(DateTime.utc_now(), -60, :second),
        session_id: session_id,
        batch_id: "batch_6",
        context: %{success_count: 95, failed_count: 5}
      }
    ]

    # Apply basic filtering
    filtered_logs = case params[:level] do
      nil -> base_logs
      level -> Enum.filter(base_logs, &(&1.level == String.to_atom(level)))
    end

    # Apply search filtering
    filtered_logs = case params[:search] do
      nil -> filtered_logs
      "" -> filtered_logs
      search_term -> 
        Enum.filter(filtered_logs, fn log ->
          String.contains?(String.downcase(log.message), String.downcase(search_term))
        end)
    end

    # Apply pagination
    filtered_logs
    |> Enum.drop(params[:offset] || 0)
    |> Enum.take(params[:limit] || 50)
  end
end