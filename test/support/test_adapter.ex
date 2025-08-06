defmodule NCDB2Phx.TestAdapter do
  @moduledoc """
  Test adapter for sync engine testing.
  
  This adapter provides a simple in-memory data source for testing
  sync operations without external dependencies.
  """
  
  @behaviour NCDB2Phx.Utilities.SourceAdapter
  
  @impl true
  def initialize(config) do
    # Initialize the adapter with test data
    data = Map.get(config, :data, [])
    {:ok, %{data: data, position: 0}}
  end
  
  @impl true
  def stream_records(state) do
    # Return a stream of the test data - just use the list directly as it's enumerable
    state.data
  end
  
  @impl true
  def validate_connection(state) do
    # Simple validation - always pass for test adapter
    if is_map(state) and Map.has_key?(state, :data) do
      :ok
    else
      {:error, "Invalid test adapter state"}
    end
  end
  
  @impl true  
  def get_total_count(state) do
    {:ok, length(state.data)}
  end
  
  @impl true
  def cleanup(_state) do
    # No cleanup needed for in-memory adapter
    :ok
  end
end