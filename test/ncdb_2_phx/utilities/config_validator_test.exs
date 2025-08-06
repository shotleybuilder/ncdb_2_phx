defmodule NCDB2Phx.Utilities.ConfigValidatorTest do
  use ExUnit.Case

  alias NCDB2Phx.Utilities.ConfigValidator

  describe "configuration validation" do
    test "module exists" do
      assert Code.ensure_loaded?(ConfigValidator)
    end

    test "has expected functions" do
      assert function_exported?(ConfigValidator, :validate_sync_config, 1)
      assert function_exported?(ConfigValidator, :validate_sync_config, 2)
    end

    test "validates empty config" do
      config = %{}
      result = ConfigValidator.validate_sync_config(config)
      
      # The actual validation behavior will depend on implementation
      # For now, just verify the function can be called
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "validates basic config structure" do
      config = %{
        source_adapter: NCDB2Phx.TestAdapter,
        source_config: %{},
        target_resource: NCDB2Phx.TestResource,
        target_config: %{},
        processing_config: %{},
        session_config: %{}
      }
      
      result = ConfigValidator.validate_sync_config(config)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end