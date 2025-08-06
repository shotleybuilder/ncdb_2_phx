defmodule NCDB2PhxTest do
  use ExUnit.Case
  doctest NCDB2Phx

  describe "module documentation" do
    test "module exists" do
      assert Code.ensure_loaded?(NCDB2Phx)
    end

    test "has expected functions" do
      assert function_exported?(NCDB2Phx, :execute_sync, 1)
      assert function_exported?(NCDB2Phx, :execute_sync, 2)
    end
  end

  describe "domain" do
    test "domain has resources configured" do
      # Test that the domain is properly configured with resources using Ash.Domain.Info
      resources = Ash.Domain.Info.resources(NCDB2Phx)
      
      assert length(resources) == 3
      assert NCDB2Phx.Resources.SyncSession in resources
      assert NCDB2Phx.Resources.SyncBatch in resources
      assert NCDB2Phx.Resources.SyncLog in resources
    end
    
    test "domain can access individual resources" do
      # Test that each resource is properly registered with the domain
      assert Ash.Domain.Info.resource(NCDB2Phx, NCDB2Phx.Resources.SyncSession)
      assert Ash.Domain.Info.resource(NCDB2Phx, NCDB2Phx.Resources.SyncBatch)
      assert Ash.Domain.Info.resource(NCDB2Phx, NCDB2Phx.Resources.SyncLog)
    end
    
    test "domain is properly configured as Ash domain" do
      # Test that the module is properly configured as an Ash domain
      assert function_exported?(NCDB2Phx, :spark_dsl_config, 0)
      
      # Test domain properties
      assert is_atom(Ash.Domain.Info.short_name(NCDB2Phx))
    end
  end
end