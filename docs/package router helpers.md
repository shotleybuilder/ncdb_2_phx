# NCDB2Phx Router Helpers Specification

This document specifies the router functionality needed for the NCDB2Phx package to provide seamless Phoenix application integration with sync administration interfaces.

## Overview

The router helpers should enable host applications to easily mount comprehensive sync administration interfaces with a single macro call, following Phoenix conventions and integrating with existing authentication/authorization pipelines.

## Module: `NCDB2Phx.Router`

### Core Module Structure

```elixir
defmodule NCDB2Phx.Router do
  @moduledoc """
  Router helpers for integrating NCDB2Phx sync administration into Phoenix applications.
  
  This module provides macro helpers to easily mount sync admin routes in host applications
  with proper authentication and authorization pipelines.
  
  ## Usage
  
      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import NCDB2Phx.Router
        
        pipeline :admin do
          plug :authenticate_admin
          plug :require_sync_permissions
        end
        
        scope "/admin", MyAppWeb.Admin do
          pipe_through [:browser, :admin]
          ncdb_sync_routes "/sync"
        end
      end
  """
  
  @doc """
  Mounts NCDB2Phx sync administration routes at the given path.
  
  ## Options
  
  * `:as` - Route helper prefix (default: :ncdb_sync)
  * `:live_session_name` - LiveView session name (default: :ncdb_sync_admin)  
  * `:root_layout` - Root layout for sync pages (default: host app layout)
  * `:session_args` - Additional session arguments for LiveView
  * `:private` - Private router data to assign
  
  ## Examples
  
      # Basic mounting
      ncdb_sync_routes "/sync"
      
      # With options
      ncdb_sync_routes "/sync", 
        as: :admin_sync,
        live_session_name: :admin_sync_session,
        root_layout: {MyAppWeb.Layouts, :admin}
  """
  defmacro ncdb_sync_routes(path, opts \\ [])
end
```

### Macro Implementation

The `ncdb_sync_routes` macro should expand to generate the following route structure:

```elixir
defmacro ncdb_sync_routes(path, opts) do
  quote do
    # Extract options with defaults
    as = Keyword.get(unquote(opts), :as, :ncdb_sync)
    live_session_name = Keyword.get(unquote(opts), :live_session_name, :ncdb_sync_admin)
    root_layout = Keyword.get(unquote(opts), :root_layout, {NCDB2Phx.Layouts, :root})
    session_args = Keyword.get(unquote(opts), :session_args, %{})
    
    # Generate LiveView session wrapper
    live_session live_session_name,
      on_mount: [{NCDB2Phx.Live.Hooks.AssignDefaults, session_args}],
      root_layout: root_layout do
      
      # Dashboard and overview routes
      live unquote(path), NCDB2Phx.Live.DashboardLive, :index, 
        as: String.to_atom("#{as}_dashboard")
      
      # Session management routes
      live "#{unquote(path)}/sessions", NCDB2Phx.Live.SessionLive.Index, :index,
        as: String.to_atom("#{as}_session_index")
      live "#{unquote(path)}/sessions/new", NCDB2Phx.Live.SessionLive.New, :new,
        as: String.to_atom("#{as}_session_new")
      live "#{unquote(path)}/sessions/:id", NCDB2Phx.Live.SessionLive.Show, :show,
        as: String.to_atom("#{as}_session_show")
      live "#{unquote(path)}/sessions/:id/edit", NCDB2Phx.Live.SessionLive.Edit, :edit,
        as: String.to_atom("#{as}_session_edit")
      
      # Real-time monitoring routes
      live "#{unquote(path)}/monitor", NCDB2Phx.Live.MonitorLive, :index,
        as: String.to_atom("#{as}_monitor")
      live "#{unquote(path)}/monitor/:session_id", NCDB2Phx.Live.MonitorLive.Session, :show,
        as: String.to_atom("#{as}_monitor_session")
      
      # Batch tracking routes
      live "#{unquote(path)}/batches", NCDB2Phx.Live.BatchLive.Index, :index,
        as: String.to_atom("#{as}_batch_index")
      live "#{unquote(path)}/batches/:id", NCDB2Phx.Live.BatchLive.Show, :show,
        as: String.to_atom("#{as}_batch_show")
      
      # Log viewing routes
      live "#{unquote(path)}/logs", NCDB2Phx.Live.LogLive.Index, :index,
        as: String.to_atom("#{as}_log_index")
      live "#{unquote(path)}/logs/:session_id", NCDB2Phx.Live.LogLive.Session, :session,
        as: String.to_atom("#{as}_log_session")
      
      # Configuration routes
      live "#{unquote(path)}/config", NCDB2Phx.Live.ConfigLive, :index,
        as: String.to_atom("#{as}_config")
    end
    
    # API endpoints for real-time data
    scope "#{unquote(path)}/api" do
      get "/sessions/:id/progress", NCDB2Phx.API.SessionController, :progress,
        as: String.to_atom("#{as}_api_session_progress")
      get "/sessions/:id/logs", NCDB2Phx.API.SessionController, :logs,
        as: String.to_atom("#{as}_api_session_logs")
      post "/sessions/:id/cancel", NCDB2Phx.API.SessionController, :cancel,
        as: String.to_atom("#{as}_api_session_cancel")
      post "/sessions/:id/retry", NCDB2Phx.API.SessionController, :retry,
        as: String.to_atom("#{as}_api_session_retry")
    end
  end
end
```

## Required LiveView Modules

### 1. Dashboard Interface

```elixir
defmodule NCDB2Phx.Live.DashboardLive do
  use NCDB2Phx.Live.BaseSyncLive
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign_dashboard_data()
     |> schedule_dashboard_refresh()}
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
  
  # Features to implement:
  # - Active sessions overview with real-time updates
  # - Recent sync activity feed
  # - System health indicators (error rates, performance metrics)
  # - Quick action buttons (start new sync, view logs, etc.)
  # - Sync statistics and charts
  # - Real-time updates via PubSub subscriptions
end
```

### 2. Session Management

```elixir
defmodule NCDB2Phx.Live.SessionLive.Index do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Paginated list of all sync sessions
  # - Advanced filtering (by status, type, date range, etc.)
  # - Bulk operations (cancel multiple, retry failed)
  # - Export session data
  # - Real-time status updates
end

defmodule NCDB2Phx.Live.SessionLive.Show do  
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Detailed session view with complete metadata
  # - Real-time progress tracking with visual progress bars
  # - Batch-by-batch breakdown with drill-down capability
  # - Error details with stack traces and context
  # - Performance metrics and timing analysis
  # - Session control actions (pause, resume, cancel)
  # - Export session report
end

defmodule NCDB2Phx.Live.SessionLive.New do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Dynamic form for configuring sync operations
  # - Source adapter selection and configuration
  # - Target resource selection and mapping
  # - Processing options (batch size, limits, filters)
  # - Schedule sync or run immediately
  # - Configuration validation and preview
end

defmodule NCDB2Phx.Live.SessionLive.Edit do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Modify session configuration for retry/resume
  # - Update processing parameters
  # - Change error handling behavior
end
```

### 3. Real-time Monitoring

```elixir
defmodule NCDB2Phx.Live.MonitorLive do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Live dashboard showing all active syncs
  # - Real-time progress bars and metrics
  # - Performance charts (records/sec, error rates)
  # - Resource utilization monitoring
  # - Alert notifications for failures
  # - System load indicators
end

defmodule NCDB2Phx.Live.MonitorLive.Session do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Detailed monitoring for single session
  # - Real-time batch progress visualization
  # - Performance metrics over time
  # - Error tracking and alerting
  # - Resource usage specific to session
end
```

### 4. Batch Management

```elixir
defmodule NCDB2Phx.Live.BatchLive.Index do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - List batches across all sessions
  # - Filter by status, session, date
  # - Performance comparison between batches
  # - Batch retry functionality
end

defmodule NCDB2Phx.Live.BatchLive.Show do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Individual batch details
  # - Record-level processing results
  # - Error analysis for failed records
  # - Batch performance metrics
end
```

### 5. Log Management

```elixir
defmodule NCDB2Phx.Live.LogLive.Index do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Comprehensive log viewing with filtering
  # - Log level filtering (error, warn, info, debug)
  # - Search functionality
  # - Export logs
  # - Real-time log streaming
end

defmodule NCDB2Phx.Live.LogLive.Session do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Session-specific log viewing
  # - Contextual log filtering
  # - Timeline view of session events
  # - Error highlighting and grouping
end
```

### 6. Configuration Management

```elixir
defmodule NCDB2Phx.Live.ConfigLive do
  use NCDB2Phx.Live.BaseSyncLive
  
  # Features:
  # - Global sync configuration management
  # - Adapter registration and configuration
  # - Default processing parameters
  # - System monitoring settings
  # - Export/import configuration
end
```

## Base LiveView Module

```elixir
defmodule NCDB2Phx.Live.BaseSyncLive do
  @moduledoc """
  Base LiveView for sync-related pages with common PubSub functionality and helpers.
  """
  
  defmacro __using__(opts) do
    quote do
      use Phoenix.LiveView, unquote(opts)
      
      @impl true
      def mount(params, session, socket) do
        if connected?(socket) do
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_progress")
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_sessions")
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_batches")
          Phoenix.PubSub.subscribe(pubsub_name(), "sync_logs")
        end
        
        {:ok, assign_sync_defaults(socket, params, session)}
      end
      
      @impl true  
      def handle_info({:sync_progress, %{session_id: session_id} = data}, socket) do
        {:noreply, update_session_progress(socket, session_id, data)}
      end
      
      def handle_info({:sync_session, %{event: event, session: session}}, socket) do
        {:noreply, handle_session_event(socket, event, session)}
      end
      
      def handle_info({:sync_batch, %{event: event, batch: batch}}, socket) do
        {:noreply, handle_batch_event(socket, event, batch)}
      end
      
      def handle_info({:sync_log, %{level: level, message: message, session_id: session_id}}, socket) do
        {:noreply, handle_log_event(socket, level, message, session_id)}
      end
      
      # Default implementations (can be overridden)
      defp assign_sync_defaults(socket, _params, _session) do
        assign(socket,
          page_title: "Sync Administration",
          active_sessions: [],
          sync_stats: %{},
          system_health: %{}
        )
      end
      
      defp update_session_progress(socket, session_id, data), do: socket
      defp handle_session_event(socket, event, session), do: socket
      defp handle_batch_event(socket, event, batch), do: socket  
      defp handle_log_event(socket, level, message, session_id), do: socket
      
      defp pubsub_name do
        Application.get_env(:ncdb_2_phx, :pubsub_name, NCDB2Phx.PubSub)
      end
      
      defoverridable [assign_sync_defaults: 3, update_session_progress: 3, 
                      handle_session_event: 3, handle_batch_event: 3, handle_log_event: 4]
    end
  end
end
```

## API Controller

```elixir
defmodule NCDB2Phx.API.SessionController do
  use Phoenix.Controller
  
  action_fallback NCDB2Phx.API.FallbackController
  
  def progress(conn, %{"id" => session_id}) do
    with {:ok, session} <- NCDB2Phx.get_sync_session(session_id),
         progress_data <- build_progress_response(session) do
      json(conn, progress_data)
    end
  end
  
  def logs(conn, %{"id" => session_id} = params) do
    with {:ok, logs} <- NCDB2Phx.list_session_logs(session_id, log_params(params)) do
      json(conn, %{logs: logs, pagination: build_pagination(logs)})
    end
  end
  
  def cancel(conn, %{"id" => session_id}) do
    with {:ok, session} <- NCDB2Phx.cancel_sync(session_id) do
      json(conn, %{status: "cancelled", session: session})
    end
  end
  
  def retry(conn, %{"id" => session_id}) do
    with {:ok, new_session} <- NCDB2Phx.retry_sync_session(session_id) do
      json(conn, %{status: "retrying", session: new_session})
    end
  end
  
  # Private helper functions
  defp build_progress_response(session), do: %{}
  defp log_params(params), do: %{}
  defp build_pagination(logs), do: %{}
end
```

## Configuration Support

The router should support application-level configuration:

```elixir
# config/config.exs
config :ncdb_2_phx, NCDB2Phx.Router,
  # Default authentication pipeline  
  auth_pipeline: [:authenticate_user, :require_admin],
  
  # Default layout for sync pages
  root_layout: {NCDB2Phx.Layouts, :root},
  
  # PubSub configuration for real-time updates
  pubsub_name: MyApp.PubSub,
  
  # Session configuration
  live_session: [
    session: %{},
    root_layout: {NCDB2Phx.Layouts, :root}
  ],
  
  # UI customization
  theme: [
    primary_color: "#0066cc",
    accent_color: "#28a745", 
    error_color: "#dc3545"
  ]
```

## Integration Examples

### Basic Integration

```elixir
# In host application router
defmodule EhsEnforcementWeb.Router do
  use Phoenix.Router
  import NCDB2Phx.Router
  
  pipeline :admin_required do
    plug EhsEnforcementWeb.Plugs.RequireAdmin
    plug EhsEnforcementWeb.Plugs.AssignCurrentUser  
  end
  
  scope "/admin", EhsEnforcementWeb.Admin do
    pipe_through [:browser, :admin_required]
    
    # Mount NCDB2Phx admin interface
    ncdb_sync_routes "/sync"
  end
end
```

### Advanced Integration with Custom Options

```elixir
defmodule EhsEnforcementWeb.Router do
  use Phoenix.Router
  import NCDB2Phx.Router
  
  scope "/admin", EhsEnforcementWeb.Admin do
    pipe_through [:browser, :admin_required]
    
    # Advanced mounting with custom options
    ncdb_sync_routes "/sync", 
      as: :admin_sync,
      live_session_name: :admin_sync_session,
      root_layout: {EhsEnforcementWeb.Layouts, :admin},
      session_args: %{
        "user_role" => "admin",
        "organization_id" => "current_org"
      },
      private: %{
        authentication_required: true,
        audit_logging: true
      }
  end
end
```

## Mount Hook for LiveView Sessions

```elixir
defmodule NCDB2Phx.Live.Hooks.AssignDefaults do
  @moduledoc """
  LiveView mount hook for assigning sync-related defaults to socket.
  """
  
  def on_mount(session_args, _params, session, socket) when is_map(session_args) do
    socket = 
      socket
      |> Phoenix.LiveView.assign(:sync_session_args, session_args)
      |> Phoenix.LiveView.assign(:pubsub_name, get_pubsub_name())
      |> Phoenix.LiveView.assign(:current_user, get_current_user(session))
      |> Phoenix.LiveView.assign(:sync_permissions, get_sync_permissions(session))
    
    {:cont, socket}
  end
  
  def on_mount(_session_args, _params, _session, socket) do
    {:cont, socket}
  end
  
  defp get_pubsub_name do
    Application.get_env(:ncdb_2_phx, NCDB2Phx.Router)[:pubsub_name] || NCDB2Phx.PubSub
  end
  
  defp get_current_user(session), do: Map.get(session, "current_user")
  defp get_sync_permissions(session), do: Map.get(session, "sync_permissions", [])
end
```

## Layouts Module

```elixir
defmodule NCDB2Phx.Layouts do
  @moduledoc """
  Default layouts for NCDB2Phx admin interface.
  """
  use Phoenix.Component
  
  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title><%= @page_title || "Sync Administration" %></title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/ncdb_sync.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/ncdb_sync.js"}></script>
      </head>
      <body>
        <div id="sync-admin-root">
          <.sync_navigation current_route={@current_route} />
          <main class="sync-main-content">
            <%= @inner_content %>
          </main>
        </div>
      </body>
    </html>
    """
  end
  
  defp sync_navigation(assigns) do
    ~H"""
    <nav class="sync-navbar">
      <div class="sync-navbar-brand">
        <h1>Sync Administration</h1>
      </div>
      <div class="sync-navbar-nav">
        <.nav_link href="/sync" current={@current_route}>Dashboard</.nav_link>
        <.nav_link href="/sync/sessions" current={@current_route}>Sessions</.nav_link>
        <.nav_link href="/sync/monitor" current={@current_route}>Monitor</.nav_link>
        <.nav_link href="/sync/logs" current={@current_route}>Logs</.nav_link>
        <.nav_link href="/sync/config" current={@current_route}>Config</.nav_link>
      </div>
    </nav>
    """
  end
end
```

## Summary

This specification provides a complete router integration system that enables:

1. **Easy Integration**: Single macro call to mount comprehensive admin interface
2. **Flexibility**: Extensive customization options for host applications
3. **Real-time Updates**: Built-in PubSub integration for live monitoring  
4. **Authentication**: Seamless integration with host app auth pipelines
5. **API Support**: RESTful endpoints for programmatic access
6. **Responsive UI**: Modern LiveView-based interface with real-time updates

The implementation would make NCDB2Phx truly plug-and-play for Phoenix applications while maintaining the flexibility needed for diverse hosting environments.