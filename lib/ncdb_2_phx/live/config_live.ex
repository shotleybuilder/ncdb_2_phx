defmodule NCDB2Phx.Live.ConfigLive do
  use NCDB2Phx.Live.BaseSyncLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket} = super(_params, _session, socket)

    socket =
      socket
      |> assign(:current_config, load_current_config())
      |> assign(:adapter_registry, load_adapter_registry())
      |> assign(:default_settings, load_default_settings())
      |> assign(:monitoring_settings, load_monitoring_settings())
      |> assign(:active_tab, :general)
      |> assign(:config_form, build_config_form())
      |> assign(:unsaved_changes, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_atom(tab))}
  end

  @impl true
  def handle_event("update_config", %{"config" => config_params}, socket) do
    case update_configuration(config_params) do
      {:ok, updated_config} ->
        socket =
          socket
          |> assign(:current_config, updated_config)
          |> assign(:unsaved_changes, false)
          |> put_flash(:info, "Configuration updated successfully")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> assign(:config_form, changeset)
          |> put_flash(:error, "Please fix the errors below")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate_config", %{"config" => config_params}, socket) do
    form = validate_config_form(config_params)
    
    socket =
      socket
      |> assign(:config_form, form)
      |> assign(:unsaved_changes, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_config", _params, socket) do
    socket =
      socket
      |> assign(:config_form, build_config_form())
      |> assign(:unsaved_changes, false)
      |> put_flash(:info, "Configuration reset to current values")

    {:noreply, socket}
  end

  @impl true
  def handle_event("export_config", _params, socket) do
    # TODO: Implement configuration export
    {:noreply, put_flash(socket, :info, "Export functionality coming soon")}
  end

  @impl true
  def handle_event("import_config", _params, socket) do
    # TODO: Implement configuration import
    {:noreply, put_flash(socket, :info, "Import functionality coming soon")}
  end

  @impl true
  def handle_event("test_adapter", %{"adapter" => adapter_name}, socket) do
    case test_adapter_connection(adapter_name) do
      {:ok, result} ->
        {:noreply, put_flash(socket, :info, "Adapter test successful: #{result.message}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Adapter test failed: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="config-page">
      <.page_header unsaved_changes={@unsaved_changes} />
      
      <.config_tabs active_tab={@active_tab} />
      
      <div class="config-content">
        <.form for={@config_form} phx-change="validate_config" phx-submit="update_config">
          <%= case @active_tab do %>
            <% :general -> %>
              <.general_settings_tab form={@config_form} config={@current_config} />
            <% :adapters -> %>
              <.adapter_settings_tab 
                form={@config_form} 
                registry={@adapter_registry}
                config={@current_config}
              />
            <% :defaults -> %>
              <.default_settings_tab form={@config_form} defaults={@default_settings} />
            <% :monitoring -> %>
              <.monitoring_settings_tab form={@config_form} settings={@monitoring_settings} />
            <% :advanced -> %>
              <.advanced_settings_tab form={@config_form} config={@current_config} />
          <% end %>
          
          <.config_actions unsaved_changes={@unsaved_changes} />
        </.form>
      </div>
    </div>
    """
  end

  defp load_current_config do
    # TODO: Load from application configuration or database
    %{
      default_batch_size: 100,
      max_concurrent_sessions: 5,
      default_timeout: 30000,
      enable_progress_tracking: true,
      enable_error_recovery: true,
      log_level: :info,
      pubsub_module: NCDB2Phx.PubSub
    }
  end

  defp load_adapter_registry do
    # TODO: Load registered adapters
    [
      %{
        name: "Airtable",
        module: NCDB2Phx.Adapters.AirtableAdapter,
        enabled: true,
        status: :available
      },
      %{
        name: "CSV",
        module: NCDB2Phx.Adapters.CSVAdapter,
        enabled: true,
        status: :available
      },
      %{
        name: "API",
        module: NCDB2Phx.Adapters.APIAdapter,
        enabled: false,
        status: :unavailable
      }
    ]
  end

  defp load_default_settings do
    # TODO: Load default processing settings
    %{
      batch_size: 100,
      timeout: 30000,
      retry_attempts: 3,
      retry_delay: 5000,
      enable_progress_tracking: true,
      enable_error_recovery: true
    }
  end

  defp load_monitoring_settings do
    # TODO: Load monitoring configuration
    %{
      enable_metrics: true,
      metrics_interval: 1000,
      enable_alerts: true,
      alert_thresholds: %{
        error_rate: 0.1,
        memory_usage: 90,
        processing_time: 300
      }
    }
  end

  defp build_config_form do
    # TODO: Build proper form with changeset
    Phoenix.HTML.FormData.to_form(%{}, as: :config)
  end

  defp validate_config_form(_params) do
    # TODO: Validate configuration parameters
    build_config_form()
  end

  defp update_configuration(_params) do
    # TODO: Update application configuration
    {:error, %Ecto.Changeset{}}
  end

  defp test_adapter_connection(_adapter_name) do
    # TODO: Test adapter connectivity
    {:error, "Not implemented"}
  end

  defp page_header(assigns) do
    ~H"""
    <div class="page-header">
      <div class="header-left">
        <h1>Configuration</h1>
        <p class="page-description">
          Manage global sync settings, adapters, and system preferences
        </p>
      </div>
      
      <div class="header-right">
        <%= if @unsaved_changes do %>
          <span class="unsaved-indicator">Unsaved Changes</span>
        <% end %>
        
        <button class="btn btn-outline" phx-click="export_config">
          Export Config
        </button>
        
        <button class="btn btn-outline" phx-click="import_config">
          Import Config
        </button>
      </div>
    </div>
    """
  end

  defp config_tabs(assigns) do
    ~H"""
    <div class="config-tabs">
      <.tab_button tab={:general} active_tab={@active_tab} label="General" />
      <.tab_button tab={:adapters} active_tab={@active_tab} label="Adapters" />
      <.tab_button tab={:defaults} active_tab={@active_tab} label="Defaults" />
      <.tab_button tab={:monitoring} active_tab={@active_tab} label="Monitoring" />
      <.tab_button tab={:advanced} active_tab={@active_tab} label="Advanced" />
    </div>
    """
  end

  defp tab_button(assigns) do
    active_class = if assigns.tab == assigns.active_tab, do: "active", else: ""
    assigns = assign(assigns, :active_class, active_class)

    ~H"""
    <button 
      class={"tab-button #{@active_class}"} 
      phx-click="switch_tab" 
      phx-value-tab={@tab}
    >
      <%= @label %>
    </button>
    """
  end

  defp general_settings_tab(assigns) do
    ~H"""
    <div class="config-section">
      <h3>General Settings</h3>
      
      <div class="form-group">
        <label for="default_batch_size">Default Batch Size</label>
        <.input 
          field={@form[:default_batch_size]} 
          type="number" 
          value={@config.default_batch_size}
          min="1" 
          max="1000"
        />
        <small>Default number of records to process per batch</small>
      </div>
      
      <div class="form-group">
        <label for="max_concurrent_sessions">Max Concurrent Sessions</label>
        <.input 
          field={@form[:max_concurrent_sessions]} 
          type="number" 
          value={@config.max_concurrent_sessions}
          min="1" 
          max="20"
        />
        <small>Maximum number of sync sessions that can run simultaneously</small>
      </div>
      
      <div class="form-group">
        <label for="default_timeout">Default Timeout (ms)</label>
        <.input 
          field={@form[:default_timeout]} 
          type="number" 
          value={@config.default_timeout}
          min="1000" 
          step="1000"
        />
        <small>Default timeout for sync operations in milliseconds</small>
      </div>
      
      <div class="form-group">
        <label for="log_level">Log Level</label>
        <.input 
          field={@form[:log_level]} 
          type="select" 
          value={@config.log_level}
          options={[
            {"Debug", :debug},
            {"Info", :info},
            {"Warning", :warn},
            {"Error", :error}
          ]}
        />
        <small>Minimum log level for sync operations</small>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input 
            field={@form[:enable_progress_tracking]} 
            type="checkbox" 
            checked={@config.enable_progress_tracking}
          />
          Enable progress tracking by default
        </label>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input 
            field={@form[:enable_error_recovery]} 
            type="checkbox" 
            checked={@config.enable_error_recovery}
          />
          Enable error recovery by default
        </label>
      </div>
    </div>
    """
  end

  defp adapter_settings_tab(assigns) do
    ~H"""
    <div class="config-section">
      <h3>Adapter Management</h3>
      
      <div class="adapter-registry">
        <%= for adapter <- @registry do %>
          <.adapter_card adapter={adapter} form={@form} />
        <% end %>
      </div>
      
      <div class="adapter-actions">
        <button class="btn btn-outline">
          Register New Adapter
        </button>
      </div>
    </div>
    """
  end

  defp default_settings_tab(assigns) do
    ~H"""
    <div class="config-section">
      <h3>Default Processing Settings</h3>
      <p class="section-description">
        These settings will be used as defaults when creating new sync sessions
      </p>
      
      <div class="form-row">
        <div class="form-group">
          <label for="default_batch_size">Batch Size</label>
          <.input 
            field={@form[:defaults_batch_size]} 
            type="number" 
            value={@defaults.batch_size}
            min="1" 
            max="1000"
          />
        </div>
        
        <div class="form-group">
          <label for="default_timeout">Timeout (ms)</label>
          <.input 
            field={@form[:defaults_timeout]} 
            type="number" 
            value={@defaults.timeout}
            min="1000"
          />
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="retry_attempts">Retry Attempts</label>
          <.input 
            field={@form[:defaults_retry_attempts]} 
            type="number" 
            value={@defaults.retry_attempts}
            min="0" 
            max="10"
          />
        </div>
        
        <div class="form-group">
          <label for="retry_delay">Retry Delay (ms)</label>
          <.input 
            field={@form[:defaults_retry_delay]} 
            type="number" 
            value={@defaults.retry_delay}
            min="1000"
          />
        </div>
      </div>
      
      <div class="form-group">
        <h4>Default Features</h4>
        <label class="checkbox-label">
          <.input 
            field={@form[:defaults_enable_progress_tracking]} 
            type="checkbox" 
            checked={@defaults.enable_progress_tracking}
          />
          Enable progress tracking
        </label>
        
        <label class="checkbox-label">
          <.input 
            field={@form[:defaults_enable_error_recovery]} 
            type="checkbox" 
            checked={@defaults.enable_error_recovery}
          />
          Enable error recovery
        </label>
      </div>
    </div>
    """
  end

  defp monitoring_settings_tab(assigns) do
    ~H"""
    <div class="config-section">
      <h3>Monitoring & Alerting</h3>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input 
            field={@form[:monitoring_enable_metrics]} 
            type="checkbox" 
            checked={@settings.enable_metrics}
          />
          Enable system metrics collection
        </label>
      </div>
      
      <div class="form-group">
        <label for="metrics_interval">Metrics Collection Interval (ms)</label>
        <.input 
          field={@form[:monitoring_metrics_interval]} 
          type="number" 
          value={@settings.metrics_interval}
          min="100" 
          max="60000"
        />
        <small>How often to collect performance metrics</small>
      </div>
      
      <div class="form-group">
        <label class="checkbox-label">
          <.input 
            field={@form[:monitoring_enable_alerts]} 
            type="checkbox" 
            checked={@settings.enable_alerts}
          />
          Enable system alerts
        </label>
      </div>
      
      <div class="alert-thresholds">
        <h4>Alert Thresholds</h4>
        
        <div class="form-row">
          <div class="form-group">
            <label for="alert_error_rate">Error Rate (%)</label>
            <.input 
              field={@form[:alert_error_rate]} 
              type="number" 
              value={@settings.alert_thresholds.error_rate * 100}
              min="0" 
              max="100" 
              step="0.1"
            />
          </div>
          
          <div class="form-group">
            <label for="alert_memory_usage">Memory Usage (%)</label>
            <.input 
              field={@form[:alert_memory_usage]} 
              type="number" 
              value={@settings.alert_thresholds.memory_usage}
              min="0" 
              max="100"
            />
          </div>
        </div>
        
        <div class="form-group">
          <label for="alert_processing_time">Max Processing Time (seconds)</label>
          <.input 
            field={@form[:alert_processing_time]} 
            type="number" 
            value={@settings.alert_thresholds.processing_time}
            min="10"
          />
        </div>
      </div>
    </div>
    """
  end

  defp advanced_settings_tab(assigns) do
    ~H"""
    <div class="config-section">
      <h3>Advanced Configuration</h3>
      
      <div class="form-group">
        <label for="pubsub_module">PubSub Module</label>
        <.input 
          field={@form[:pubsub_module]} 
          type="text" 
          value={@config.pubsub_module}
        />
        <small>Phoenix PubSub module for real-time updates</small>
      </div>
      
      <div class="form-group">
        <label for="raw_config">Raw Configuration</label>
        <.input 
          field={@form[:raw_config]} 
          type="textarea" 
          rows="20"
          value={format_raw_config(@config)}
        />
        <small>Advanced users: Edit raw configuration as Elixir terms</small>
      </div>
      
      <div class="danger-zone">
        <h4>Danger Zone</h4>
        <button class="btn btn-danger" phx-click="reset_all_config" data-confirm="Reset all configuration to defaults?">
          Reset All Configuration
        </button>
      </div>
    </div>
    """
  end

  defp adapter_card(assigns) do
    status_class = case assigns.adapter.status do
      :available -> "adapter-available"
      :unavailable -> "adapter-unavailable"
      :error -> "adapter-error"
    end

    assigns = assign(assigns, :status_class, status_class)

    ~H"""
    <div class={"adapter-card #{@status_class}"}>
      <div class="adapter-header">
        <h4><%= @adapter.name %></h4>
        <.adapter_status_badge status={@adapter.status} />
      </div>
      
      <div class="adapter-info">
        <div class="adapter-module">
          <strong>Module:</strong> <%= @adapter.module %>
        </div>
        
        <div class="adapter-controls">
          <label class="checkbox-label">
            <input 
              type="checkbox" 
              name={"adapter_enabled[#{@adapter.name}]"}
              checked={@adapter.enabled}
            />
            Enabled
          </label>
        </div>
      </div>
      
      <div class="adapter-actions">
        <button 
          class="btn btn-sm btn-outline" 
          phx-click="test_adapter" 
          phx-value-adapter={@adapter.name}
        >
          Test Connection
        </button>
        
        <button class="btn btn-sm btn-outline">
          Configure
        </button>
      </div>
    </div>
    """
  end

  defp config_actions(assigns) do
    ~H"""
    <div class="config-actions">
      <button type="submit" class="btn btn-primary" disabled={not @unsaved_changes}>
        Save Configuration
      </button>
      
      <button type="button" class="btn btn-secondary" phx-click="reset_config">
        Reset Changes
      </button>
    </div>
    """
  end

  defp adapter_status_badge(assigns) do
    badge_class = case assigns.status do
      :available -> "badge badge-success"
      :unavailable -> "badge badge-secondary"
      :error -> "badge badge-error"
    end

    badge_text = case assigns.status do
      :available -> "Available"
      :unavailable -> "Unavailable"
      :error -> "Error"
    end

    assigns = assign(assigns, :badge_class, badge_class)
    assigns = assign(assigns, :badge_text, badge_text)

    ~H"""
    <span class={@badge_class}><%= @badge_text %></span>
    """
  end

  defp format_raw_config(config) do
    # TODO: Format configuration as readable Elixir terms
    inspect(config, pretty: true)
  end
end