defmodule NCDB2Phx.Live.BatchLive.Show do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {:ok, socket} = super(%{"id" => id}, session, socket)

    {:ok, batch} = load_batch(id)
    socket =
      socket
      |> assign(:batch, batch)
      |> assign(:session, load_batch_session(batch.session_id))
      |> assign(:record_details, load_record_details(id))
      |> assign(:error_analysis, analyze_batch_errors(id))
      |> assign(:performance_metrics, calculate_batch_performance(batch))

    {:ok, socket}
  end

  @impl true
  def handle_event("retry_batch", _params, socket) do
    {:error, reason} = retry_batch(socket.assigns.batch.id)
    {:noreply, put_flash(socket, :error, "Failed to retry batch: #{reason}")}
  end

  @impl true
  def handle_event("export_batch_data", _params, socket) do
    # TODO: Implement batch data export
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  @impl true
  def handle_event("toggle_record_details", %{"record_id" => _record_id}, socket) do
    # TODO: Toggle detailed view for specific record
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="batch-show">
      <.page_header batch={@batch} session={@session} />
      
      <div class="batch-details-grid">
        <.batch_overview batch={@batch} />
        <.batch_performance metrics={@performance_metrics} />
        <.batch_timeline batch={@batch} />
      </div>
      
      <.error_analysis_section analysis={@error_analysis} />
      
      <.record_details_section records={@record_details} />
    </div>
    """
  end

  defp load_batch(id) do
    # TODO: Load from NCDB2Phx.Resources.SyncBatch
    {:ok, %{
      id: id,
      batch_number: 5,
      session_id: "session_123",
      status: :completed,
      record_count: 250,
      successful_count: 245,
      failed_count: 5,
      success_rate: 98.0,
      processing_time: 45,
      inserted_at: DateTime.utc_now(),
      completed_at: DateTime.utc_now()
    }}
  end

  defp load_batch_session(_session_id) do
    # TODO: Load session from NCDB2Phx.Resources.SyncSession
    %{
      id: "session_123",
      name: "Test Session"
    }
  end

  defp load_record_details(_batch_id) do
    # TODO: Load record-level details
    []
  end

  defp analyze_batch_errors(_batch_id) do
    # TODO: Analyze errors and group by type/pattern
    %{
      total_errors: 5,
      error_types: [
        %{type: "validation_error", count: 3, percentage: 60.0},
        %{type: "network_timeout", count: 2, percentage: 40.0}
      ],
      common_patterns: [
        "Missing required field: email",
        "Connection timeout after 30s"
      ]
    }
  end

  defp calculate_batch_performance(batch) do
    # TODO: Calculate performance metrics
    %{
      records_per_second: if(batch.processing_time > 0, do: batch.record_count / batch.processing_time, else: 0),
      avg_record_time: if(batch.record_count > 0, do: batch.processing_time / batch.record_count, else: 0),
      memory_efficiency: 85.5,
      throughput_compared_to_session_avg: 12.3
    }
  end

  defp retry_batch(_id) do
    # TODO: Implement batch retry
    {:error, "Not implemented"}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <div class="header-left">
        <h1>Batch #<%= @batch.batch_number %> Details</h1>
        <nav class="breadcrumb">
          <.link navigate="/sync/batches">Batches</.link>
          <span>/</span>
          <.link navigate={"/sync/sessions/#{@session.id}"}><%= @session.name %></.link>
          <span>/</span>
          <span>Batch #<%= @batch.batch_number %></span>
        </nav>
      </div>
      
      <div class="header-actions">
        <%= if @batch.status == :failed do %>
          <button class="btn btn-primary" phx-click="retry_batch">
            Retry Batch
          </button>
        <% end %>
        
        <button class="btn btn-outline" phx-click="export_batch_data">
          Export Data
        </button>
      </div>
    </div>
    """
  end

  defp batch_overview(assigns) do
    ~H"""
    <div class="batch-card">
      <h3>Batch Overview</h3>
      <div class="batch-meta">
        <div class="meta-group">
          <div class="meta-item">
            <label>Status:</label>
            <.status_badge status={@batch.status} />
          </div>
          
          <div class="meta-item">
            <label>Record Count:</label>
            <span class="record-count">
              <%= @batch.record_count %> total
              <small>(<%= @batch.successful_count %> success, <%= @batch.failed_count %> failed)</small>
            </span>
          </div>
          
          <div class="meta-item">
            <label>Success Rate:</label>
            <.success_rate_display rate={@batch.success_rate} />
          </div>
        </div>
        
        <div class="meta-group">
          <div class="meta-item">
            <label>Started:</label>
            <span><%= format_datetime(@batch.inserted_at) %></span>
          </div>
          
          <%= if @batch.completed_at do %>
            <div class="meta-item">
              <label>Completed:</label>
              <span><%= format_datetime(@batch.completed_at) %></span>
            </div>
          <% end %>
          
          <div class="meta-item">
            <label>Processing Time:</label>
            <span><%= format_duration(@batch.processing_time) %></span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp batch_performance(assigns) do
    ~H"""
    <div class="batch-card">
      <h3>Performance Metrics</h3>
      <div class="performance-grid">
        <div class="perf-metric">
          <div class="metric-value"><%= Float.round(@metrics.records_per_second, 1) %></div>
          <div class="metric-label">Records/sec</div>
        </div>
        
        <div class="perf-metric">
          <div class="metric-value"><%= Float.round(@metrics.avg_record_time * 1000, 1) %>ms</div>
          <div class="metric-label">Avg Time/Record</div>
        </div>
        
        <div class="perf-metric">
          <div class="metric-value"><%= @metrics.memory_efficiency %>%</div>
          <div class="metric-label">Memory Efficiency</div>
        </div>
        
        <div class="perf-metric">
          <div class="metric-value">
            <%= if @metrics.throughput_compared_to_session_avg > 0, do: "+", else: "" %><%= Float.round(@metrics.throughput_compared_to_session_avg, 1) %>%
          </div>
          <div class="metric-label">vs Session Avg</div>
        </div>
      </div>
    </div>
    """
  end

  defp batch_timeline(assigns) do
    ~H"""
    <div class="batch-card">
      <h3>Processing Timeline</h3>
      <div class="timeline">
        <div class="timeline-item">
          <div class="timeline-marker timeline-start"></div>
          <div class="timeline-content">
            <div class="timeline-title">Batch Started</div>
            <div class="timeline-time"><%= format_datetime(@batch.inserted_at) %></div>
          </div>
        </div>
        
        <%= if @batch.completed_at do %>
          <div class="timeline-item">
            <div class="timeline-marker timeline-end"></div>
            <div class="timeline-content">
              <div class="timeline-title">Batch Completed</div>
              <div class="timeline-time"><%= format_datetime(@batch.completed_at) %></div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp error_analysis_section(assigns) do
    ~H"""
    <%= if @analysis.total_errors > 0 do %>
      <div class="section">
        <h2>Error Analysis</h2>
        <div class="error-analysis-grid">
          <.error_summary analysis={@analysis} />
          <.error_patterns patterns={@analysis.common_patterns} />
        </div>
      </div>
    <% end %>
    """
  end

  defp error_summary(assigns) do
    ~H"""
    <div class="error-card">
      <h4>Error Breakdown</h4>
      <div class="error-total">
        <span class="error-count"><%= @analysis.total_errors %></span>
        <span class="error-label">Total Errors</span>
      </div>
      
      <div class="error-types">
        <%= for error_type <- @analysis.error_types do %>
          <div class="error-type-item">
            <div class="error-type-info">
              <span class="error-type-name"><%= error_type.type %></span>
              <span class="error-type-count"><%= error_type.count %> (<%= error_type.percentage %>%)</span>
            </div>
            <div class="error-type-bar">
              <div class="error-type-fill" style={"width: #{error_type.percentage}%"}></div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp error_patterns(assigns) do
    ~H"""
    <div class="error-card">
      <h4>Common Error Patterns</h4>
      <%= if @patterns == [] do %>
        <p class="empty-state">No common patterns identified</p>
      <% else %>
        <ul class="error-patterns-list">
          <%= for pattern <- @patterns do %>
            <li class="error-pattern">
              <code><%= pattern %></code>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  defp record_details_section(assigns) do
    ~H"""
    <div class="section">
      <h2>Record Details</h2>
      <%= if @records == [] do %>
        <div class="empty-state">
          <p>No detailed record information available</p>
        </div>
      <% else %>
        <.records_table records={@records} />
      <% end %>
    </div>
    """
  end

  defp records_table(assigns) do
    ~H"""
    <div class="records-table">
      <table class="table">
        <thead>
          <tr>
            <th>Record #</th>
            <th>Status</th>
            <th>Processing Time</th>
            <th>Error Message</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <%= for record <- @records do %>
            <tr class={"record-row record-#{record.status}"}>
              <td>#<%= record.record_number %></td>
              <td><.status_badge status={record.status} /></td>
              <td><%= record.processing_time %>ms</td>
              <td>
                <%= if record.error_message do %>
                  <span class="error-message"><%= record.error_message %></span>
                <% else %>
                  <span class="text-muted">--</span>
                <% end %>
              </td>
              <td>
                <button 
                  class="btn btn-sm btn-outline" 
                  phx-click="toggle_record_details" 
                  phx-value-record_id={record.id}
                >
                  Details
                </button>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp status_badge(assigns) do
    class = case assigns.status do
      :pending -> "badge badge-secondary"
      :processing -> "badge badge-primary"
      :completed -> "badge badge-success"
      :failed -> "badge badge-error"
      _ -> "badge"
    end

    assigns = assign(assigns, :class, class)

    ~H"""
    <span class={@class}><%= @status %></span>
    """
  end

  defp success_rate_display(assigns) do
    rate_class = cond do
      assigns.rate >= 95 -> "success-rate-good"
      assigns.rate >= 80 -> "success-rate-warning"
      true -> "success-rate-poor"
    end

    assigns = assign(assigns, :rate_class, rate_class)

    ~H"""
    <span class={"success-rate #{@rate_class}"}><%= @rate %>%</span>
    """
  end

  defp format_duration(nil), do: "--"
  defp format_duration(seconds) when is_number(seconds) do
    if seconds < 60 do
      "#{seconds}s"
    else
      minutes = div(seconds, 60)
      remaining_seconds = rem(seconds, 60)
      "#{minutes}m #{remaining_seconds}s"
    end
  end

  defp format_datetime(datetime) do
    # TODO: Implement proper datetime formatting
    to_string(datetime)
  end
end