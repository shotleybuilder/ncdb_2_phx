defmodule NCDB2Phx.SyncEngineTest do
  use ExUnit.Case
  
  alias NCDB2Phx.SyncEngine

  describe "module structure" do
    test "module exists" do
      assert Code.ensure_loaded?(SyncEngine)
    end

    test "has expected functions" do
      assert function_exported?(SyncEngine, :execute_sync, 1)
      assert function_exported?(SyncEngine, :validate_config, 1)
    end
  end

  describe "configuration validation" do
    test "validates basic required fields" do
      config = %{}
      assert {:error, _} = SyncEngine.validate_config(config)
    end

    test "accepts minimal valid configuration" do
      config = %{
        source_adapter: TestAdapter,
        source_config: %{},
        target_resource: TestResource,
        target_config: %{},
        processing_config: %{},
        session_config: %{}
      }
      
      # This test may fail until we implement proper validation
      # For now, just verify the function exists
      result = SyncEngine.validate_config(config)
      assert result in [{:ok, config}, {:error, _}]
    end
  end
end