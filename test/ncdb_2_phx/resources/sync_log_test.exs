defmodule NCDB2Phx.Resources.SyncLogTest do
  use NCDB2Phx.DataCase, async: true

  alias NCDB2Phx.Resources.{SyncLog, SyncSession}

  describe "sync log resource" do
    setup do
      session = create_test_sync_session()
      {:ok, session: session}
    end

    test "can create a sync log entry", %{session: session} do
      attrs = %{
        session_id: session.id,
        level: :info,
        message: "Test log message",
        event_type: :record_processed,
        data: %{component: "test"},
        context: %{key: "value"}
      }

      assert {:ok, log} = 
        SyncLog
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      assert log.session_id == session.id
      assert log.level == :info
      assert log.message == "Test log message"
      assert log.event_type == :record_processed
    end

    test "requires session_id and message", %{session: _session} do
      attrs = %{
        level: :info,
        event_type: :record_processed
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        SyncLog
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()
    end

    test "can read sync logs", %{session: session} do
      log = create_test_sync_log(session)
      
      assert {:ok, [found_log]} = Ash.read(SyncLog)
      assert found_log.id == log.id
      assert found_log.session_id == session.id
    end

    test "validates log level", %{session: session} do
      attrs = %{
        session_id: session.id,
        level: :invalid_level,
        message: "Test log message",
        component: "test"
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        SyncLog
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()
    end
  end

  defp create_test_sync_session(attrs \\ %{}) do
    default_attrs = %{
      session_id: Ecto.UUID.generate(),
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

  defp create_test_sync_log(session, attrs \\ %{}) do
    default_attrs = %{
      session_id: session.id,
      level: :info,
      message: "Test log message",
      event_type: :record_processed,
      data: %{component: "test"},
      context: %{test: true}
    }

    attrs = Map.merge(default_attrs, attrs)
    
    SyncLog
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!()
  end
end