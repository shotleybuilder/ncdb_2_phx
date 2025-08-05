defmodule AirtableSyncPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AirtableSyncPhoenixWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AirtableSyncPhoenix.PubSub},
      # Start the Finch HTTP client for making external requests
      {Finch, name: AirtableSyncPhoenix.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AirtableSyncPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end