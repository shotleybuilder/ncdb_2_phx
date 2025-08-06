defmodule NCDB2PhxTest do
  use ExUnit.Case
  doctest NCDB2Phx

  describe "module documentation" do
    test "module exists" do
      assert Code.ensure_loaded?(NCDB2Phx)
    end

    test "has expected functions" do
      assert function_exported?(NCDB2Phx, :sync, 1)
    end
  end

  describe "domain" do
    test "domain is defined" do
      assert NCDB2Phx.__ash_domain__()
    end
  end
end