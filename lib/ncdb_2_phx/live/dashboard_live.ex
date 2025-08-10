defmodule NCDB2Phx.Live.DashboardLive do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    socket =
      socket
      |> assign_dashboard_data()
      |> schedule_dashboard_refresh()

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    socket =
      socket
      |> assign_dashboard_data()
      |> schedule_dashboard_refresh()

    {:noreply, socket}
  end

  @impl true
  def handle_event("new_sync", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin/sync/sessions/new")}
  end

  @impl true
  def handle_event("view_sessions", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin/sync/sessions")}
  end

  @impl true
  def handle_event("view_logs", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin/sync/logs")}
  end

  @impl true
  def handle_event("system_monitor", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin/sync/monitor")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="sync-dashboard">
      <.dashboard_header />
      
      <div class="dashboard-grid">
        <.active_sessions_card sessions={@active_sessions} />
        <.recent_activity_card activities={@recent_activities} />
        <.system_health_card health={@system_health} />
        <.quick_actions_card />
      </div>
      
      <.sync_statistics_section stats={@sync_stats} />
    </div>
    """
  end

  defp assign_dashboard_data(socket) do
    # TODO: Implement actual data loading from Ash resources
    assign(socket,
      active_sessions: load_active_sessions(),
      recent_activities: load_recent_activities(),
      system_health: calculate_system_health(),
      sync_stats: load_sync_statistics()
    )
  end

  defp schedule_dashboard_refresh(socket) do
    Process.send_after(self(), :refresh_dashboard, 5000)
    socket
  end

  defp load_active_sessions do
    # TODO: Load from NCDB2Phx.Resources.SyncSession
    []
  end

  defp load_recent_activities do
    # TODO: Load from NCDB2Phx.Resources.SyncLog
    []
  end

  defp calculate_system_health do
    # TODO: Calculate based on recent sessions and errors
    %{
      status: :healthy,
      error_rate: 0.05,
      avg_duration: 120,
      active_syncs: 3
    }
  end

  defp load_sync_statistics do
    # TODO: Calculate from historical data
    %{
      total_sessions: 0,
      successful_sessions: 0,
      failed_sessions: 0,
      total_records_synced: 0
    }
  end

  defp dashboard_header(assigns) do
    ~H"""
    <div class="dashboard-header">
      <h1>Sync Dashboard</h1>
      <div class="dashboard-actions">
        <button class="btn btn-primary" phx-click="new_sync">
          New Sync
        </button>
      </div>
    </div>
    """
  end

  defp active_sessions_card(assigns) do
    ~H"""
    <div class="dashboard-card">
      <h3>Active Sessions</h3>
      <div class="session-count"><%= length(@sessions) %></div>
      <%= if @sessions == [] do %>
        <p class="empty-state">No active sync sessions</p>
      <% else %>
        <ul class="session-list">
          <%= for session <- @sessions do %>
            <li class="session-item">
              <span class="session-name"><%= session.name %></span>
              <span class="session-progress"><%= session.progress %>%</span>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  defp recent_activity_card(assigns) do
    ~H"""
    <div class="dashboard-card">
      <h3>Recent Activity</h3>
      <%= if @activities == [] do %>
        <p class="empty-state">No recent activity</p>
      <% else %>
        <ul class="activity-list">
          <%= for activity <- @activities do %>
            <li class="activity-item">
              <span class="activity-message"><%= activity.message %></span>
              <span class="activity-time"><%= activity.timestamp %></span>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  defp system_health_card(assigns) do
    health = assigns[:health] || %{status: :unknown}
    status_class = case health.status do
      :healthy -> "status-healthy"
      :warning -> "status-warning"
      :error -> "status-error"
    end

    assigns = assign(assigns, :status_class, status_class)
    assigns = assign(assigns, :health, health)

    ~H"""
    <div class="dashboard-card">
      <h3>System Health</h3>
      <div class={"health-indicator #{@status_class}"}>
        <div class="health-status"><%= @health.status %></div>
        <div class="health-metrics">
          <div class="metric">
            <span class="metric-label">Error Rate:</span>
            <span class="metric-value"><%= Float.round((@health[:error_rate] || 0) * 100, 1) %>%</span>
          </div>
          <div class="metric">
            <span class="metric-label">Avg Duration:</span>
            <span class="metric-value"><%= @health[:avg_duration] || 0 %>s</span>
          </div>
          <div class="metric">
            <span class="metric-label">Active Syncs:</span>
            <span class="metric-value"><%= @health[:active_syncs] || 0 %></span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp quick_actions_card(assigns) do
    ~H"""
    <div class="dashboard-card">
      <h3>Quick Actions</h3>
      <div class="quick-actions">
        <button class="btn btn-outline" phx-click="view_sessions">
          View All Sessions
        </button>
        <button class="btn btn-outline" phx-click="view_logs">
          View Logs
        </button>
        <button class="btn btn-outline" phx-click="system_monitor">
          System Monitor
        </button>
      </div>
    </div>
    """
  end

  defp sync_statistics_section(assigns) do
    ~H"""
    <div class="statistics-section">
      <h2>Sync Statistics</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <h4>Total Sessions</h4>
          <div class="stat-value"><%= @stats.total_sessions %></div>
        </div>
        <div class="stat-card">
          <h4>Successful</h4>
          <div class="stat-value success"><%= @stats.successful_sessions %></div>
        </div>
        <div class="stat-card">
          <h4>Failed</h4>
          <div class="stat-value error"><%= @stats.failed_sessions %></div>
        </div>
        <div class="stat-card">
          <h4>Records Synced</h4>
          <div class="stat-value"><%= @stats.total_records_synced %></div>
        </div>
      </div>
    </div>
    """
  end
end