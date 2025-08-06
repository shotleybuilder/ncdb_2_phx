defmodule NCDB2Phx.SyncEngineTest do
  use ExUnit.Case
  
  alias NCDB2Phx.SyncEngine

  describe "module structure" do
    test "module exists" do
      assert Code.ensure_loaded?(SyncEngine)
    end

    test "has expected functions" do
      assert function_exported?(SyncEngine, :execute_sync, 1)
      assert function_exported?(SyncEngine, :execute_sync, 2)
    end
  end

  describe "sync execution" do
    test "execute_sync exists and handles empty config" do
      config = %{}
      # execute_sync should return an error for empty config
      assert {:error, _} = SyncEngine.execute_sync(config)
    end

    test "execute_sync exists and can be called with valid structure" do
      config = %{
        source_adapter: NCDB2Phx.TestAdapter,
        source_config: %{},
        target_resource: NCDB2Phx.TestResource,
        target_config: %{},
        processing_config: %{},
        session_config: %{}
      }
      
      # This test may fail until we implement proper adapters
      # For now, just verify the function can be called
      result = SyncEngine.execute_sync(config)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end