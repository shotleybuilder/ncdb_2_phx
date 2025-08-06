defmodule NCDB2Phx.Live.SessionLive.New do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    socket =
      socket
      |> assign(:form, build_form())
      |> assign(:available_adapters, load_available_adapters())
      |> assign(:available_resources, load_available_resources())
      |> assign(:selected_adapter, nil)
      |> assign(:adapter_config, %{})
      |> assign(:validation_errors, %{})

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"session" => params}, socket) do
    form = build_form(params)
    
    socket =
      socket
      |> assign(:form, form)
      |> validate_configuration(params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_adapter", %{"adapter" => adapter_name}, socket) do
    adapter = find_adapter(socket.assigns.available_adapters, adapter_name)
    
    socket =
      socket
      |> assign(:selected_adapter, adapter)
      |> assign(:adapter_config, %{})
      |> update_form_with_adapter(adapter)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_session", %{"session" => params}, socket) do
    {:error, %Ecto.Changeset{} = changeset} = create_sync_session(params)
    socket =
      socket
      |> assign(:form, build_form(params, changeset))
      |> put_flash(:error, "Please fix the errors below")

    {:noreply, socket}
  end

  @impl true
  def handle_event("preview_config", %{"session" => params}, socket) do
    config = build_sync_config(params)
    
    socket =
      socket
      |> assign(:config_preview, config)
      |> assign(:show_preview, true)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="session-new">
      <.page_header />
      
      <.form for={@form} phx-change="validate" phx-submit="create_session" class="session-form">
        <div class="form-sections">
          <.basic_info_section form={@form} />
          
          <.source_configuration_section 
            form={@form}
            adapters={@available_adapters}
            selected_adapter={@selected_adapter}
            adapter_config={@adapter_config}
          />
          
          <.target_configuration_section 
            form={@form}
            resources={@available_resources}
          />
          
          <.processing_options_section form={@form} />
          
          <.scheduling_section form={@form} />
        </div>
        
        <div class="form-actions">
          <button type="button" class="btn btn-outline" phx-click="preview_config">
            Preview Configuration
          </button>
          
          <button type="submit" class="btn btn-primary">
            Create Session
          </button>
          
          <.link navigate="/sync/sessions" class="btn btn-secondary">
            Cancel
          </.link>
        </div>
      </.form>
      
      <%= if assigns[:show_preview] do %>
        <.config_preview config={@config_preview} />
      <% end %>
    </div>
    """
  end

  defp build_form(_params \\ %{}, _changeset \\ nil) do
    # TODO: Create proper form with changeset
    Phoenix.HTML.FormData.to_form(%{}, as: :session)
  end

  defp load_available_adapters do
    # TODO: Load from adapter registry
    [
      %{name: "Airtable", module: NCDB2Phx.Adapters.AirtableAdapter, type: :airtable},
      %{name: "CSV File", module: NCDB2Phx.Adapters.CSVAdapter, type: :csv},
      %{name: "REST API", module: NCDB2Phx.Adapters.APIAdapter, type: :api}
    ]
  end

  defp load_available_resources do
    # TODO: Load from Ash registry
    []
  end

  defp find_adapter(adapters, name) do
    Enum.find(adapters, &(&1.name == name))
  end

  defp validate_configuration(socket, _params) do
    # TODO: Implement configuration validation
    socket
  end

  defp update_form_with_adapter(socket, _adapter) do
    # TODO: Update form based on selected adapter
    socket
  end

  defp create_sync_session(_params) do
    # TODO: Create session using NCDB2Phx.create_sync_session/1
    {:error, %Ecto.Changeset{}}
  end

  defp build_sync_config(_params) do
    # TODO: Build configuration map
    %{}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <h1>Create New Sync Session</h1>
      <nav class="breadcrumb">
        <.link navigate="/sync/sessions">Sessions</.link>
        <span>/</span>
        <span>New</span>
      </nav>
    </div>
    """
  end

  defp basic_info_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Basic Information</h3>
      
      <div class="form-group">
        <label for="session_name">Session Name</label>
        <.input field={@form[:name]} placeholder="Enter session name" />
        <small>Optional: Provide a descriptive name for this sync session</small>
      </div>
      
      <div class="form-group">
        <label for="session_description">Description</label>
        <.input field={@form[:description]} type="textarea" placeholder="Describe the purpose of this sync" />
      </div>
    </div>
    """
  end

  defp source_configuration_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Source Configuration</h3>
      
      <div class="form-group">
        <label>Data Source Type</label>
        <div class="adapter-grid">
          <%= for adapter <- @adapters do %>
            <div class={"adapter-card #{if @selected_adapter == adapter, do: "selected", else: ""}"}>
              <button 
                type="button"
                class="adapter-button"
                phx-click="select_adapter"
                phx-value-adapter={adapter.name}
              >
                <div class="adapter-icon">
                  <.adapter_icon type={adapter.type} />
                </div>
                <div class="adapter-name"><%= adapter.name %></div>
              </button>
            </div>
          <% end %>
        </div>
      </div>
      
      <%= if @selected_adapter do %>
        <.adapter_config_form adapter={@selected_adapter} config={@adapter_config} />
      <% end %>
    </div>
    """
  end

  defp target_configuration_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Target Configuration</h3>
      
      <div class="form-group">
        <label for="target_resource">Target Resource</label>
        <.input field={@form[:target_resource]} type="select" options={build_resource_options(@resources)} />
        <small>Select the Ash resource where data will be imported</small>
      </div>
      
      <div class="form-group">
        <label for="unique_field">Unique Field</label>
        <.input field={@form[:unique_field]} placeholder="e.g., email, external_id" />
        <small>Field used to identify existing records for updates</small>
      </div>
      
      <div class="form-group">
        <label>Import Strategy</label>
        <.input field={@form[:import_strategy]} type="select" options={[
          {"Create new records only", "create"},
          {"Update existing records only", "update"},
          {"Create or update (upsert)", "upsert"}
        ]} />
      </div>
    </div>
    """
  end

  defp processing_options_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Processing Options</h3>
      
      <div class="form-row">
        <div class="form-group">
          <label for="batch_size">Batch Size</label>
          <.input field={@form[:batch_size]} type="number" value="100" min="1" max="1000" />
          <small>Number of records processed per batch</small>
        </div>
        
        <div class="form-group">
          <label for="limit">Record Limit</label>
          <.input field={@form[:limit]} type="number" placeholder="No limit" min="1" />
          <small>Maximum records to process (optional)</small>
        </div>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input field={@form[:enable_progress_tracking]} type="checkbox" checked />
          Enable real-time progress tracking
        </label>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input field={@form[:enable_error_recovery]} type="checkbox" checked />
          Enable error recovery and retry
        </label>
      </div>
    </div>
    """
  end

  defp scheduling_section(assigns) do
    ~H"""
    <div class="form-section">
      <h3>Scheduling</h3>
      
      <div class="form-group">
        <label>Run Schedule</label>
        <.input field={@form[:schedule]} type="select" options={[
          {"Run immediately", "immediate"},
          {"Schedule for later", "scheduled"}
        ]} />
      </div>
      
      <div class="form-group conditional" data-show-when="schedule=scheduled">
        <label for="scheduled_at">Scheduled Time</label>
        <.input field={@form[:scheduled_at]} type="datetime-local" />
      </div>
    </div>
    """
  end

  defp adapter_config_form(assigns) do
    ~H"""
    <div class="adapter-config">
      <%= case @adapter.type do %>
        <% :airtable -> %>
          <.airtable_config_form config={@config} />
        <% :csv -> %>
          <.csv_config_form config={@config} />
        <% :api -> %>
          <.api_config_form config={@config} />
        <% _ -> %>
          <p>Configuration form for <%= @adapter.name %> not yet implemented.</p>
      <% end %>
    </div>
    """
  end

  defp airtable_config_form(assigns) do
    ~H"""
    <div class="adapter-specific-config">
      <div class="form-group">
        <label>API Key</label>
        <.input name="adapter_config[api_key]" type="password" placeholder="Enter Airtable API key" />
      </div>
      
      <div class="form-group">
        <label>Base ID</label>
        <.input name="adapter_config[base_id]" placeholder="app..." />
      </div>
      
      <div class="form-group">
        <label>Table Name</label>
        <.input name="adapter_config[table_name]" placeholder="Table name" />
      </div>
    </div>
    """
  end

  defp csv_config_form(assigns) do
    ~H"""
    <div class="adapter-specific-config">
      <div class="form-group">
        <label>CSV File</label>
        <.input name="adapter_config[file_path]" type="file" accept=".csv" />
      </div>
      
      <div class="form-group">
        <label>Delimiter</label>
        <.input name="adapter_config[delimiter]" value="," />
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input name="adapter_config[has_headers]" type="checkbox" checked />
          File has headers
        </label>
      </div>
    </div>
    """
  end

  defp api_config_form(assigns) do
    ~H"""
    <div class="adapter-specific-config">
      <div class="form-group">
        <label>API Endpoint</label>
        <.input name="adapter_config[endpoint_url]" placeholder="https://api.example.com/data" />
      </div>
      
      <div class="form-group">
        <label>Authentication</label>
        <.input name="adapter_config[auth_header]" placeholder="Bearer token or API key" />
      </div>
    </div>
    """
  end

  defp config_preview(assigns) do
    ~H"""
    <div class="config-preview">
      <h3>Configuration Preview</h3>
      <pre><%= inspect(@config, pretty: true) %></pre>
    </div>
    """
  end

  defp adapter_icon(assigns) do
    icon_class = case assigns.type do
      :airtable -> "icon-airtable"
      :csv -> "icon-csv"
      :api -> "icon-api"
      _ -> "icon-default"
    end

    assigns = assign(assigns, :icon_class, icon_class)

    ~H"""
    <div class={@icon_class}></div>
    """
  end

  defp build_resource_options(resources) do
    Enum.map(resources, &{&1.name, &1.module})
  end
end