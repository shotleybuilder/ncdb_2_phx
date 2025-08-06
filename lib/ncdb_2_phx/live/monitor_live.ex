defmodule NCDB2Phx.Live.MonitorLive do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket} = super(_params, _session, socket)

    socket =
      socket
      |> assign(:active_sessions, load_active_sessions())
      |> assign(:system_metrics, load_system_metrics())
      |> assign(:alerts, load_active_alerts())
      |> assign(:performance_charts, load_performance_data())
      |> schedule_metrics_refresh()

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh_metrics, socket) do
    socket =
      socket
      |> assign(:active_sessions, load_active_sessions())
      |> assign(:system_metrics, load_system_metrics())
      |> assign(:alerts, load_active_alerts())
      |> update(:performance_charts, &update_performance_data/1)
      |> schedule_metrics_refresh()

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_session", %{"id" => session_id}, socket) do
    case cancel_session(session_id) do
      {:ok, _session} ->
        socket =
          socket
          |> assign(:active_sessions, load_active_sessions())
          |> put_flash(:info, "Session cancelled successfully")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel session: #{reason}")}
    end
  end

  @impl true
  def handle_event("pause_session", %{"id" => session_id}, socket) do
    case pause_session(session_id) do
      {:ok, _session} ->
        socket =
          socket
          |> assign(:active_sessions, load_active_sessions())
          |> put_flash(:info, "Session paused successfully")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to pause session: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="monitor-dashboard">
      <.page_header />
      
      <.alerts_section alerts={@alerts} />
      
      <.system_metrics_section metrics={@system_metrics} />
      
      <.active_sessions_section sessions={@active_sessions} />
      
      <.performance_charts_section charts={@performance_charts} />
    </div>
    """
  end

  defp load_active_sessions do
    # TODO: Load active sessions from NCDB2Phx.Resources.SyncSession
    []
  end

  defp load_system_metrics do
    # TODO: Calculate system metrics
    %{
      cpu_usage: 45.6,
      memory_usage: 62.3,
      active_syncs: 3,
      total_records_per_second: 456,
      error_rate: 0.02,
      avg_response_time: 150
    }
  end

  defp load_active_alerts do
    # TODO: Load active alerts/warnings
    []
  end

  defp load_performance_data do
    # TODO: Load performance chart data
    %{
      records_per_second: [],
      error_rates: [],
      memory_usage: [],
      response_times: []
    }
  end

  defp update_performance_data(charts) do
    # TODO: Update chart data with new points
    charts
  end

  defp schedule_metrics_refresh(socket) do
    Process.send_after(self(), :refresh_metrics, 2000)
    socket
  end

  defp cancel_session(_id) do
    # TODO: Implement session cancellation
    {:error, "Not implemented"}
  end

  defp pause_session(_id) do
    # TODO: Implement session pause
    {:error, "Not implemented"}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <h1>Live Monitor</h1>
      <div class="monitor-status">
        <div class="status-indicator status-active"></div>
        <span>Real-time monitoring active</span>
      </div>
    </div>
    """
  end

  defp alerts_section(assigns) do
    ~H"""
    <%= if @alerts != [] do %>
      <div class="alerts-section">
        <h2>Active Alerts</h2>
        <div class="alerts-list">
          <%= for alert <- @alerts do %>
            <div class={"alert alert-#{alert.severity}"}>
              <div class="alert-content">
                <strong><%= alert.title %></strong>
                <p><%= alert.message %></p>
              </div>
              <div class="alert-timestamp">
                <%= format_datetime(alert.timestamp) %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp system_metrics_section(assigns) do
    ~H"""
    <div class="system-metrics">
      <h2>System Health</h2>
      <div class="metrics-grid">
        <.metric_card
          title="CPU Usage"
          value={"#{@metrics.cpu_usage}%"}
          status={metric_status(@metrics.cpu_usage, 80, 95)}
          trend="stable"
        />
        
        <.metric_card
          title="Memory Usage"
          value={"#{@metrics.memory_usage}%"}
          status={metric_status(@metrics.memory_usage, 75, 90)}
          trend="increasing"
        />
        
        <.metric_card
          title="Active Syncs"
          value={@metrics.active_syncs}
          status="normal"
          trend="stable"
        />
        
        <.metric_card
          title="Records/sec"
          value={@metrics.total_records_per_second}
          status="normal"
          trend="stable"
        />
        
        <.metric_card
          title="Error Rate"
          value={"#{Float.round(@metrics.error_rate * 100, 1)}%"}
          status={error_rate_status(@metrics.error_rate)}
          trend="stable"
        />
        
        <.metric_card
          title="Response Time"
          value={"#{@metrics.avg_response_time}ms"}
          status={response_time_status(@metrics.avg_response_time)}
          trend="stable"
        />
      </div>
    </div>
    """
  end

  defp active_sessions_section(assigns) do
    ~H"""
    <div class="active-sessions">
      <h2>Active Sessions</h2>
      <%= if @sessions == [] do %>
        <div class="empty-state">
          <p>No active sync sessions</p>
        </div>
      <% else %>
        <div class="sessions-grid">
          <%= for session <- @sessions do %>
            <.session_monitor_card session={session} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp performance_charts_section(assigns) do
    ~H"""
    <div class="performance-charts">
      <h2>Performance Trends</h2>
      <div class="charts-grid">
        <.chart_card
          title="Records Per Second"
          chart_id="records-chart"
          data={@charts.records_per_second}
        />
        
        <.chart_card
          title="Error Rates"
          chart_id="errors-chart"
          data={@charts.error_rates}
        />
        
        <.chart_card
          title="Memory Usage"
          chart_id="memory-chart"
          data={@charts.memory_usage}
        />
        
        <.chart_card
          title="Response Times"
          chart_id="response-chart"
          data={@charts.response_times}
        />
      </div>
    </div>
    """
  end

  defp metric_card(assigns) do
    ~H"""
    <div class={"metric-card metric-#{@status}"}>
      <div class="metric-header">
        <h4><%= @title %></h4>
        <.trend_indicator trend={@trend} />
      </div>
      <div class="metric-value"><%= @value %></div>
      <.metric_status_indicator status={@status} />
    </div>
    """
  end

  defp session_monitor_card(assigns) do
    ~H"""
    <div class="session-monitor-card">
      <div class="session-header">
        <h4>
          <.link navigate={"/sync/sessions/#{@session.id}"}>
            <%= @session.name || "Session #{@session.id}" %>
          </.link>
        </h4>
        <.status_badge status={@session.status} />
      </div>
      
      <div class="session-progress">
        <.progress_bar progress={@session.progress || 0} />
        <div class="progress-stats">
          <span><%= @session.records_processed || 0 %> / <%= @session.total_records || "?" %></span>
          <span><%= @session.records_per_second || 0 %> rec/s</span>
        </div>
      </div>
      
      <div class="session-metrics">
        <div class="metric">
          <span class="metric-label">Duration:</span>
          <span class="metric-value"><%= calculate_duration(@session) %></span>
        </div>
        <div class="metric">
          <span class="metric-label">Errors:</span>
          <span class="metric-value error"><%= @session.error_count || 0 %></span>
        </div>
      </div>
      
      <div class="session-actions">
        <.link navigate={"/sync/monitor/#{@session.id}"} class="btn btn-sm btn-outline">
          Details
        </.link>
        
        <%= if @session.status == :running do %>
          <button class="btn btn-sm btn-warning" phx-click="pause_session" phx-value-id={@session.id}>
            Pause
          </button>
          <button class="btn btn-sm btn-error" phx-click="cancel_session" phx-value-id={@session.id}>
            Cancel
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp chart_card(assigns) do
    ~H"""
    <div class="chart-card">
      <h4><%= @title %></h4>
      <div class="chart-container">
        <div id={@chart_id} class="chart" phx-hook="LineChart" data-points={Jason.encode!(@data)}>
          <!-- Chart will be rendered by JavaScript hook -->
        </div>
      </div>
    </div>
    """
  end

  defp trend_indicator(assigns) do
    icon_class = case assigns.trend do
      "increasing" -> "trend-up"
      "decreasing" -> "trend-down"
      "stable" -> "trend-stable"
      _ -> "trend-unknown"
    end

    assigns = assign(assigns, :icon_class, icon_class)

    ~H"""
    <span class={"trend-indicator #{@icon_class}"}></span>
    """
  end

  defp metric_status_indicator(assigns) do
    ~H"""
    <div class={"status-indicator status-#{@status}"}></div>
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
    ~H"""
    <div class="progress-bar">
      <div class="progress-fill" style={"width: #{@progress}%"}></div>
      <span class="progress-text"><%= @progress %>%</span>
    </div>
    """
  end

  defp metric_status(value, warning_threshold, error_threshold) do
    cond do
      value >= error_threshold -> "error"
      value >= warning_threshold -> "warning"
      true -> "normal"
    end
  end

  defp error_rate_status(rate) do
    cond do
      rate >= 0.1 -> "error"
      rate >= 0.05 -> "warning"
      true -> "normal"
    end
  end

  defp response_time_status(time) do
    cond do
      time >= 1000 -> "error"
      time >= 500 -> "warning"
      true -> "normal"
    end
  end

  defp calculate_duration(_session) do
    # TODO: Calculate actual session duration
    "5m 32s"
  end

  defp format_datetime(datetime) do
    # TODO: Implement proper datetime formatting
    to_string(datetime)
  end
end