defmodule NCDB2Phx.Live.SessionLive.Show do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {:ok, socket} = super(%{"id" => id}, session, socket)

    {:ok, session} = load_session(id)
    socket =
      socket
      |> assign(:session, session)
      |> assign(:batches, load_session_batches(id))
      |> assign(:logs, load_session_logs(id))
      |> assign(:performance_metrics, calculate_performance_metrics(session))

    {:ok, socket}
  end

  @impl true
  def handle_event("cancel_session", _params, socket) do
    {:error, reason} = cancel_session(socket.assigns.session.id)
    {:noreply, put_flash(socket, :error, "Failed to cancel session: #{reason}")}
  end

  @impl true
  def handle_event("retry_session", _params, socket) do
    {:error, reason} = retry_session(socket.assigns.session.id)
    {:noreply, put_flash(socket, :error, "Failed to retry session: #{reason}")}
  end

  @impl true
  def handle_event("export_report", _params, socket) do
    # TODO: Implement session report export
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="session-show">
      <.page_header session={@session} />
      
      <div class="session-details-grid">
        <.session_overview session={@session} />
        <.session_progress session={@session} />
        <.performance_metrics metrics={@performance_metrics} />
      </div>
      
      <.session_batches batches={@batches} />
      
      <.session_logs logs={@logs} />
    </div>
    """
  end

  defp load_session(id) do
    # TODO: Load from NCDB2Phx.Resources.SyncSession
    {:ok, %{
      id: id,
      name: "Test Session",
      status: :running,
      progress: 65,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      config: %{}
    }}
  end

  defp load_session_batches(_id) do
    # TODO: Load from NCDB2Phx.Resources.SyncBatch
    []
  end

  defp load_session_logs(_id) do
    # TODO: Load from NCDB2Phx.Resources.SyncLog
    []
  end

  defp calculate_performance_metrics(_session) do
    # TODO: Calculate from batches and logs
    %{
      avg_records_per_second: 150,
      total_processing_time: 300,
      error_rate: 0.02,
      memory_usage: 45.6
    }
  end

  defp cancel_session(_id) do
    # TODO: Implement session cancellation
    {:error, "Not implemented"}
  end

  defp retry_session(_id) do
    # TODO: Implement session retry
    {:error, "Not implemented"}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <div class="header-left">
        <h1>Session Details</h1>
        <nav class="breadcrumb">
          <.link navigate="/sync/sessions">Sessions</.link>
          <span>/</span>
          <span><%= @session.name || "Session #{@session.id}" %></span>
        </nav>
      </div>
      
      <div class="header-actions">
        <%= if @session.status == :running do %>
          <button class="btn btn-warning" phx-click="cancel_session">
            Cancel Session
          </button>
        <% end %>
        
        <%= if @session.status in [:failed, :cancelled] do %>
          <button class="btn btn-primary" phx-click="retry_session">
            Retry Session
          </button>
        <% end %>
        
        <.link navigate={"/sync/sessions/#{@session.id}/edit"} class="btn btn-outline">
          Edit
        </.link>
        
        <button class="btn btn-outline" phx-click="export_report">
          Export Report
        </button>
      </div>
    </div>
    """
  end

  defp session_overview(assigns) do
    ~H"""
    <div class="session-card">
      <h3>Session Overview</h3>
      <div class="session-meta">
        <div class="meta-item">
          <label>Status:</label>
          <.status_badge status={@session.status} />
        </div>
        
        <div class="meta-item">
          <label>Started:</label>
          <span><%= format_datetime(@session.inserted_at) %></span>
        </div>
        
        <div class="meta-item">
          <label>Last Updated:</label>
          <span><%= format_datetime(@session.updated_at) %></span>
        </div>
        
        <div class="meta-item">
          <label>Duration:</label>
          <span><%= calculate_duration(@session) %></span>
        </div>
        
        <div class="meta-item">
          <label>Session ID:</label>
          <span class="session-id"><%= @session.id %></span>
        </div>
      </div>
      
      <div class="session-config">
        <h4>Configuration</h4>
        <pre><%= inspect(@session.config, pretty: true) %></pre>
      </div>
    </div>
    """
  end

  defp session_progress(assigns) do
    ~H"""
    <div class="session-card">
      <h3>Progress</h3>
      <div class="progress-display">
        <.progress_bar progress={@session.progress || 0} size="large" />
        <div class="progress-stats">
          <div class="stat">
            <span class="stat-label">Records Processed:</span>
            <span class="stat-value">1,250 / 2,000</span>
          </div>
          <div class="stat">
            <span class="stat-label">Success Rate:</span>
            <span class="stat-value">98.5%</span>
          </div>
          <div class="stat">
            <span class="stat-label">Estimated Time Remaining:</span>
            <span class="stat-value">5 minutes</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp performance_metrics(assigns) do
    ~H"""
    <div class="session-card">
      <h3>Performance Metrics</h3>
      <div class="metrics-grid">
        <div class="metric">
          <div class="metric-value"><%= @metrics.avg_records_per_second %></div>
          <div class="metric-label">Records/sec</div>
        </div>
        
        <div class="metric">
          <div class="metric-value"><%= @metrics.total_processing_time %>s</div>
          <div class="metric-label">Processing Time</div>
        </div>
        
        <div class="metric">
          <div class="metric-value"><%= Float.round(@metrics.error_rate * 100, 1) %>%</div>
          <div class="metric-label">Error Rate</div>
        </div>
        
        <div class="metric">
          <div class="metric-value"><%= @metrics.memory_usage %>MB</div>
          <div class="metric-label">Memory Usage</div>
        </div>
      </div>
    </div>
    """
  end

  defp session_batches(assigns) do
    ~H"""
    <div class="section">
      <h2>Batches</h2>
      <%= if @batches == [] do %>
        <div class="empty-state">
          <p>No batches have been processed yet.</p>
        </div>
      <% else %>
        <div class="batches-table">
          <table class="table">
            <thead>
              <tr>
                <th>Batch</th>
                <th>Status</th>
                <th>Records</th>
                <th>Success Rate</th>
                <th>Duration</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for batch <- @batches do %>
                <tr>
                  <td>#<%= batch.batch_number %></td>
                  <td><.status_badge status={batch.status} /></td>
                  <td><%= batch.record_count %></td>
                  <td><%= batch.success_rate %>%</td>
                  <td><%= batch.duration %>s</td>
                  <td>
                    <.link navigate={"/sync/batches/#{batch.id}"} class="btn btn-sm">
                      View Details
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp session_logs(assigns) do
    ~H"""
    <div class="section">
      <h2>Recent Logs</h2>
      <%= if @logs == [] do %>
        <div class="empty-state">
          <p>No logs available for this session.</p>
        </div>
      <% else %>
        <div class="logs-container">
          <%= for log <- @logs do %>
            <div class={"log-entry log-#{log.level}"}>
              <span class="log-timestamp"><%= format_datetime(log.timestamp) %></span>
              <span class="log-level"><%= log.level %></span>
              <span class="log-message"><%= log.message %></span>
            </div>
          <% end %>
        </div>
      <% end %>
      
      <div class="logs-actions">
        <.link navigate={"/sync/logs/#{@session.id}"} class="btn btn-outline">
          View All Logs
        </.link>
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    class = case assigns.status do
      :pending -> "badge badge-secondary"
      :running -> "badge badge-primary"
      :completed -> "badge badge-success"
      :failed -> "badge badge-error"
      :cancelled -> "badge badge-warning"
      _ -> "badge"
    end

    assigns = assign(assigns, :class, class)

    ~H"""
    <span class={@class}><%= @status %></span>
    """
  end

  defp progress_bar(assigns) do
    size_class = Map.get(assigns, :size, "normal")
    assigns = assign(assigns, :size_class, "progress-bar-#{size_class}")

    ~H"""
    <div class={"progress-bar #{@size_class}"}>
      <div class="progress-fill" style={"width: #{@progress}%"}></div>
      <span class="progress-text"><%= @progress %>%</span>
    </div>
    """
  end

  defp format_datetime(datetime) do
    # TODO: Implement proper datetime formatting
    to_string(datetime)
  end

  defp calculate_duration(_session) do
    # TODO: Calculate actual session duration
    "5 minutes"
  end
end