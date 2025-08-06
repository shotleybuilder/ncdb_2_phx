defmodule NCDB2Phx.Application do
  @moduledoc """
  Optional supervision tree for NCDB2Phx library components.
  
  Host applications can include this supervisor in their application tree:
  
      children = [
        # Other children...
        NCDB2Phx.Application
      ]
  
  Or start individual components as needed:
  
      children = [
        {Phoenix.PubSub, name: NCDB2Phx.PubSub},
        {Finch, name: NCDB2Phx.Finch}
      ]
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Database repository (for development/testing)
      NCDB2Phx.Repo,
      # PubSub system for real-time progress tracking
      {Phoenix.PubSub, name: NCDB2Phx.PubSub},
      # HTTP client for external API requests
      {Finch, name: NCDB2Phx.Finch}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end