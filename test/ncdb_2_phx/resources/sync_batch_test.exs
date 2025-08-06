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
        batch_size: 10,
        source_ids: ["rec1", "rec2", "rec3"],
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
      session_id: "test_session_" <> String.replace(Ecto.UUID.generate(), "-", "_"),
      sync_type: :custom_sync,
      target_resource: "TestResource",
      source_adapter: "TestAdapter",
      estimated_total: 100,
      config: %{},
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
      batch_size: 10,
      source_ids: ["rec1", "rec2", "rec3"],
      metadata: %{}
    }

    attrs = Map.merge(default_attrs, attrs)
    
    SyncBatch
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!()
  end
end