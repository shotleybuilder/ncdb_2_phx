defmodule NCDB2Phx.Live.Hooks.AssignDefaults do
  @moduledoc """
  LiveView mount hook for assigning sync-related defaults to socket.
  """

  def on_mount(session_args, _params, session, socket) when is_map(session_args) do
    socket =
      socket
      |> Phoenix.LiveView.assign(:sync_session_args, session_args)
      |> Phoenix.LiveView.assign(:pubsub_name, get_pubsub_name())
      |> Phoenix.LiveView.assign(:current_user, get_current_user(session))
      |> Phoenix.LiveView.assign(:sync_permissions, get_sync_permissions(session))

    {:cont, socket}
  end

  def on_mount(_session_args, _params, session, socket) do
    socket =
      socket
      |> Phoenix.LiveView.assign(:sync_session_args, %{})
      |> Phoenix.LiveView.assign(:pubsub_name, get_pubsub_name())
      |> Phoenix.LiveView.assign(:current_user, get_current_user(session))
      |> Phoenix.LiveView.assign(:sync_permissions, get_sync_permissions(session))

    {:cont, socket}
  end

  defp get_pubsub_name do
    config = Application.get_env(:ncdb_2_phx, NCDB2Phx.Router, [])
    Keyword.get(config, :pubsub_name, NCDB2Phx.PubSub)
  end

  defp get_current_user(session), do: Map.get(session, "current_user")
  defp get_sync_permissions(session), do: Map.get(session, "sync_permissions", [])
end