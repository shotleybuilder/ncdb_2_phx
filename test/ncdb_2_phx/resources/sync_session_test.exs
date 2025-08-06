defmodule NCDB2Phx.Resources.SyncSessionTest do
  use NCDB2Phx.DataCase, async: true

  alias NCDB2Phx.Resources.SyncSession

  describe "sync session resource" do
    test "creates a sync session with valid attributes" do
      attrs = %{
        session_id: Ecto.UUID.generate(),
        sync_type: :import_airtable,
        target_resource: "TestResource",
        source_adapter: "TestAdapter",
        config: %{},
        metadata: %{description: "Test sync session"},
        estimated_total: 100
      }

      assert {:ok, session} = 
        SyncSession
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      assert session.sync_type == :import_airtable
      assert session.metadata["description"] == "Test sync session"
      assert session.status == :pending
      assert session.estimated_total == 100
    end

    test "validates required fields" do
      attrs = %{}

      assert {:error, %Ash.Error.Invalid{} = error} = 
        SyncSession
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()
      
      # Check that required field errors are present
      assert Enum.any?(error.errors, fn err -> 
        :session_id in Map.get(err, :fields, []) and err.__struct__ == Ash.Error.Changes.InvalidChanges
      end)
      assert Enum.any?(error.errors, fn err -> 
        :sync_type in Map.get(err, :fields, []) and err.__struct__ == Ash.Error.Changes.InvalidChanges
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
        sync_type: :import_airtable,
        target_resource: "TestResource",
        source_adapter: "TestAdapter",
        metadata: %{description: "Test import session"}
      }

      assert {:ok, session} = 
        SyncSession
        |> Ash.Changeset.for_create(:create_session, attrs)
        |> Ash.create()

      assert session.sync_type == :import_airtable
      assert session.status == :pending
    end
  end

  defp create_test_sync_session(attrs \\ %{}) do
    default_attrs = %{
      session_id: Ecto.UUID.generate(),
      sync_type: :import_airtable,
      target_resource: "TestResource",
      source_adapter: "TestAdapter",
      config: %{},
      metadata: %{description: "Test sync session"},
      estimated_total: 100
    }

    attrs = Map.merge(default_attrs, attrs)
    
    SyncSession
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!()
  end
end