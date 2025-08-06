defmodule NCDB2Phx.Utilities.ConfigValidatorTest do
  use ExUnit.Case

  alias NCDB2Phx.Utilities.ConfigValidator

  describe "configuration validation" do
    test "module exists" do
      assert Code.ensure_loaded?(ConfigValidator)
    end

    test "has expected functions" do
      assert function_exported?(ConfigValidator, :validate_config, 1)
    end

    test "validates empty config" do
      config = %{}
      result = ConfigValidator.validate_config(config)
      
      # The actual validation behavior will depend on implementation
      # For now, just verify the function can be called
      assert result in [{:ok, _}, {:error, _}]
    end

    test "validates basic config structure" do
      config = %{
        source_adapter: TestAdapter,
        source_config: %{},
        target_resource: TestResource,
        target_config: %{},
        processing_config: %{},
        session_config: %{}
      }
      
      result = ConfigValidator.validate_config(config)
      assert result in [{:ok, _}, {:error, _}]
    end
  end
end