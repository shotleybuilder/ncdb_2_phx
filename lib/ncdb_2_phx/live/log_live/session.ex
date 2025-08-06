defmodule NCDB2Phx.Live.LogLive.Session do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(%{"session_id" => session_id}, session, socket) do
    {:ok, socket} = super(%{"session_id" => session_id}, session, socket)

    {:ok, session} = load_session(session_id)
    socket =
      socket
      |> assign(:session, session)
      |> assign(:logs, list_session_logs(session_id))
      |> assign(:filters, %{level: :all, search: ""})
      |> assign(:timeline_view, false)
      |> assign(:live_streaming, false)
      |> assign(:log_stats, calculate_log_statistics(session_id))

    {:ok, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = build_filters(filter_params)
    
    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:logs, filter_session_logs(socket.assigns.session.id, filters))

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_timeline_view", _params, socket) do
    {:noreply, assign(socket, :timeline_view, !socket.assigns.timeline_view)}
  end

  @impl true
  def handle_event("toggle_live_streaming", _params, socket) do
    live_streaming = !socket.assigns.live_streaming
    
    socket = assign(socket, :live_streaming, live_streaming)
    
    if live_streaming do
      subscribe_to_session_logs(socket.assigns.session.id)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("export_session_logs", _params, socket) do
    # TODO: Implement session log export
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  @impl true
  def handle_event("clear_session_logs", _params, socket) do
    {:error, reason} = clear_session_logs(socket.assigns.session.id)
    {:noreply, put_flash(socket, :error, "Failed to clear logs: #{reason}")}
  end

  @impl true
  def handle_info({:sync_log, %{session_id: session_id} = log}, socket) do
    if socket.assigns.live_streaming and session_id == socket.assigns.session.id do
      if matches_session_filters?(log, socket.assigns.filters) do
        logs = [log | Enum.take(socket.assigns.logs, 499)]
        socket =
          socket
          |> assign(:logs, logs)
          |> update(:log_stats, &update_log_stats(&1, log))

        {:noreply, socket}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="session-logs">
      <.page_header session={@session} />
      
      <.session_log_stats stats={@log_stats} />
      
      <.session_log_controls 
        filters={@filters} 
        timeline_view={@timeline_view}
        live_streaming={@live_streaming}
      />
      
      <%= if @timeline_view do %>
        <.timeline_view logs={@logs} session={@session} />
      <% else %>
        <.standard_logs_view logs={@logs} />
      <% end %>
    </div>
    """
  end

  defp load_session(id) do
    # TODO: Load from NCDB2Phx.Resources.SyncSession
    {:ok, %{
      id: id,
      name: "Session Logs",
      status: :completed,
      inserted_at: DateTime.utc_now()
    }}
  end

  defp list_session_logs(_session_id) do
    # TODO: Load logs from NCDB2Phx.Resources.SyncLog
    []
  end

  defp filter_session_logs(_session_id, _filters) do
    # TODO: Filter logs based on criteria
    []
  end

  defp calculate_log_statistics(_session_id) do
    # TODO: Calculate log statistics
    %{
      total_logs: 0,
      debug_count: 0,
      info_count: 0,
      warn_count: 0,
      error_count: 0,
      first_log_time: nil,
      last_log_time: nil
    }
  end

  defp build_filters(params) do
    %{
      level: atomize_param(params["level"], :all),
      search: params["search"] || ""
    }
  end

  defp atomize_param(value, _default) when is_binary(value), do: String.to_atom(value)
  defp atomize_param(_value, default), do: default

  defp subscribe_to_session_logs(_session_id) do
    # TODO: Subscribe to session-specific logs
    Phoenix.PubSub.subscribe(NCDB2Phx.PubSub, "sync_logs")
  end

  defp matches_session_filters?(_log, _filters) do
    # TODO: Implement session-specific filter matching
    true
  end

  defp clear_session_logs(_session_id) do
    # TODO: Clear logs for specific session
    {:error, "Not implemented"}
  end

  defp update_log_stats(stats, log) do
    level_key = :"#{log.level}_count"
    
    stats
    |> Map.update(:total_logs, 1, &(&1 + 1))
    |> Map.update(level_key, 1, &(&1 + 1))
    |> Map.put(:last_log_time, log.timestamp)
    |> Map.update(:first_log_time, log.timestamp, fn current ->
      if is_nil(current) or DateTime.compare(log.timestamp, current) == :lt do
        log.timestamp
      else
        current
      end
    end)
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <div class="header-left">
        <h1>Session Logs</h1>
        <nav class="breadcrumb">
          <.link navigate="/sync/logs">Logs</.link>
          <span>/</span>
          <.link navigate={"/sync/sessions/#{@session.id}"}><%= @session.name || "Session #{@session.id}" %></.link>
        </nav>
      </div>
    </div>
    """
  end

  defp session_log_stats(assigns) do
    ~H"""
    <div class="log-stats-section">
      <div class="stats-grid">
        <.stat_card title="Total Logs" value={@stats.total_logs} type="total" />
        <.stat_card title="Errors" value={@stats.error_count} type="error" />
        <.stat_card title="Warnings" value={@stats.warn_count} type="warning" />
        <.stat_card title="Info" value={@stats.info_count} type="info" />
        <.stat_card title="Debug" value={@stats.debug_count} type="debug" />
        
        <div class="stat-card time-range">
          <h4>Log Time Range</h4>
          <%= if @stats.first_log_time do %>
            <div class="time-range-content">
              <div class="time-start">
                <label>First:</label>
                <span><%= format_datetime(@stats.first_log_time) %></span>
              </div>
              <div class="time-end">
                <label>Last:</label>
                <span><%= format_datetime(@stats.last_log_time) %></span>
              </div>
            </div>
          <% else %>
            <p class="no-logs">No logs recorded</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp session_log_controls(assigns) do
    ~H"""
    <div class="log-controls">
      <div class="log-filters">
        <form phx-change="filter" class="filter-form">
          <div class="filter-group">
            <label>Level:</label>
            <select name="filter[level]">
              <option value="all" selected={@filters.level == :all}>All</option>
              <option value="debug" selected={@filters.level == :debug}>Debug</option>
              <option value="info" selected={@filters.level == :info}>Info</option>
              <option value="warn" selected={@filters.level == :warn}>Warning</option>
              <option value="error" selected={@filters.level == :error}>Error</option>
            </select>
          </div>
          
          <div class="filter-group">
            <label>Search:</label>
            <input 
              type="text" 
              name="filter[search]" 
              value={@filters.search} 
              placeholder="Search in messages..."
            />
          </div>
        </form>
      </div>
      
      <div class="view-controls">
        <label class="toggle-control">
          <input 
            type="checkbox" 
            phx-click="toggle_timeline_view" 
            checked={@timeline_view}
          />
          Timeline View
        </label>
        
        <label class="toggle-control">
          <input 
            type="checkbox" 
            phx-click="toggle_live_streaming" 
            checked={@live_streaming}
          />
          Live Updates
          <%= if @live_streaming do %>
            <span class="live-indicator">LIVE</span>
          <% end %>
        </label>
      </div>
      
      <div class="log-actions">
        <button class="btn btn-outline" phx-click="export_session_logs">
          Export Session Logs
        </button>
        
        <button class="btn btn-warning" phx-click="clear_session_logs" data-confirm="Clear all logs for this session?">
          Clear Session Logs
        </button>
      </div>
    </div>
    """
  end

  defp timeline_view(assigns) do
    ~H"""
    <div class="timeline-container">
      <div class="session-timeline">
        <div class="timeline-header">
          <h3>Session Timeline</h3>
          <p>Chronological view of session events and logs</p>
        </div>
        
        <%= if @logs == [] do %>
          <div class="empty-timeline">
            <p>No logs to display in timeline</p>
          </div>
        <% else %>
          <div class="timeline">
            <%= for log <- group_logs_by_time(@logs) do %>
              <.timeline_group logs={log.logs} timestamp={log.timestamp} />
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp standard_logs_view(assigns) do
    ~H"""
    <div class="logs-container">
      <%= if @logs == [] do %>
        <div class="empty-state">
          <p>No logs found for this session.</p>
        </div>
      <% else %>
        <div class="logs-list">
          <%= for log <- @logs do %>
            <.session_log_entry log={log} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp timeline_group(assigns) do
    ~H"""
    <div class="timeline-group">
      <div class="timeline-timestamp">
        <%= format_datetime(@timestamp) %>
      </div>
      <div class="timeline-logs">
        <%= for log <- @logs do %>
          <.timeline_log_entry log={log} />
        <% end %>
      </div>
    </div>
    """
  end

  defp timeline_log_entry(assigns) do
    ~H"""
    <div class={"timeline-log-entry timeline-#{@log.level}"}>
      <div class="timeline-marker"></div>
      <div class="timeline-content">
        <div class="timeline-log-header">
          <.log_level_badge level={@log.level} />
          <%= if @log.batch_id do %>
            <span class="timeline-batch">Batch #<%= @log.batch_number %></span>
          <% end %>
        </div>
        <div class="timeline-message">
          <%= @log.message %>
        </div>
      </div>
    </div>
    """
  end

  defp session_log_entry(assigns) do
    ~H"""
    <div class={"log-entry log-#{@log.level}"}>
      <div class="log-header">
        <span class="log-timestamp"><%= format_datetime(@log.timestamp) %></span>
        <.log_level_badge level={@log.level} />
        <%= if @log.batch_id do %>
          <.link navigate={"/sync/batches/#{@log.batch_id}"} class="log-batch-link">
            Batch #<%= @log.batch_number %>
          </.link>
        <% end %>
      </div>
      
      <div class="log-message">
        <%= @log.message %>
      </div>
      
      <%= if @log.context and @log.context != %{} do %>
        <.log_context context={@log.context} />
      <% end %>
      
      <%= if @log.stack_trace do %>
        <details class="log-stack-trace">
          <summary>Stack Trace</summary>
          <pre><%= @log.stack_trace %></pre>
        </details>
      <% end %>
    </div>
    """
  end

  defp stat_card(assigns) do
    card_class = case assigns.type do
      "error" -> "stat-card error"
      "warning" -> "stat-card warning"
      "info" -> "stat-card info"
      "debug" -> "stat-card debug"
      _ -> "stat-card"
    end

    assigns = assign(assigns, :card_class, card_class)

    ~H"""
    <div class={@card_class}>
      <h4><%= @title %></h4>
      <div class="stat-value"><%= @value %></div>
    </div>
    """
  end

  defp log_level_badge(assigns) do
    badge_class = case assigns.level do
      :debug -> "log-level-badge debug"
      :info -> "log-level-badge info"
      :warn -> "log-level-badge warn"
      :error -> "log-level-badge error"
      _ -> "log-level-badge"
    end

    assigns = assign(assigns, :badge_class, badge_class)

    ~H"""
    <span class={@badge_class}><%= String.upcase(to_string(@level)) %></span>
    """
  end

  defp log_context(assigns) do
    ~H"""
    <details class="log-context">
      <summary>Context</summary>
      <div class="log-context-content">
        <%= for {key, value} <- @context do %>
          <div class="context-item">
            <strong><%= key %>:</strong> <%= inspect(value) %>
          </div>
        <% end %>
      </div>
    </details>
    """
  end

  defp group_logs_by_time(logs) do
    # TODO: Group logs by time intervals (e.g., by minute or hour)
    logs
    |> Enum.group_by(fn log -> 
      # Group by minute for now
      DateTime.truncate(log.timestamp, :minute)
    end)
    |> Enum.map(fn {timestamp, logs} ->
      %{timestamp: timestamp, logs: Enum.sort_by(logs, & &1.timestamp)}
    end)
    |> Enum.sort_by(& &1.timestamp, DateTime)
  end

  defp format_datetime(datetime) do
    # TODO: Implement proper datetime formatting
    to_string(datetime)
  end
end