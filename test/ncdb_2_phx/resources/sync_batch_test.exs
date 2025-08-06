defmodule NCDB2Phx.Resources.SyncBatchTest do
  use NCDB2Phx.DataCase, async: true

  alias NCDB2Phx.Resources.{SyncBatch, SyncSession}

  describe "sync batch resource" do
    setup do
      session = create_test_sync_session()
      {:ok, session: session}
    end

    test "can create a sync batch", %{session: session} do
      attrs = %{
        session_id: session.id,
        batch_number: 1,
        status: :pending,
        total_records: 10,
        processed_records: 0,
        failed_records: 0,
        started_at: DateTime.utc_now(),
        metadata: %{}
      }

      assert {:ok, batch} = 
        SyncBatch
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      assert batch.session_id == session.id
      assert batch.batch_number == 1
      assert batch.status == :pending
    end

    test "requires session_id", %{session: _session} do
      attrs = %{
        batch_number: 1,
        status: :pending
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        SyncBatch
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()
    end

    test "can read sync batches", %{session: session} do
      batch = create_test_sync_batch(session)
      
      assert {:ok, [found_batch]} = Ash.read(SyncBatch)
      assert found_batch.id == batch.id
      assert found_batch.session_id == session.id
    end
  end

  defp create_test_sync_session(attrs \\ %{}) do
    default_attrs = %{
      session_id: Ecto.UUID.generate(),
      sync_type: :test,
      description: "Test sync session",
      status: :pending,
      target_resource: "TestResource",
      source_adapter: "TestAdapter",
      total_records: 100,
      processed_records: 0,
      failed_records: 0,
      config: %{},
      started_at: DateTime.utc_now(),
      metadata: %{}
    }

    attrs = Map.merge(default_attrs, attrs)
    
    SyncSession
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!()
  end

  defp create_test_sync_batch(session, attrs \\ %{}) do
    default_attrs = %{
      session_id: session.id,
      batch_number: 1,
      status: :pending,
      total_records: 10,
      processed_records: 0,
      failed_records: 0,
      started_at: DateTime.utc_now(),
      metadata: %{}
    }

    attrs = Map.merge(default_attrs, attrs)
    
    SyncBatch
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!()
  end
end