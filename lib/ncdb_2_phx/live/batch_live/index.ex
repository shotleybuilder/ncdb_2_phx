defmodule NCDB2Phx.Live.BatchLive.Index do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    socket =
      socket
      |> assign(:batches, list_batches())
      |> assign(:filters, %{status: :all, session: :all, date_range: :all})
      |> assign(:sort_by, :inserted_at)
      |> assign(:sort_order, :desc)
      |> assign(:selected_batches, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_filters_and_sort(params)
      |> assign(:batches, list_batches_with_filters_and_sort(socket.assigns))

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = build_filters(filter_params)
    
    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:batches, list_batches_with_filters_and_sort(socket.assigns))

    {:noreply, push_patch(socket, to: build_filter_path(filters, socket.assigns))}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    current_sort = socket.assigns.sort_by
    sort_order = if current_sort == String.to_atom(sort_by) and socket.assigns.sort_order == :asc do
      :desc
    else
      :asc
    end

    socket =
      socket
      |> assign(:sort_by, String.to_atom(sort_by))
      |> assign(:sort_order, sort_order)
      |> assign(:batches, list_batches_with_filters_and_sort(socket.assigns))

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_batch", %{"id" => id}, socket) do
    selected = toggle_selected_batch(socket.assigns.selected_batches, id)
    {:noreply, assign(socket, :selected_batches, selected)}
  end

  @impl true
  def handle_event("bulk_retry", _params, socket) do
    {:error, reason} = retry_batches(socket.assigns.selected_batches)
    {:noreply, put_flash(socket, :error, "Failed to retry batches: #{reason}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="batch-index">
      <.page_header />
      
      <.filter_and_sort_section 
        filters={@filters} 
        sort_by={@sort_by} 
        sort_order={@sort_order}
      />
      
      <.bulk_actions selected={@selected_batches} />
      
      <.batches_table 
        batches={@batches} 
        selected={@selected_batches}
        sort_by={@sort_by}
        sort_order={@sort_order}
      />
      
      <.pagination />
    </div>
    """
  end

  defp list_batches do
    # TODO: Load from NCDB2Phx.Resources.SyncBatch
    []
  end

  defp list_batches_with_filters_and_sort(_assigns) do
    # TODO: Implement filtering and sorting
    []
  end

  defp apply_filters_and_sort(socket, params) do
    filters = %{
      status: atomize_param(params["status"], :all),
      session: atomize_param(params["session"], :all),
      date_range: atomize_param(params["date_range"], :all)
    }

    sort_by = atomize_param(params["sort_by"], :inserted_at)
    sort_order = atomize_param(params["sort_order"], :desc)

    socket
    |> assign(:filters, filters)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
  end

  defp build_filters(params) do
    %{
      status: atomize_param(params["status"], :all),
      session: atomize_param(params["session"], :all),
      date_range: atomize_param(params["date_range"], :all)
    }
  end

  defp atomize_param(value, _default) when is_binary(value), do: String.to_atom(value)
  defp atomize_param(_value, default), do: default

  defp build_filter_path(filters, assigns) do
    query_params = 
      filters
      |> Map.put(:sort_by, assigns.sort_by)
      |> Map.put(:sort_order, assigns.sort_order)
      |> Enum.reject(fn {_k, v} -> v in [:all, :inserted_at, :desc] end)
      |> Enum.into(%{})

    if query_params == %{} do
      "/batches"
    else
      "/batches?" <> URI.encode_query(query_params)
    end
  end

  defp toggle_selected_batch(selected, id) do
    if id in selected do
      List.delete(selected, id)
    else
      [id | selected]
    end
  end

  defp retry_batches(_batch_ids) do
    # TODO: Implement batch retry
    {:error, "Not implemented"}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <h1>Sync Batches</h1>
      <p class="page-description">
        Monitor and manage batch-level processing across all sync sessions
      </p>
    </div>
    """
  end

  defp filter_and_sort_section(assigns) do
    ~H"""
    <div class="filter-sort-section">
      <form phx-change="filter" class="filter-form">
        <div class="filter-group">
          <label>Status:</label>
          <select name="filter[status]">
            <option value="all" selected={@filters.status == :all}>All</option>
            <option value="pending" selected={@filters.status == :pending}>Pending</option>
            <option value="processing" selected={@filters.status == :processing}>Processing</option>
            <option value="completed" selected={@filters.status == :completed}>Completed</option>
            <option value="failed" selected={@filters.status == :failed}>Failed</option>
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
          <label>Date Range:</label>
          <select name="filter[date_range]">
            <option value="all" selected={@filters.date_range == :all}>All</option>
            <option value="today" selected={@filters.date_range == :today}>Today</option>
            <option value="week" selected={@filters.date_range == :week}>This Week</option>
            <option value="month" selected={@filters.date_range == :month}>This Month</option>
          </select>
        </div>
      </form>
    </div>
    """
  end

  defp bulk_actions(assigns) do
    ~H"""
    <%= if @selected != [] do %>
      <div class="bulk-actions">
        <span class="selected-count"><%= length(@selected) %> batches selected</span>
        <button class="btn btn-outline" phx-click="bulk_retry">
          Retry Selected
        </button>
      </div>
    <% end %>
    """
  end

  defp batches_table(assigns) do
    ~H"""
    <div class="batches-table">
      <%= if @batches == [] do %>
        <div class="empty-state">
          <p>No batches found matching your criteria.</p>
        </div>
      <% else %>
        <table class="table">
          <thead>
            <tr>
              <th><input type="checkbox" /></th>
              <th>
                <.sortable_header 
                  label="Batch" 
                  sort_by={:batch_number} 
                  current_sort={@sort_by} 
                  sort_order={@sort_order} 
                />
              </th>
              <th>Session</th>
              <th>
                <.sortable_header 
                  label="Status" 
                  sort_by={:status} 
                  current_sort={@sort_by} 
                  sort_order={@sort_order} 
                />
              </th>
              <th>
                <.sortable_header 
                  label="Records" 
                  sort_by={:record_count} 
                  current_sort={@sort_by} 
                  sort_order={@sort_order} 
                />
              </th>
              <th>
                <.sortable_header 
                  label="Success Rate" 
                  sort_by={:success_rate} 
                  current_sort={@sort_by} 
                  sort_order={@sort_order} 
                />
              </th>
              <th>
                <.sortable_header 
                  label="Duration" 
                  sort_by={:processing_time} 
                  current_sort={@sort_by} 
                  sort_order={@sort_order} 
                />
              </th>
              <th>
                <.sortable_header 
                  label="Started" 
                  sort_by={:inserted_at} 
                  current_sort={@sort_by} 
                  sort_order={@sort_order} 
                />
              </th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for batch <- @batches do %>
              <tr class="batch-row">
                <td>
                  <input 
                    type="checkbox" 
                    phx-click="select_batch"
                    phx-value-id={batch.id}
                    checked={batch.id in @selected}
                  />
                </td>
                <td>
                  <.link navigate={"/sync/batches/#{batch.id}"} class="batch-link">
                    #<%= batch.batch_number %>
                  </.link>
                </td>
                <td>
                  <.link navigate={"/sync/sessions/#{batch.session_id}"} class="session-link">
                    <%= batch.session_name || "Session #{batch.session_id}" %>
                  </.link>
                </td>
                <td><.status_badge status={batch.status} /></td>
                <td>
                  <div class="record-count">
                    <span class="count-number"><%= batch.record_count %></span>
                    <%= if batch.failed_count > 0 do %>
                      <span class="failed-count">(<%= batch.failed_count %> failed)</span>
                    <% end %>
                  </div>
                </td>
                <td>
                  <.success_rate_display rate={batch.success_rate} />
                </td>
                <td><%= format_duration(batch.processing_time) %></td>
                <td><%= format_datetime(batch.inserted_at) %></td>
                <td>
                  <.batch_actions batch={batch} />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp sortable_header(assigns) do
    is_current = assigns.sort_by == assigns.current_sort
    sort_icon = cond do
      is_current and assigns.sort_order == :asc -> "↑"
      is_current and assigns.sort_order == :desc -> "↓"
      true -> ""
    end

    assigns = assign(assigns, :sort_icon, sort_icon)
    assigns = assign(assigns, :is_current, is_current)

    ~H"""
    <button 
      class={"sortable-header #{if @is_current, do: "active", else: ""}"} 
      phx-click="sort" 
      phx-value-sort_by={@sort_by}
    >
      <%= @label %> <span class="sort-icon"><%= @sort_icon %></span>
    </button>
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

  defp batch_actions(assigns) do
    ~H"""
    <div class="batch-actions">
      <.link navigate={"/sync/batches/#{@batch.id}"} class="btn btn-sm">
        View
      </.link>
      <%= if @batch.status == :failed do %>
        <button class="btn btn-sm btn-outline" phx-click="retry_batch" phx-value-id={@batch.id}>
          Retry
        </button>
      <% end %>
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

  defp pagination(assigns) do
    ~H"""
    <div class="pagination">
      <!-- TODO: Implement pagination controls -->
    </div>
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