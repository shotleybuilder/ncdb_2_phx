defmodule NCDB2Phx.TestHelpers do
  @moduledoc """
  Helper functions for tests
  """

  @doc """
  Creates a simple test data source adapter config
  """
  def test_source_config do
    %{
      source_adapter: NCDB2Phx.TestAdapter,
      source_config: %{
        data: [
          %{id: 1, name: "Test Record 1", value: "A"},
          %{id: 2, name: "Test Record 2", value: "B"},
          %{id: 3, name: "Test Record 3", value: "C"}
        ]
      },
      target_resource: NCDB2Phx.TestResource,
      target_config: %{unique_field: :id},
      processing_config: %{
        batch_size: 10,
        limit: 100,
        enable_error_recovery: true,
        enable_progress_tracking: true
      },
      session_config: %{
        sync_type: :test_import,
        description: "Test import sync"
      }
    }
  end

  @doc """
  Creates test session data without database persistence
  """
  def test_session_data(attrs \\ %{}) do
    default_attrs = %{
      id: Ecto.UUID.generate(),
      sync_type: :test,
      description: "Test sync session",
      status: :pending,
      total_records: 100,
      processed_records: 0,
      failed_records: 0,
      config: %{},
      started_at: DateTime.utc_now(),
      metadata: %{}
    }

    Map.merge(default_attrs, attrs)
  end

  @doc """
  Creates test batch data
  """
  def test_batch_data(session_id, attrs \\ %{}) do
    default_attrs = %{
      id: Ecto.UUID.generate(),
      session_id: session_id,
      batch_number: 1,
      status: :pending,
      total_records: 10,
      processed_records: 0,
      failed_records: 0,
      started_at: DateTime.utc_now(),
      metadata: %{}
    }

    Map.merge(default_attrs, attrs)
  end
end