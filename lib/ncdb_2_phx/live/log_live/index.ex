defmodule NCDB2Phx.Live.LogLive.Index do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket} = super(_params, _session, socket)

    socket =
      socket
      |> assign(:logs, list_logs())
      |> assign(:filters, %{level: :all, session: :all, search: "", date_range: :today})
      |> assign(:live_streaming, false)
      |> assign(:auto_scroll, true)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_filters(params)
      |> assign(:logs, list_logs_with_filters(socket.assigns.filters))

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = build_filters(filter_params)
    
    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:logs, list_logs_with_filters(filters))

    {:noreply, push_patch(socket, to: build_filter_path(filters))}
  end

  @impl true
  def handle_event("toggle_live_streaming", _params, socket) do
    live_streaming = !socket.assigns.live_streaming
    
    socket = assign(socket, :live_streaming, live_streaming)
    
    if live_streaming do
      subscribe_to_live_logs()
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_auto_scroll", _params, socket) do
    {:noreply, assign(socket, :auto_scroll, !socket.assigns.auto_scroll)}
  end

  @impl true
  def handle_event("clear_logs", _params, socket) do
    case clear_logs(socket.assigns.filters) do
      {:ok, _result} ->
        socket =
          socket
          |> assign(:logs, list_logs_with_filters(socket.assigns.filters))
          |> put_flash(:info, "Logs cleared successfully")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to clear logs: #{reason}")}
    end
  end

  @impl true
  def handle_event("export_logs", _params, socket) do
    # TODO: Implement log export
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  @impl true
  def handle_info({:sync_log, log}, socket) do
    if socket.assigns.live_streaming and matches_filters?(log, socket.assigns.filters) do
      logs = [log | Enum.take(socket.assigns.logs, 499)]  # Keep latest 500 logs
      {:noreply, assign(socket, :logs, logs)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="log-viewer" class="log-index" phx-hook="LogViewer" data-auto-scroll={@auto_scroll}>
      <.page_header />
      
      <.log_controls 
        filters={@filters} 
        live_streaming={@live_streaming} 
        auto_scroll={@auto_scroll} 
      />
      
      <.logs_display logs={@logs} live_streaming={@live_streaming} />
    </div>
    """
  end

  defp list_logs do
    # TODO: Load from NCDB2Phx.Resources.SyncLog
    []
  end

  defp list_logs_with_filters(_filters) do
    # TODO: Implement filtering logic
    []
  end

  defp apply_filters(socket, params) do
    filters = %{
      level: atomize_param(params["level"], :all),
      session: params["session"] || :all,
      search: params["search"] || "",
      date_range: atomize_param(params["date_range"], :today)
    }
    assign(socket, :filters, filters)
  end

  defp build_filters(params) do
    %{
      level: atomize_param(params["level"], :all),
      session: params["session"] || :all,
      search: params["search"] || "",
      date_range: atomize_param(params["date_range"], :today)
    }
  end

  defp atomize_param(value, default) when is_binary(value), do: String.to_atom(value)
  defp atomize_param(_value, default), do: default

  defp build_filter_path(filters) do
    query_params = 
      filters
      |> Enum.reject(fn {k, v} -> v in [:all, "", :today] or (k == :search and v == "") end)
      |> Enum.into(%{})

    if query_params == %{} do
      "/logs"
    else
      "/logs?" <> URI.encode_query(query_params)
    end
  end

  defp subscribe_to_live_logs do
    # TODO: Subscribe to real-time log events
    Phoenix.PubSub.subscribe(NCDB2Phx.PubSub, "sync_logs")
  end

  defp matches_filters?(_log, _filters) do
    # TODO: Implement filter matching logic
    true
  end

  defp clear_logs(_filters) do
    # TODO: Implement log clearing
    {:error, "Not implemented"}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <h1>Sync Logs</h1>
      <p class="page-description">
        View and search through comprehensive sync operation logs
      </p>
    </div>
    """
  end

  defp log_controls(assigns) do
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
            <label>Session:</label>
            <select name="filter[session]">
              <option value="all" selected={@filters.session == :all}>All Sessions</option>
              <!-- TODO: Populate with actual sessions -->
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
          
          <div class="filter-group">
            <label>Date:</label>
            <select name="filter[date_range]">
              <option value="today" selected={@filters.date_range == :today}>Today</option>
              <option value="yesterday" selected={@filters.date_range == :yesterday}>Yesterday</option>
              <option value="week" selected={@filters.date_range == :week}>This Week</option>
              <option value="month" selected={@filters.date_range == :month}>This Month</option>
              <option value="all" selected={@filters.date_range == :all}>All Time</option>
            </select>
          </div>
        </form>
      </div>
      
      <div class="log-actions">
        <label class="toggle-control">
          <input 
            type="checkbox" 
            phx-click="toggle_live_streaming" 
            checked={@live_streaming}
          />
          Live Streaming
          <%= if @live_streaming do %>
            <span class="live-indicator">LIVE</span>
          <% end %>
        </label>
        
        <label class="toggle-control">
          <input 
            type="checkbox" 
            phx-click="toggle_auto_scroll" 
            checked={@auto_scroll}
          />
          Auto Scroll
        </label>
        
        <button class="btn btn-outline" phx-click="export_logs">
          Export
        </button>
        
        <button class="btn btn-warning" phx-click="clear_logs" data-confirm="Are you sure you want to clear the filtered logs?">
          Clear Logs
        </button>
      </div>
    </div>
    """
  end

  defp logs_display(assigns) do
    ~H"""
    <div class={"logs-container #{if @live_streaming, do: "live-streaming", else: ""}"}>
      <%= if @logs == [] do %>
        <div class="empty-state">
          <p>No logs found matching your criteria.</p>
          <%= if @live_streaming do %>
            <p>Waiting for new log entries...</p>
          <% end %>
        </div>
      <% else %>
        <div class="logs-list" id="logs-list">
          <%= for log <- @logs do %>
            <.log_entry log={log} />
          <% end %>
        </div>
        
        <div class="logs-pagination">
          <button class="btn btn-outline">Load More</button>
        </div>
      <% end %>
    </div>
    """
  end

  defp log_entry(assigns) do
    log_class = "log-entry log-#{assigns.log.level}"
    assigns = assign(assigns, :log_class, log_class)

    ~H"""
    <div class={@log_class} data-log-id={@log.id}>
      <div class="log-header">
        <span class="log-timestamp"><%= format_timestamp(@log.timestamp) %></span>
        <.log_level_badge level={@log.level} />
        <%= if @log.session_id do %>
          <.link navigate={"/sync/sessions/#{@log.session_id}"} class="log-session-link">
            Session <%= @log.session_id %>
          </.link>
        <% end %>
        <%= if @log.batch_id do %>
          <.link navigate={"/sync/batches/#{@log.batch_id}"} class="log-batch-link">
            Batch #<%= @log.batch_number %>
          </.link>
        <% end %>
      </div>
      
      <div class="log-message">
        <%= @log.message %>
      </div>
      
      <%= if @log.context do %>
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

  defp format_timestamp(timestamp) do
    # TODO: Implement proper timestamp formatting
    to_string(timestamp)
  end
end