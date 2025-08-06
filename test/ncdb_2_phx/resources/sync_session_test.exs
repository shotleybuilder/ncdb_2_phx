defmodule NCDB2Phx.Resources.SyncSessionTest do
  use NCDB2Phx.DataCase, async: true

  alias NCDB2Phx.Resources.SyncSession

  describe "sync session resource" do
    test "creates a sync session with valid attributes" do
      attrs = %{
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

      assert {:ok, session} = 
        SyncSession
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      assert session.sync_type == :test
      assert session.description == "Test sync session"
      assert session.status == :pending
      assert session.total_records == 100
    end

    test "validates required fields" do
      attrs = %{}

      assert {:error, %Ash.Error.Invalid{} = error} = 
        SyncSession
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()
      
      # Check that required field errors are present
      assert Enum.any?(error.errors, fn err -> 
        err.field == :session_id and err.__struct__ == Ash.Error.Changes.Required
      end)
      assert Enum.any?(error.errors, fn err -> 
        err.field == :sync_type and err.__struct__ == Ash.Error.Changes.Required
      end)
    end

    test "can read sync sessions" do
      session = create_test_sync_session()
      
      assert {:ok, [found_session]} = Ash.read(SyncSession)
      assert found_session.id == session.id
    end

    test "creates session with create_session action" do
      attrs = %{
        session_id: Ecto.UUID.generate(),
        sync_type: :test_import,
        description: "Test import session",
        target_resource: "TestResource",
        source_adapter: "TestAdapter"
      }

      assert {:ok, session} = 
        SyncSession
        |> Ash.Changeset.for_create(:create_session, attrs)
        |> Ash.create()

      assert session.sync_type == :test_import
      assert session.status == :pending
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
end