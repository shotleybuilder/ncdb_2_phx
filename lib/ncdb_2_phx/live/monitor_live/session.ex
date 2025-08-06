defmodule NCDB2Phx.Live.MonitorLive.Session do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(%{"session_id" => session_id}, _session, socket) do
    {:ok, socket} = super(%{"session_id" => session_id}, _session, socket)

    case load_session(session_id) do
      {:ok, session} ->
        socket =
          socket
          |> assign(:session, session)
          |> assign(:real_time_metrics, load_real_time_metrics(session_id))
          |> assign(:batch_progress, load_batch_progress(session_id))
          |> assign(:performance_history, load_performance_history(session_id))
          |> assign(:resource_usage, load_resource_usage(session_id))
          |> schedule_real_time_refresh()

        {:ok, socket}

      {:error, :not_found} ->
        socket =
          socket
          |> put_flash(:error, "Session not found")
          |> push_navigate(to: "/sync/monitor")

        {:ok, socket}
    end
  end

  @impl true
  def handle_info(:refresh_real_time, socket) do
    session_id = socket.assigns.session.id
    
    socket =
      socket
      |> assign(:real_time_metrics, load_real_time_metrics(session_id))
      |> assign(:batch_progress, load_batch_progress(session_id))
      |> update(:performance_history, &update_performance_history(&1, session_id))
      |> assign(:resource_usage, load_resource_usage(session_id))
      |> schedule_real_time_refresh()

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_session", _params, socket) do
    case cancel_session(socket.assigns.session.id) do
      {:ok, updated_session} ->
        socket =
          socket
          |> assign(:session, updated_session)
          |> put_flash(:info, "Session cancelled successfully")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel session: #{reason}")}
    end
  end

  @impl true
  def handle_event("pause_session", _params, socket) do
    case pause_session(socket.assigns.session.id) do
      {:ok, updated_session} ->
        socket =
          socket
          |> assign(:session, updated_session)
          |> put_flash(:info, "Session paused successfully")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to pause session: #{reason}")}
    end
  end

  @impl true
  def handle_event("resume_session", _params, socket) do
    case resume_session(socket.assigns.session.id) do
      {:ok, updated_session} ->
        socket =
          socket
          |> assign(:session, updated_session)
          |> put_flash(:info, "Session resumed successfully")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to resume session: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="session-monitor">
      <.page_header session={@session} />
      
      <.session_status_section session={@session} metrics={@real_time_metrics} />
      
      <.batch_progress_section progress={@batch_progress} />
      
      <.performance_metrics_section metrics={@real_time_metrics} />
      
      <.resource_usage_section usage={@resource_usage} />
      
      <.performance_charts_section history={@performance_history} />
    </div>
    """
  end

  defp load_session(id) do
    # TODO: Load from NCDB2Phx.Resources.SyncSession
    {:ok, %{
      id: id,
      name: "Detailed Session",
      status: :running,
      progress: 75,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }}
  end

  defp load_real_time_metrics(_session_id) do
    # TODO: Load real-time metrics
    %{
      records_per_second: 125,
      current_batch: 8,
      total_batches: 12,
      processed_records: 3750,
      total_records: 5000,
      error_count: 15,
      success_rate: 99.6
    }
  end

  defp load_batch_progress(_session_id) do
    # TODO: Load batch-level progress
    []
  end

  defp load_performance_history(_session_id) do
    # TODO: Load historical performance data
    %{
      timestamps: [],
      records_per_second: [],
      memory_usage: [],
      error_rates: [],
      response_times: []
    }
  end

  defp load_resource_usage(_session_id) do
    # TODO: Load resource usage data
    %{
      memory_mb: 145.6,
      cpu_percent: 23.4,
      disk_io_mb_per_sec: 12.8,
      network_kb_per_sec: 156.2
    }
  end

  defp update_performance_history(history, session_id) do
    # TODO: Add new data point to history
    current_metrics = load_real_time_metrics(session_id)
    timestamp = DateTime.utc_now()

    %{
      history |
      timestamps: [timestamp | Enum.take(history.timestamps, 59)],
      records_per_second: [current_metrics.records_per_second | Enum.take(history.records_per_second, 59)],
      memory_usage: [145.6 | Enum.take(history.memory_usage, 59)],
      error_rates: [0.4 | Enum.take(history.error_rates, 59)],
      response_times: [125 | Enum.take(history.response_times, 59)]
    }
  end

  defp schedule_real_time_refresh(socket) do
    Process.send_after(self(), :refresh_real_time, 1000)
    socket
  end

  defp cancel_session(_id), do: {:error, "Not implemented"}
  defp pause_session(_id), do: {:error, "Not implemented"}
  defp resume_session(_id), do: {:error, "Not implemented"}

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <div class="header-left">
        <h1>Session Monitor</h1>
        <nav class="breadcrumb">
          <.link navigate="/sync/monitor">Monitor</.link>
          <span>/</span>
          <span><%= @session.name || "Session #{@session.id}" %></span>
        </nav>
      </div>
      
      <div class="header-actions">
        <%= case @session.status do %>
          <% :running -> %>
            <button class="btn btn-warning" phx-click="pause_session">
              Pause Session
            </button>
            <button class="btn btn-error" phx-click="cancel_session">
              Cancel Session
            </button>
          <% :paused -> %>
            <button class="btn btn-success" phx-click="resume_session">
              Resume Session
            </button>
            <button class="btn btn-error" phx-click="cancel_session">
              Cancel Session
            </button>
          <% _ -> %>
            <span class="text-muted">No actions available</span>
        <% end %>
      </div>
    </div>
    """
  end

  defp session_status_section(assigns) do
    ~H"""
    <div class="status-section">
      <div class="status-cards">
        <.status_card
          title="Status"
          value={@session.status}
          type="status"
        />
        
        <.status_card
          title="Progress"
          value={"#{@session.progress}%"}
          type="progress"
          extra={progress_bar_html(@session.progress)}
        />
        
        <.status_card
          title="Records/sec"
          value={@metrics.records_per_second}
          type="metric"
        />
        
        <.status_card
          title="Success Rate"
          value={"#{@metrics.success_rate}%"}
          type="metric"
        />
        
        <.status_card
          title="Errors"
          value={@metrics.error_count}
          type="error"
        />
        
        <.status_card
          title="ETA"
          value={calculate_eta(@metrics)}
          type="time"
        />
      </div>
    </div>
    """
  end

  defp batch_progress_section(assigns) do
    ~H"""
    <div class="batch-progress-section">
      <h2>Batch Progress</h2>
      <%= if @progress == [] do %>
        <div class="empty-state">
          <p>No batch data available yet</p>
        </div>
      <% else %>
        <div class="batch-timeline">
          <%= for batch <- @progress do %>
            <.batch_progress_item batch={batch} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp performance_metrics_section(assigns) do
    ~H"""
    <div class="performance-section">
      <h2>Real-time Metrics</h2>
      <div class="metrics-grid">
        <.metric_display
          label="Current Batch"
          value={"#{@metrics.current_batch} / #{@metrics.total_batches}"}
          trend="stable"
        />
        
        <.metric_display
          label="Processed Records"
          value={"#{@metrics.processed_records} / #{@metrics.total_records}"}
          trend="increasing"
        />
        
        <.metric_display
          label="Processing Rate"
          value={"#{@metrics.records_per_second} rec/s"}
          trend="stable"
        />
        
        <.metric_display
          label="Error Rate"
          value={"#{Float.round((1 - @metrics.success_rate / 100) * 100, 2)}%"}
          trend="stable"
        />
      </div>
    </div>
    """
  end

  defp resource_usage_section(assigns) do
    ~H"""
    <div class="resource-section">
      <h2>Resource Usage</h2>
      <div class="resource-grid">
        <.resource_meter
          label="Memory"
          value={@usage.memory_mb}
          unit="MB"
          max={500}
          type="memory"
        />
        
        <.resource_meter
          label="CPU"
          value={@usage.cpu_percent}
          unit="%"
          max={100}
          type="cpu"
        />
        
        <.resource_meter
          label="Disk I/O"
          value={@usage.disk_io_mb_per_sec}
          unit="MB/s"
          max={50}
          type="disk"
        />
        
        <.resource_meter
          label="Network"
          value={@usage.network_kb_per_sec}
          unit="KB/s"
          max={1000}
          type="network"
        />
      </div>
    </div>
    """
  end

  defp performance_charts_section(assigns) do
    ~H"""
    <div class="charts-section">
      <h2>Performance History</h2>
      <div class="charts-grid">
        <.real_time_chart
          title="Records Per Second"
          chart_id="rps-chart"
          data={@history.records_per_second}
          timestamps={@history.timestamps}
          color="blue"
        />
        
        <.real_time_chart
          title="Memory Usage (MB)"
          chart_id="memory-chart"
          data={@history.memory_usage}
          timestamps={@history.timestamps}
          color="green"
        />
        
        <.real_time_chart
          title="Error Rate (%)"
          chart_id="error-chart"
          data={@history.error_rates}
          timestamps={@history.timestamps}
          color="red"
        />
        
        <.real_time_chart
          title="Response Time (ms)"
          chart_id="response-chart"
          data={@history.response_times}
          timestamps={@history.timestamps}
          color="purple"
        />
      </div>
    </div>
    """
  end

  defp status_card(assigns) do
    card_class = case assigns.type do
      "status" -> "status-card"
      "progress" -> "progress-card"
      "metric" -> "metric-card"
      "error" -> "error-card"
      "time" -> "time-card"
      _ -> "status-card"
    end

    assigns = assign(assigns, :card_class, card_class)

    ~H"""
    <div class={@card_class}>
      <h4><%= @title %></h4>
      <div class="card-value">
        <%= case @type do %>
          <% "status" -> %>
            <.status_badge status={@value} />
          <% "progress" -> %>
            <span><%= @value %></span>
            <div class="progress-visual">
              <%= raw(Map.get(assigns, :extra, "")) %>
            </div>
          <% _ -> %>
            <span><%= @value %></span>
        <% end %>
      </div>
    </div>
    """
  end

  defp batch_progress_item(assigns) do
    ~H"""
    <div class={"batch-item batch-#{@batch.status}"}>
      <div class="batch-number">Batch #<%= @batch.number %></div>
      <div class="batch-info">
        <div class="batch-records"><%= @batch.records %> records</div>
        <div class="batch-duration"><%= @batch.duration %>s</div>
      </div>
      <div class="batch-status">
        <.status_badge status={@batch.status} />
      </div>
    </div>
    """
  end

  defp metric_display(assigns) do
    ~H"""
    <div class="metric-display">
      <div class="metric-label"><%= @label %></div>
      <div class="metric-value"><%= @value %></div>
      <.trend_indicator trend={@trend} />
    </div>
    """
  end

  defp resource_meter(assigns) do
    percentage = (assigns.value / assigns.max) * 100
    meter_class = cond do
      percentage >= 90 -> "meter-danger"
      percentage >= 75 -> "meter-warning"
      true -> "meter-normal"
    end

    assigns = assign(assigns, :percentage, percentage)
    assigns = assign(assigns, :meter_class, meter_class)

    ~H"""
    <div class="resource-meter">
      <div class="meter-header">
        <span class="meter-label"><%= @label %></span>
        <span class="meter-value"><%= @value %><%= @unit %></span>
      </div>
      <div class={"meter-bar #{@meter_class}"}>
        <div class="meter-fill" style={"width: #{@percentage}%"}></div>
      </div>
    </div>
    """
  end

  defp real_time_chart(assigns) do
    ~H"""
    <div class="chart-container">
      <h4><%= @title %></h4>
      <div 
        id={@chart_id} 
        class="real-time-chart" 
        phx-hook="RealTimeChart" 
        data-color={@color}
        data-points={Jason.encode!(@data)}
        data-timestamps={Jason.encode!(@timestamps)}
      >
        <!-- Chart will be rendered by JavaScript hook -->
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    class = case assigns.status do
      :pending -> "badge badge-secondary"
      :running -> "badge badge-primary"
      :paused -> "badge badge-warning"
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

  defp progress_bar_html(progress) do
    ~s(<div class="mini-progress-bar"><div class="mini-progress-fill" style="width: #{progress}%"></div></div>)
  end

  defp calculate_eta(metrics) do
    if metrics.records_per_second > 0 do
      remaining_records = metrics.total_records - metrics.processed_records
      remaining_seconds = div(remaining_records, metrics.records_per_second)
      
      minutes = div(remaining_seconds, 60)
      seconds = rem(remaining_seconds, 60)
      
      "#{minutes}m #{seconds}s"
    else
      "--"
    end
  end
end