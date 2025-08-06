defmodule NCDB2Phx.Live.SessionLive.Index do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    socket =
      socket
      |> assign(:sessions, list_sessions())
      |> assign(:filters, %{status: :all, type: :all, date_range: :all})
      |> assign(:selected_sessions, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_filters(params)
      |> assign(:sessions, list_sessions_with_filters(socket.assigns.filters))

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = build_filters(filter_params)
    
    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:sessions, list_sessions_with_filters(filters))

    {:noreply, push_patch(socket, to: build_filter_path(filters))}
  end

  @impl true
  def handle_event("select_session", %{"id" => id}, socket) do
    selected = toggle_selected_session(socket.assigns.selected_sessions, id)
    {:noreply, assign(socket, :selected_sessions, selected)}
  end

  @impl true
  def handle_event("bulk_cancel", _params, socket) do
    # TODO: Implement bulk cancellation
    {:noreply, socket}
  end

  @impl true
  def handle_event("bulk_retry", _params, socket) do
    # TODO: Implement bulk retry
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="session-index">
      <.page_header />
      
      <.filter_section filters={@filters} />
      
      <.bulk_actions selected={@selected_sessions} />
      
      <.sessions_table sessions={@sessions} selected={@selected_sessions} />
      
      <.pagination />
    </div>
    """
  end

  defp list_sessions do
    # TODO: Load from NCDB2Phx.Resources.SyncSession with pagination
    []
  end

  defp list_sessions_with_filters(_filters) do
    # TODO: Implement filtering logic
    []
  end

  defp apply_filters(socket, params) do
    filters = %{
      status: Map.get(params, "status", :all),
      type: Map.get(params, "type", :all),
      date_range: Map.get(params, "date_range", :all)
    }
    assign(socket, :filters, filters)
  end

  defp build_filters(params) do
    %{
      status: atomize_filter(params["status"]),
      type: atomize_filter(params["type"]),
      date_range: atomize_filter(params["date_range"])
    }
  end

  defp atomize_filter(value) when is_binary(value), do: String.to_atom(value)
  defp atomize_filter(value), do: value

  defp build_filter_path(filters) do
    query_params = 
      filters
      |> Enum.reject(fn {_k, v} -> v == :all end)
      |> Enum.into(%{})

    if query_params == %{} do
      "/sessions"
    else
      "/sessions?" <> URI.encode_query(query_params)
    end
  end

  defp toggle_selected_session(selected, id) do
    if id in selected do
      List.delete(selected, id)
    else
      [id | selected]
    end
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <h1>Sync Sessions</h1>
      <div class="page-actions">
        <.link navigate="/sync/sessions/new" class="btn btn-primary">
          New Session
        </.link>
      </div>
    </div>
    """
  end

  defp filter_section(assigns) do
    ~H"""
    <div class="filter-section">
      <form phx-change="filter">
        <div class="filter-group">
          <label>Status:</label>
          <select name="filter[status]">
            <option value="all" selected={@filters.status == :all}>All</option>
            <option value="pending" selected={@filters.status == :pending}>Pending</option>
            <option value="running" selected={@filters.status == :running}>Running</option>
            <option value="completed" selected={@filters.status == :completed}>Completed</option>
            <option value="failed" selected={@filters.status == :failed}>Failed</option>
            <option value="cancelled" selected={@filters.status == :cancelled}>Cancelled</option>
          </select>
        </div>
        
        <div class="filter-group">
          <label>Type:</label>
          <select name="filter[type]">
            <option value="all" selected={@filters.type == :all}>All</option>
            <option value="airtable" selected={@filters.type == :airtable}>Airtable</option>
            <option value="csv" selected={@filters.type == :csv}>CSV</option>
            <option value="api" selected={@filters.type == :api}>API</option>
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
        <span class="selected-count"><%= length(@selected) %> selected</span>
        <button class="btn btn-outline" phx-click="bulk_cancel">
          Cancel Selected
        </button>
        <button class="btn btn-outline" phx-click="bulk_retry">
          Retry Selected
        </button>
      </div>
    <% end %>
    """
  end

  defp sessions_table(assigns) do
    ~H"""
    <div class="sessions-table">
      <%= if @sessions == [] do %>
        <div class="empty-state">
          <p>No sessions found matching your criteria.</p>
        </div>
      <% else %>
        <table class="table">
          <thead>
            <tr>
              <th><input type="checkbox" /></th>
              <th>Name</th>
              <th>Type</th>
              <th>Status</th>
              <th>Progress</th>
              <th>Started</th>
              <th>Duration</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for session <- @sessions do %>
              <tr class="session-row">
                <td>
                  <input 
                    type="checkbox" 
                    phx-click="select_session"
                    phx-value-id={session.id}
                    checked={session.id in @selected}
                  />
                </td>
                <td>
                  <.link navigate={"/sync/sessions/#{session.id}"} class="session-link">
                    <%= session.name || "Session #{session.id}" %>
                  </.link>
                </td>
                <td><%= session.type %></td>
                <td><.status_badge status={session.status} /></td>
                <td><.progress_bar progress={session.progress || 0} /></td>
                <td><%= format_datetime(session.inserted_at) %></td>
                <td><%= calculate_duration(session) %></td>
                <td>
                  <.session_actions session={session} />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
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
    ~H"""
    <div class="progress-bar">
      <div class="progress-fill" style={"width: #{@progress}%"}></div>
      <span class="progress-text"><%= @progress %>%</span>
    </div>
    """
  end

  defp session_actions(assigns) do
    ~H"""
    <div class="session-actions">
      <.link navigate={"/sync/sessions/#{@session.id}"} class="btn btn-sm">
        View
      </.link>
      <%= if @session.status in [:pending, :failed] do %>
        <.link navigate={"/sync/sessions/#{@session.id}/edit"} class="btn btn-sm">
          Edit
        </.link>
      <% end %>
      <%= if @session.status == :running do %>
        <button class="btn btn-sm btn-warning" phx-click="cancel_session" phx-value-id={@session.id}>
          Cancel
        </button>
      <% end %>
    </div>
    """
  end

  defp pagination(assigns) do
    ~H"""
    <div class="pagination">
      <!-- TODO: Implement pagination controls -->
    </div>
    """
  end

  defp format_datetime(datetime) do
    # TODO: Implement datetime formatting
    to_string(datetime)
  end

  defp calculate_duration(_session) do
    # TODO: Calculate session duration
    "--"
  end
end