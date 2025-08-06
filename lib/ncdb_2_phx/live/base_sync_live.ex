defmodule NCDB2Phx.Live.BaseSyncLive do
  @moduledoc """
  Base LiveView for sync-related pages with common PubSub functionality and helpers.
  """

  defmacro __using__(opts) do
    quote do
      use Phoenix.LiveView, unquote(opts)
      
      # Import common components, excluding conflicting functions
      import NCDB2Phx.Components, except: [status_badge: 1, progress_bar: 1]

      @impl true
      def mount(params, session, socket) do
        socket = 
          socket
          |> assign_sync_defaults(params, session)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_progress")
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_sessions")
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_batches")
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_logs")
        end

        {:ok, socket}
      end

      @impl true
      def handle_info({:sync_progress, %{session_id: session_id} = data}, socket) do
        {:noreply, update_session_progress(socket, session_id, data)}
      end

      def handle_info({:sync_session, %{event: event, session: session}}, socket) do
        {:noreply, handle_session_event(socket, event, session)}
      end

      def handle_info({:sync_batch, %{event: event, batch: batch}}, socket) do
        {:noreply, handle_batch_event(socket, event, batch)}
      end

      def handle_info({:sync_log, %{level: level, message: message, session_id: session_id}}, socket) do
        {:noreply, handle_log_event(socket, level, message, session_id)}
      end

      # Default implementations (can be overridden)
      defp assign_sync_defaults(socket, _params, _session) do
        assign(socket,
          page_title: "Sync Administration",
          active_sessions: [],
          sync_stats: %{},
          system_health: %{}
        )
      end

      defp update_session_progress(socket, _session_id, _data), do: socket
      defp handle_session_event(socket, _event, _session), do: socket
      defp handle_batch_event(socket, _event, _batch), do: socket
      defp handle_log_event(socket, _level, _message, _session_id), do: socket

      defp pubsub_name do
        Application.get_env(:ncdb_2_phx, :pubsub_name, NCDB2Phx.PubSub)
      end

      defoverridable [
        mount: 3,
        assign_sync_defaults: 3,
        update_session_progress: 3,
        handle_session_event: 3,
        handle_batch_event: 3,
        handle_log_event: 4
      ]
    end
  end
end