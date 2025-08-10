# Admin Interface Guide

This guide covers the comprehensive admin interface for NCDB2Phx, providing a complete web-based dashboard for managing and monitoring sync operations.

## Overview

The NCDB2Phx admin interface is a complete LiveView-based web application that provides:

- **Real-time Dashboard** with system health and sync overview
- **Session Management** for creating, monitoring, and managing sync operations  
- **Live Monitoring** with real-time progress tracking and performance metrics
- **Batch Analysis** for detailed batch-level performance and error analysis
- **Comprehensive Logging** with filtering, search, and live log streaming
- **Configuration Management** for system settings and adapter management
- **RESTful API** for programmatic access to all functionality

## Quick Setup

Get the admin interface running in 5 minutes:

### Step 1: Add Router Import

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  
  # Import NCDB2Phx router helpers
  import NCDB2Phx.Router
  
  # Your existing pipelines...
  pipeline :admin do
    plug :authenticate_admin  # Your admin authentication
  end
  
  # Mount the admin interface
  scope "/admin", MyAppWeb.Admin do
    pipe_through [:browser, :admin]
    ncdb_sync_routes "/sync"  # Single line = complete admin interface!
  end
end
```

### Step 2: Configure Available Resources

Configure which Ash resources can be used as sync targets:

```elixir
# config/config.exs
import NCDB2Phx.Config.ResourceConfig

config :ncdb_2_phx,
  available_resources: [
    resource("Users", MyApp.Accounts.User, "System user accounts"),
    resource("Cases", MyApp.Cases.Case, "Legal case records"),
    resource("Notices", MyApp.Notices.Notice, "Court notices and documents")
  ]

# Alternative: Auto-discover from domains
config :ncdb_2_phx,
  sync_domains: [MyApp.Accounts, MyApp.Cases, MyApp.Notices]
```

### Step 3: Access the Interface

Visit `http://localhost:4000/admin/sync` to access:
- Dashboard overview
- Session management with resource dropdown populated
- Real-time monitoring
- Log viewing
- System configuration

That's it! You now have a complete admin interface with working resource selection.

## Comprehensive Setup

### Router Configuration

The `ncdb_sync_routes` macro provides extensive customization options:

```elixir
# Basic setup
ncdb_sync_routes "/sync"

# Advanced setup with all options
ncdb_sync_routes "/sync",
  # Route customization
  as: :admin_sync,                    # Route helper prefix
  live_session_name: :admin_session,  # LiveView session name
  
  # Layout customization  
  root_layout: {MyAppWeb.Layouts, :admin},
  
  # Session arguments (passed to all LiveViews)
  session_args: %{
    "user_role" => "admin",
    "organization_id" => "current_org"
  },
  
  # Private router data
  private: %{
    authentication_required: true,
    audit_logging: true
  }
```

### Route Structure

The macro generates these routes automatically:

#### LiveView Routes
```elixir
# Dashboard
GET /sync                              → Dashboard overview
GET /sync/sessions                     → Session management index  
GET /sync/sessions/new                 → Create new session
GET /sync/sessions/:id                 → Session details
GET /sync/sessions/:id/edit            → Edit session configuration

# Monitoring  
GET /sync/monitor                      → System monitoring dashboard
GET /sync/monitor/:session_id          → Session-specific monitoring

# Batch management
GET /sync/batches                      → Batch index and filtering
GET /sync/batches/:id                  → Batch details and analysis

# Log management
GET /sync/logs                         → Comprehensive log viewer
GET /sync/logs/:session_id             → Session-specific logs

# Configuration
GET /sync/config                       → System configuration management
```

#### API Routes
```elixir
# Session management API
GET  /sync/api/sessions/:id/progress   → Real-time progress data
GET  /sync/api/sessions/:id/logs       → Session logs with pagination
POST /sync/api/sessions/:id/cancel     → Cancel running session
POST /sync/api/sessions/:id/retry      → Retry failed session
```

## Resource Configuration

The admin interface needs to know which Ash resources are available as sync targets. NCDB2Phx provides multiple flexible approaches to configure this.

### Configuration Approaches

#### 1. Simple List Configuration (Recommended)

The most straightforward approach using the helper module:

```elixir
# config/config.exs
import NCDB2Phx.Config.ResourceConfig

config :ncdb_2_phx,
  available_resources: [
    resource("Users", MyApp.Accounts.User, "System user accounts"),
    resource("Cases", MyApp.Cases.Case, "Legal case records"),
    resource("Notices", MyApp.Notices.Notice, "Court notices and documents"),
    resource("Companies", MyApp.Companies.Company)
  ]
```

This creates a dropdown in the admin interface with clear, descriptive names:
- "Users (Accounts.User) - System user accounts"
- "Cases (Cases.Case) - Legal case records"
- "Notices (Notices.Notice) - Court notices and documents"  
- "Companies (Companies.Company)"

#### 2. Domain-Based Discovery

Automatically discover resources from your Ash domains:

```elixir
# config/config.exs
config :ncdb_2_phx,
  sync_domains: [MyApp.Accounts, MyApp.Cases, MyApp.Notices]
```

This approach:
- Automatically finds all resources in the specified domains
- Uses the resource module name as the display name
- Perfect for when all domain resources should be available for sync
- Requires no maintenance when adding new resources

#### 3. Custom Provider Module

For complex scenarios, implement a custom resource provider:

```elixir
# config/config.exs  
config :ncdb_2_phx, 
  resource_provider: MyApp.SyncResourceProvider

# lib/my_app/sync_resource_provider.ex
defmodule MyApp.SyncResourceProvider do
  @behaviour NCDB2Phx.Utilities.ResourceProvider

  def get_available_resources do
    # Custom logic - maybe based on user permissions, feature flags, etc.
    base_resources = [
      %{name: "Users", module: MyApp.Accounts.User, description: "User accounts"},
      %{name: "Cases", module: MyApp.Cases.Case, description: "Legal cases"}
    ]
    
    if Application.get_env(:my_app, :enable_notice_sync, false) do
      [%{name: "Notices", module: MyApp.Notices.Notice} | base_resources]
    else
      base_resources
    end
  end
end
```

#### 4. Runtime Discovery (Fallback)

If no configuration is provided, NCDB2Phx automatically discovers all loaded Ash resources:

```elixir
# No configuration needed - automatic discovery
# This scans all loaded modules for Ash resources
```

**Note:** Automatic discovery works but may include resources you don't want to sync. Explicit configuration is recommended for production.

### Resource Configuration Options

When using the `resource/3-4` helper, you can specify:

```elixir
import NCDB2Phx.Config.ResourceConfig

resource(name, module, description \\ nil, opts \\ [])

# Examples:
resource("Users", MyApp.Accounts.User)
resource("Cases", MyApp.Cases.Case, "Legal case records")
resource("Notices", MyApp.Notices.Notice, "Court documents", 
  domain: MyApp.Legal,
  metadata: %{sync_frequency: :daily}
)
```

**Parameters:**
- `name` - Human-readable name displayed in the interface
- `module` - The Ash resource module  
- `description` - Optional description shown in dropdown
- `opts[:domain]` - Specify the domain (useful for organization)
- `opts[:metadata]` - Custom metadata for future extensibility

### Alternative Configuration Formats

NCDB2Phx accepts multiple configuration formats for flexibility:

```elixir
# Raw map format
config :ncdb_2_phx,
  available_resources: [
    %{name: "Users", module: MyApp.Accounts.User, description: "User accounts"},
    %{name: "Cases", module: MyApp.Cases.Case}
  ]

# Tuple format  
config :ncdb_2_phx,
  available_resources: [
    {"Users", MyApp.Accounts.User},
    {"Cases", MyApp.Cases.Case}
  ]

# Module-only format (names auto-generated)
config :ncdb_2_phx,
  available_resources: [
    MyApp.Accounts.User,
    MyApp.Cases.Case
  ]
```

### Troubleshooting Resource Configuration

#### Empty Dropdown

If the target resource dropdown is empty:

1. **Check Configuration**: Ensure you've added resource configuration to `config/config.exs`
2. **Verify Modules**: Ensure the resource modules are loaded and available
3. **Check Ash Resources**: Verify the modules are actual Ash resources with `YourModule.resource?()`
4. **Domain Loading**: If using domain discovery, ensure domains are loaded when the admin interface mounts

#### Debug Resource Discovery

Enable debug mode to see what resources are found:

```elixir
# In your LiveView mount or IEx
resources = NCDB2Phx.Utilities.ResourceProvider.get_available_resources()
IO.inspect(resources, label: "Available Resources")
```

#### Production Considerations

**Performance:**
- Resource discovery runs once per LiveView mount
- For frequently accessed admin interfaces, consider caching
- Domain discovery is fast but configuration lists are faster

**Security:**
- Only include resources that should be accessible via sync
- Consider implementing permission-based resource filtering
- Sensitive resources should not be included in sync configuration

**Maintenance:**  
- Configuration lists require manual updates when adding resources
- Domain discovery is automatic but includes all domain resources
- Custom providers offer the most control but require more code

## Interface Components

### Dashboard

The main dashboard provides a system overview:

**Features:**
- Active sessions with real-time status updates
- System health indicators (error rates, performance)  
- Recent activity feed
- Quick action buttons
- Sync statistics and charts

**Key Metrics:**
- Current sync operations
- Success/failure rates
- Performance trends
- Resource utilization

### Session Management

Comprehensive session lifecycle management:

**Session Index:**
- Paginated list of all sync sessions
- Advanced filtering by status, type, date range
- Bulk operations (cancel multiple, retry failed)
- Export session data

**Session Details:**
- Complete session metadata and configuration
- Real-time progress tracking with visual progress bars  
- Batch-by-batch breakdown with drill-down
- Error details with stack traces and context
- Performance metrics and timing analysis
- Session control actions (pause, resume, cancel)

**New Session Creation:**
- Dynamic form for configuring sync operations
- Source adapter selection and configuration  
- Target resource selection and mapping
- Processing options (batch size, limits, filters)
- Schedule sync or run immediately
- Configuration validation and preview

### Live Monitoring

Real-time system and session monitoring:

**System Monitor:**
- Live dashboard showing all active syncs
- Real-time progress bars and performance metrics
- Performance charts (records/sec, error rates)
- Resource utilization monitoring (CPU, memory)
- Alert notifications for failures
- System load indicators

**Session Monitor:**  
- Detailed monitoring for individual sessions
- Real-time batch progress visualization
- Performance metrics over time
- Error tracking and alerting
- Resource usage specific to session

### Batch Management

Detailed batch-level analysis:

**Batch Index:**
- List batches across all sessions
- Filter by status, session, date range
- Performance comparison between batches
- Batch retry functionality

**Batch Details:**
- Individual batch analysis
- Record-level processing results  
- Error analysis for failed records
- Performance metrics and optimization insights

### Log Management

Comprehensive logging with advanced features:

**Log Viewer:**
- Real-time log streaming with live updates
- Log level filtering (error, warn, info, debug)
- Full-text search functionality
- Export logs in multiple formats
- Timeline view of session events

**Session Logs:**
- Session-specific log filtering
- Contextual log organization  
- Error highlighting and grouping
- Performance correlation with log events

### Configuration Management

System-wide configuration interface:

**Global Settings:**
- Default sync parameters
- System performance tuning
- Error handling configuration
- Monitoring and alerting settings

**Adapter Management:**
- Registered adapter overview
- Adapter configuration and testing
- Connection validation
- Adapter performance metrics

## Authentication Integration

The admin interface integrates seamlessly with your application's authentication:

### Basic Authentication

```elixir
# Simple role-based access
pipeline :admin do
  plug MyApp.Auth.RequireAdmin
end

scope "/admin" do
  pipe_through [:browser, :admin] 
  ncdb_sync_routes "/sync"
end
```

### Advanced Authentication

```elixir
# Granular permission control
pipeline :sync_admin do
  plug MyApp.Auth.RequireUser
  plug MyApp.Auth.RequirePermissions, [:sync_admin, :sync_monitor]
  plug MyApp.Auth.LoadSyncPermissions
end

scope "/admin" do
  pipe_through [:browser, :sync_admin]
  ncdb_sync_routes "/sync",
    session_args: %{
      "current_user_id" => "user_context",
      "sync_permissions" => "user_sync_permissions"
    }
end
```

### Custom Authentication

```elixir
defmodule MyApp.SyncAuth do
  def require_sync_access(conn, _opts) do
    case get_current_user(conn) do
      %{role: role} when role in [:admin, :sync_manager] ->
        assign(conn, :sync_permissions, get_user_sync_permissions(conn))
      _ ->
        conn |> put_flash(:error, "Access denied") |> redirect(to: "/")
    end
  end
end

# In router
pipeline :sync_access do
  plug MyApp.SyncAuth, :require_sync_access
end
```

## Customization

### Layout Customization

Override the default layouts:

```elixir
# Use your application's admin layout
ncdb_sync_routes "/sync",
  root_layout: {MyAppWeb.Layouts, :admin}
```

Custom admin layout example:

```elixir
# lib/my_app_web/components/layouts/admin.html.heex
<html>
  <head>
    <title>My App Admin - <%= assigns[:page_title] || "Sync Management" %></title>
    <link rel="stylesheet" href="/assets/admin.css">
  </head>
  <body>
    <nav class="admin-nav">
      <!-- Your admin navigation -->
    </nav>
    
    <main class="admin-content">
      <%= @inner_content %>
    </main>
  </body>
</html>
```

### Styling and Themes

The admin interface follows a **semantic CSS class** approach - the package provides meaningful class names and minimal base styling, while you control all visual design.

**📖 For complete styling documentation, see: [Styling Guide](styling.md)**

#### Quick Start Styling

The interface provides these key CSS classes:

```css
/* Layout Components */
.sync-dashboard              /* Main dashboard container */
.dashboard-grid             /* Dashboard content grid */
.sync-navbar                /* Navigation bar */
.sync-main-content          /* Main content area */

/* Session Components */
.session-card               /* Individual session cards */
.session-status--running    /* Running session state */
.session-status--error      /* Error session state */
.session-status--completed  /* Completed session state */

/* Progress Components */
.progress-bar               /* Progress bar container */
.progress-fill              /* Progress bar fill */
.progress-text              /* Progress percentage text */

/* Monitoring Components */
.metric-card                /* System metric displays */
.monitor-dashboard          /* Monitoring interface */
.session-monitor-card       /* Individual session monitors */

/* Log Components */
.log-entry                  /* Individual log entries */
.log-error                  /* Error level logs */
.log-warning                /* Warning level logs */
.log-info                   /* Info level logs */

/* Form Components */
.form-input                 /* Form input fields */
.form-label                 /* Form labels */
.btn                        /* Button base class */
.btn-primary                /* Primary buttons */
.btn-outline                /* Outline buttons */
```

#### Framework Examples

**Tailwind CSS:**
```css
.session-card {
  @apply bg-white rounded-lg shadow-sm border border-gray-200 p-6 
         hover:shadow-md transition-shadow;
}

.session-status--running {
  @apply bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium;
}

.progress-bar {
  @apply w-full bg-gray-200 rounded-full h-2;
}

.progress-fill {
  @apply bg-blue-600 h-2 rounded-full transition-all duration-300;
}
```

**Bootstrap Integration:**
```css
.session-card {
  @extend .card;
  margin-bottom: 1rem;
}

.session-status--running {
  @extend .badge;
  @extend .badge-success;
}

.metric-card {
  @extend .card;
  @extend .text-center;
}

.log-entry.log-error {
  @extend .list-group-item-danger;
}
```

**Custom Brand Theme:**
```css
:root {
  --sync-primary: #your-brand-primary;
  --sync-success: #28a745;
  --sync-warning: #ffc107;
  --sync-error: #dc3545;
}

.sync-dashboard {
  font-family: 'Your Brand Font', sans-serif;
  background: var(--your-brand-bg);
}

.session-card {
  background: white;
  border: 1px solid var(--your-brand-border);
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.session-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.btn-primary {
  background: var(--sync-primary);
  border: 1px solid var(--sync-primary);
  color: white;
  font-weight: 600;
}
```

### Component Overrides

Override specific LiveView components:

```elixir
# Create custom components
defmodule MyAppWeb.SyncComponents do
  use Phoenix.Component
  
  # Override default dashboard
  def custom_dashboard(assigns) do
    ~H"""
    <div class="my-custom-dashboard">
      <!-- Your custom dashboard layout -->
    </div>
    """
  end
end
```

## API Integration

The admin interface exposes a comprehensive REST API for programmatic access:

### Progress Tracking

```bash
# Get real-time session progress
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/admin/sync/api/sessions/123/progress"

# Response
{
  "session_id": "123",
  "status": "running", 
  "progress": {
    "percentage": 65,
    "current_batch": 7,
    "total_batches": 10,
    "processed_records": 3250,
    "total_records": 5000
  },
  "metrics": {
    "records_per_second": 125,
    "estimated_time_remaining": 180
  }
}
```

### Session Control

```bash
# Cancel a running session
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/admin/sync/api/sessions/123/cancel"

# Retry a failed session  
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/admin/sync/api/sessions/123/retry"
```

### Log Access

```bash
# Get session logs with filtering
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4000/admin/sync/api/sessions/123/logs?level=error&limit=50"

# Response
{
  "logs": [
    {
      "id": "log_1",
      "level": "error",
      "message": "Failed to process record",
      "timestamp": "2025-08-06T10:30:00Z",
      "context": {"record_id": "rec_123"}
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "has_more": true
  }
}
```

## Real-time Features

### WebSocket Integration

The admin interface uses Phoenix LiveView for real-time updates:

**Automatic Features:**
- Live progress bars during sync operations
- Real-time status updates across all components
- Live log streaming with filtering
- Performance metrics updates
- System health monitoring

**Custom Integration:**

```elixir
# Subscribe to custom sync events in your LiveViews
def mount(_params, _session, socket) do
  if connected?(socket) do
    # Subscribe to custom sync events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "custom_sync_events")
  end
  {:ok, socket}
end

def handle_info({:custom_sync_event, data}, socket) do
  # Handle custom real-time updates
  {:noreply, update_custom_display(socket, data)}
end
```

### Event Publishing

Publish custom events to the admin interface:

```elixir
# From your sync operations
Phoenix.PubSub.broadcast(MyApp.PubSub, "sync_progress", {
  :sync_progress,
  %{
    session_id: session_id,
    progress_percentage: 75,
    status: :running,
    custom_metrics: %{your_data: "here"}
  }
})
```

## Performance and Scaling

### Optimization Tips

**Large Dataset Handling:**
- The interface automatically handles large sync operations
- Progress updates are throttled to prevent UI flooding
- Log streaming uses pagination and filtering
- Batch analysis includes memory-efficient processing

**Multi-user Access:**
- LiveView automatically handles multiple concurrent users
- Real-time updates are broadcast to all connected sessions
- User-specific permissions are enforced per session

**Database Performance:**
- The interface includes query optimization for large log tables  
- Automatic data retention policies
- Indexed columns for efficient filtering

### Production Deployment

**Requirements:**
- Phoenix LiveView ~> 1.0
- Phoenix PubSub configured
- Database with sync tracking tables
- Web server with WebSocket support

**Recommended Setup:**

```elixir
# config/prod.exs
config :my_app, MyAppWeb.Endpoint,
  # WebSocket support for LiveView
  websocket: [timeout: 45_000],
  
  # LiveView configuration
  live_view: [
    signing_salt: "your-salt-here"
  ]

# PubSub for real-time updates  
config :my_app, MyApp.PubSub,
  name: MyApp.PubSub,
  adapter: Phoenix.PubSub.PG2
```

## Troubleshooting

### Common Issues

**1. Routes Not Found**
```
** (UndefinedFunctionError) function NCDB2Phx.Router.ncdb_sync_routes/2 is undefined
```
**Solution:** Ensure you've added `import NCDB2Phx.Router` to your router module.

**2. LiveView Not Loading**
```
LiveView session timed out or was never connected
```
**Solution:** 
- Verify Phoenix LiveView is configured correctly
- Check PubSub is running: `Process.whereis(MyApp.PubSub)`
- Ensure WebSocket connections are allowed

**3. Authentication Issues**
```
Access denied to sync admin interface
```
**Solution:**
- Verify authentication pipeline is correctly configured
- Check user has required permissions
- Review session_args configuration

**4. Real-time Updates Not Working**
```
Progress bars not updating, logs not streaming
```  
**Solution:**
- Verify PubSub module name in configuration
- Check network allows WebSocket connections  
- Review browser console for JavaScript errors

### Debug Mode

Enable debug mode for troubleshooting:

```elixir
# In your router
ncdb_sync_routes "/sync",
  session_args: %{"debug_mode" => true},
  private: %{enable_debug_logging: true}
```

This enables:
- Detailed logging of LiveView events
- Configuration validation messages
- Performance timing information
- WebSocket connection diagnostics

### Health Checks

Monitor admin interface health:

```elixir
# Add to your health check endpoint
def sync_admin_health do
  %{
    liveview_working: liveview_functional?(),
    pubsub_connected: pubsub_healthy?(),
    database_responsive: database_responsive?(),
    websockets_enabled: websockets_working?()
  }
end
```

## Advanced Features

### Custom Dashboards

Create specialized dashboards for specific sync types:

```elixir
# Custom LiveView for specific sync monitoring
defmodule MyAppWeb.CustomSyncDashboard do
  use NCDB2Phx.Live.BaseSyncLive
  
  def mount(_params, _session, socket) do
    {:ok, socket} = super(_params, _session, socket)
    
    socket = assign(socket, :custom_metrics, load_custom_metrics())
    {:ok, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div class="custom-sync-dashboard">
      <!-- Your specialized dashboard -->
    </div>
    """
  end
end
```

### Integration with External Systems

Connect the admin interface to external monitoring:

```elixir
defmodule MyApp.SyncMonitoring do
  # Send metrics to external systems
  def handle_sync_event({:sync_progress, data}) do
    # Send to Datadog, New Relic, etc.
    send_to_monitoring_system(data)
    
    # Send to Slack, email, etc.
    send_notifications_if_needed(data)
  end
end
```

### Multi-tenant Support

Configure for multi-tenant applications:

```elixir
# Tenant-specific routing
scope "/:tenant/admin" do
  pipe_through [:browser, :load_tenant, :admin]
  
  ncdb_sync_routes "/sync",
    session_args: %{"tenant_id" => "current_tenant"},
    private: %{tenant_scoped: true}
end
```

## Support and Resources

### Documentation
- [Installation Guide](installation.md) - Setup and configuration
- [Quickstart Guide](quickstart.md) - Getting started quickly
- [Configuration Guide](configuration.md) - Advanced configuration options
- [Styling Guide](styling.md) - Complete CSS class reference and theming examples
- [API Documentation](https://hexdocs.pm/ncdb_2_phx) - Complete API reference

### Community
- [GitHub Repository](https://github.com/shotleybuilder/ncdb_2_phx) - Source code and updates
- [GitHub Issues](https://github.com/shotleybuilder/ncdb_2_phx/issues) - Bug reports and feature requests  
- [GitHub Discussions](https://github.com/shotleybuilder/ncdb_2_phx/discussions) - Questions and community help

### Examples
- [Example Applications](https://github.com/shotleybuilder/ncdb_2_phx/tree/main/examples) - Complete working examples
- [Integration Patterns](https://github.com/shotleybuilder/ncdb_2_phx/wiki) - Common integration patterns

The NCDB2Phx admin interface provides a complete, production-ready solution for managing sync operations in your Phoenix application. With real-time monitoring, comprehensive management tools, and extensive customization options, it scales from simple sync operations to complex, multi-tenant, high-volume sync systems.