defmodule NCDB2Phx.Live.SessionLive.Edit do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {:ok, socket} = super(%{"id" => id}, session, socket)

    {:ok, session} = load_session(id)
    socket =
      socket
      |> assign(:session, session)
      |> assign(:form, build_form_from_session(session))
      |> assign(:validation_errors, %{})

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"session" => params}, socket) do
    form = update_form(socket.assigns.form, params)
    
    socket =
      socket
      |> assign(:form, form)
      |> validate_configuration(params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_session", %{"session" => params}, socket) do
    {:error, %Ecto.Changeset{} = changeset} = update_sync_session(socket.assigns.session.id, params)
    socket =
      socket
      |> assign(:form, build_form_from_changeset(changeset))
      |> put_flash(:error, "Please fix the errors below")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="session-edit">
      <.page_header session={@session} />
      
      <%= if @session.status not in [:pending, :failed, :cancelled] do %>
        <div class="alert alert-warning">
          <strong>Warning:</strong> This session is currently <%= @session.status %>.
          Some configuration options may not be editable.
        </div>
      <% end %>
      
      <.form for={@form} phx-change="validate" phx-submit="update_session" class="session-form">
        <div class="form-sections">
          <.basic_info_section form={@form} session={@session} />
          
          <.processing_options_section form={@form} session={@session} />
          
          <.error_handling_section form={@form} session={@session} />
          
          <%= if @session.status in [:failed, :cancelled] do %>
            <.retry_options_section form={@form} session={@session} />
          <% end %>
        </div>
        
        <div class="form-actions">
          <button type="submit" class="btn btn-primary">
            Update Session
          </button>
          
          <.link navigate={"/sync/sessions/#{@session.id}"} class="btn btn-secondary">
            Cancel
          </.link>
        </div>
      </.form>
    </div>
    """
  end

  defp load_session(id) do
    # TODO: Load from NCDB2Phx.Resources.SyncSession
    {:ok, %{
      id: id,
      name: "Test Session",
      status: :failed,
      config: %{},
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }}
  end

  defp build_form_from_session(_session) do
    # TODO: Build form from session data
    Phoenix.HTML.FormData.to_form(%{}, as: :session)
  end

  defp build_form_from_changeset(_changeset) do
    # TODO: Build form from changeset
    Phoenix.HTML.FormData.to_form(%{}, as: :session)
  end

  defp update_form(form, _params) do
    # TODO: Update form with new params
    form
  end

  defp validate_configuration(socket, _params) do
    # TODO: Validate configuration changes
    socket
  end

  defp update_sync_session(_id, _params) do
    # TODO: Update session using NCDB2Phx.update_sync_session/2
    {:error, %Ecto.Changeset{}}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <div class="header-left">
        <h1>Edit Session</h1>
        <nav class="breadcrumb">
          <.link navigate="/sync/sessions">Sessions</.link>
          <span>/</span>
          <.link navigate={"/sync/sessions/#{@session.id}"}><%= @session.name || "Session #{@session.id}" %></.link>
          <span>/</span>
          <span>Edit</span>
        </nav>
      </div>
    </div>
    """
  end

  defp basic_info_section(assigns) do
    editable = assigns.session.status in [:pending, :failed, :cancelled]
    assigns = assign(assigns, :editable, editable)

    ~H"""
    <div class="form-section">
      <h3>Basic Information</h3>
      
      <div class="form-group">
        <label for="session_name">Session Name</label>
        <.input field={@form[:name]} placeholder="Enter session name" disabled={not @editable} />
        <%= unless @editable do %>
          <small class="text-muted">Cannot edit name of active session</small>
        <% end %>
      </div>
      
      <div class="form-group">
        <label for="session_description">Description</label>
        <.input field={@form[:description]} type="textarea" disabled={not @editable} />
      </div>
      
      <div class="session-meta">
        <div class="meta-item">
          <label>Current Status:</label>
          <.status_badge status={@session.status} />
        </div>
        
        <div class="meta-item">
          <label>Session ID:</label>
          <span class="session-id"><%= @session.id %></span>
        </div>
        
        <div class="meta-item">
          <label>Created:</label>
          <span><%= format_datetime(@session.inserted_at) %></span>
        </div>
      </div>
    </div>
    """
  end

  defp processing_options_section(assigns) do
    editable = assigns.session.status in [:pending, :failed]
    assigns = assign(assigns, :editable, editable)

    ~H"""
    <div class="form-section">
      <h3>Processing Options</h3>
      
      <div class="form-row">
        <div class="form-group">
          <label for="batch_size">Batch Size</label>
          <.input field={@form[:batch_size]} type="number" min="1" max="1000" disabled={not @editable} />
          <%= unless @editable do %>
            <small class="text-muted">Cannot modify batch size of running session</small>
          <% end %>
        </div>
        
        <div class="form-group">
          <label for="limit">Record Limit</label>
          <.input field={@form[:limit]} type="number" min="1" disabled={not @editable} />
        </div>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input field={@form[:enable_progress_tracking]} type="checkbox" disabled={not @editable} />
          Enable real-time progress tracking
        </label>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input field={@form[:enable_error_recovery]} type="checkbox" />
          Enable error recovery and retry
        </label>
      </div>
    </div>
    """
  end

  defp error_handling_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Error Handling</h3>
      
      <div class="form-group">
        <label>On Error</label>
        <.input field={@form[:error_strategy]} type="select" options={[
          {"Stop processing", "stop"},
          {"Skip record and continue", "skip"},
          {"Retry with backoff", "retry"}
        ]} />
      </div>
      
      <div class="form-group">
        <label for="max_retries">Maximum Retries</label>
        <.input field={@form[:max_retries]} type="number" value="3" min="0" max="10" />
      </div>
      
      <div class="form-group">
        <label for="retry_delay">Retry Delay (seconds)</label>
        <.input field={@form[:retry_delay]} type="number" value="5" min="1" max="300" />
      </div>
    </div>
    """
  end

  defp retry_options_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Retry Options</h3>
      
      <div class="alert alert-info">
        This session <%= @session.status %>. You can configure retry behavior and restart the session.
      </div>
      
      <div class="form-group">
        <label>Retry Strategy</label>
        <.input field={@form[:retry_strategy]} type="select" options={[
          {"Retry from beginning", "restart"},
          {"Resume from last successful batch", "resume"},
          {"Retry failed records only", "failed_only"}
        ]} />
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input field={@form[:clear_previous_errors]} type="checkbox" />
          Clear previous error logs
        </label>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input field={@form[:update_config]} type="checkbox" />
          Update source configuration before retry
        </label>
      </div>
      
      <%= if @form[:retry_strategy].value == "resume" do %>
        <div class="form-group">
          <label>Resume from Batch</label>
          <.input field={@form[:resume_from_batch]} type="number" min="1" />
          <small>Specify batch number to resume from</small>
        </div>
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

  defp format_datetime(datetime) do
    # TODO: Implement proper datetime formatting
    to_string(datetime)
  end
end