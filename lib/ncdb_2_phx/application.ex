defmodule NCDB2Phx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      NCDB2PhxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: NCDB2Phx.PubSub},
      # Start the Finch HTTP client for making external requests
      {Finch, name: NCDB2Phx.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NCDB2Phx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end