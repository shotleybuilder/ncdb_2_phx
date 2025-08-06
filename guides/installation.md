# Installation Guide

This guide will walk you through installing and setting up NCDB2Phx in your Phoenix application using Ash Framework.

## Prerequisites

Before installing NCDB2Phx, ensure your application meets these requirements:

- **Elixir**: >= 1.16
- **Phoenix**: >= 1.7.0
- **Ash Framework**: >= 3.0.0
- **AshPostgres**: >= 2.0.0 (if using PostgreSQL)
- **AshPhoenix**: >= 2.0.0 (for LiveView components)

Your application should already be set up with:
- PostgreSQL database configured
- Ash domains and resources defined
- Phoenix PubSub configured

## Step 1: Add Dependency

Add `ncdb_2_phx` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    # Your existing dependencies
    {:phoenix, "~> 1.7.14"},
    {:ash, "~> 3.0"},
    {:ash_postgres, "~> 2.0"},
    {:ash_phoenix, "~> 2.0"},
    
    # Add NCDB2Phx
    {:ncdb_2_phx, "~> 0.2"}
  ]
end
```

Then fetch the dependency:

```bash
mix deps.get
```

## Step 2: Add Resources to Your Domain

You'll need to add the sync tracking resources to one of your Ash domains. Create a new domain or add to an existing one:

```elixir
# lib/my_app/sync.ex
defmodule MyApp.Sync do
  use Ash.Domain
  
  resources do
    # Add the sync tracking resources
    resource NCDB2Phx.Resources.SyncSession
    resource NCDB2Phx.Resources.SyncBatch
    resource NCDB2Phx.Resources.SyncLog
    
    # You can also add your own custom sync resources here
    # resource MyApp.Sync.CustomSyncConfig
  end
end
```

Alternative: If you prefer to keep sync resources in your main domain:

```elixir
# lib/my_app/application_domain.ex  
defmodule MyApp.ApplicationDomain do
  use Ash.Domain
  
  resources do
    # Your existing resources
    resource MyApp.Accounts.User
    resource MyApp.Products.Product
    
    # Add sync resources
    resource NCDB2Phx.Resources.SyncSession
    resource NCDB2Phx.Resources.SyncBatch
    resource NCDB2Phx.Resources.SyncLog
  end
end
```

## Step 3: Generate and Run Migrations

The sync resources require database tables. Generate the migrations:

```bash
# Generate Ash migrations for the sync resources
mix ash.codegen --check

# Apply the migrations
mix ash.migrate
```

You should see new migration files created for:
- `sync_sessions` table
- `sync_batches` table  
- `sync_logs` table

## Step 4: Add NCDB2Phx Supervisor (Optional)

NCDB2Phx provides an optional supervisor for its core services. Add it to your application's supervision tree if you need PubSub and HTTP client services:

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Your existing children...
      MyAppWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:my_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MyApp.PubSub},
      
      # Add NCDB2Phx supervisor (optional)
      NCDB2Phx.Application,
      
      # Or add services individually if you prefer more control:
      # {Phoenix.PubSub, name: NCDB2Phx.PubSub},
      # {Finch, name: NCDB2Phx.Finch},
      
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Note**: If you skip this step, you'll need to ensure PubSub is configured for real-time progress tracking.

## Step 5: Configuration

Add basic configuration to your application:

```elixir
# config/config.exs
config :ncdb_2_phx,
  # Default sync settings
  default_batch_size: 100,
  default_timeout: 30_000,
  
  # PubSub configuration (use your app's PubSub module)
  pubsub_module: MyApp.PubSub,
  default_progress_topic: "sync_progress",
  
  # Error handling
  enable_error_recovery: true,
  max_retries: 3,
  
  # Logging
  enable_detailed_logging: true

# Environment-specific configuration
```

```elixir
# config/dev.exs
config :ncdb_2_phx,
  default_batch_size: 50,      # Smaller batches for dev
  enable_detailed_logging: true

# config/prod.exs
config :ncdb_2_phx,
  default_batch_size: 500,     # Larger batches for production
  default_timeout: 60_000,     # Longer timeout
  enable_detailed_logging: false
```

## Step 6: Environment Variables

Set up environment variables for your data sources:

```bash
# .env (for development)
export AIRTABLE_API_KEY="keyXXXXXXXXXXXXXX"
export AIRTABLE_BASE_ID="appXXXXXXXXXXXXXX"

# For production, set these in your deployment environment
```

## Step 7: Verify Installation

Create a simple test to verify everything is working:

```elixir
# lib/my_app/sync_test.ex
defmodule MyApp.SyncTest do
  def test_installation do
    # Test that sync resources are available
    case NCDB2Phx.create_sync_session(%{
      session_id: "test_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      sync_type: :test,
      status: :pending
    }) do
      {:ok, session} ->
        IO.puts("✅ Installation successful! Created test session: #{session.session_id}")
        {:ok, session}
        
      {:error, error} ->
        IO.puts("❌ Installation issue: #{inspect(error)}")
        {:error, error}
    end
  end
end
```

Run the test in IEx:

```bash
iex -S mix
```

```elixir
iex> MyApp.SyncTest.test_installation()
```

You should see: `✅ Installation successful! Created test session: test_XXXXXXXX`

## Step 8: Add Admin Interface (Recommended)

NCDB2Phx provides a comprehensive web-based admin interface for managing and monitoring sync operations. Add it to your router:

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  
  # Import NCDB2Phx router helpers
  import NCDB2Phx.Router
  
  # Your existing pipelines...
  pipeline :admin do
    plug :authenticate_admin  # Add your admin authentication
    plug :require_sync_permissions  # Optional: granular permissions
  end
  
  # Mount the complete admin interface
  scope "/admin", MyAppWeb.Admin do
    pipe_through [:browser, :admin]
    
    # Single line = complete sync admin interface!
    ncdb_sync_routes "/sync"
  end
end
```

### Admin Interface Features

This creates a complete admin interface at `/admin/sync` with:

**Dashboard & Monitoring:**
- `/admin/sync` - Real-time dashboard with system overview
- `/admin/sync/monitor` - Live monitoring with performance metrics
- `/admin/sync/monitor/:session_id` - Session-specific monitoring

**Session Management:**
- `/admin/sync/sessions` - Comprehensive session management
- `/admin/sync/sessions/new` - Create and configure new syncs
- `/admin/sync/sessions/:id` - Detailed session view with real-time progress
- `/admin/sync/sessions/:id/edit` - Edit session configuration

**Analysis & Debugging:**
- `/admin/sync/batches` - Batch-level performance analysis
- `/admin/sync/batches/:id` - Detailed batch analysis with error breakdown
- `/admin/sync/logs` - Comprehensive log viewer with search and filtering
- `/admin/sync/logs/:session_id` - Session-specific logs with timeline view

**Configuration:**
- `/admin/sync/config` - System configuration management

**API Endpoints:**
- `/admin/sync/api/sessions/:id/progress` - Real-time progress data
- `/admin/sync/api/sessions/:id/logs` - Session logs with pagination
- `/admin/sync/api/sessions/:id/cancel` - Cancel running sessions
- `/admin/sync/api/sessions/:id/retry` - Retry failed sessions

### Advanced Router Configuration

For more control over the admin interface:

```elixir
# Advanced configuration with all options
ncdb_sync_routes "/sync",
  # Customize route helpers
  as: :admin_sync,
  
  # Custom LiveView session
  live_session_name: :admin_sync_session,
  
  # Use your admin layout
  root_layout: {MyAppWeb.Layouts, :admin},
  
  # Pass session context
  session_args: %{
    "user_role" => "admin",
    "organization_id" => "current_org_id"
  },
  
  # Private router data
  private: %{
    authentication_required: true,
    audit_logging: true
  }
```

### Authentication Integration

The admin interface integrates with your existing authentication:

#### Simple Role-Based Access
```elixir
pipeline :sync_admin do
  plug MyApp.Auth.RequireAdmin
end
```

#### Granular Permission Control
```elixir
pipeline :sync_admin do
  plug MyApp.Auth.RequireUser
  plug MyApp.Auth.RequirePermissions, [:sync_admin, :sync_monitor]
  plug MyApp.Auth.AssignSyncPermissions
end
```

#### Custom Authentication Logic
```elixir
defmodule MyApp.SyncAuth do
  def require_sync_access(conn, _opts) do
    case get_current_user(conn) do
      %{role: role} when role in [:admin, :sync_manager] ->
        assign(conn, :sync_permissions, get_user_sync_permissions(conn))
      _ ->
        conn 
        |> put_flash(:error, "Access denied") 
        |> redirect(to: "/")
    end
  end
end

# In your router pipeline
plug MyApp.SyncAuth, :require_sync_access
```

## Troubleshooting

### Migration Issues

If you encounter migration issues:

```bash
# Check what migrations are pending
mix ash.codegen --check

# If you need to reset and regenerate
mix ash.codegen --check --drop

# Apply migrations
mix ash.migrate
```

### Resource Not Found Errors

If you get "resource not found" errors, ensure:

1. You've added the sync resources to your domain
2. You've run the migrations
3. Your domain is properly configured in your application

### Compilation Errors

If you get compilation errors related to Ash queries, add to the files using queries:

```elixir
require Ash.Query
import Ash.Expr
```

### PubSub Configuration

If you encounter PubSub-related errors, verify your PubSub module name in config:

```elixir
# Verify your PubSub module name
config :ncdb_2_phx,
  pubsub_module: MyApp.PubSub  # Should match your app's PubSub module
```

## Next Steps

With NCDB2Phx installed, you're ready to:

1. [Follow the Quickstart Guide](quickstart.md) to set up your first sync
2. [Explore the Admin Interface](admin-interface.md) for web-based sync management
3. [Create Custom Adapters](adapters.md) for your data sources  
4. [Configure Advanced Settings](configuration.md)

## Installation Checklist

- [ ] Added dependency to `mix.exs` (~> 0.2)
- [ ] Ran `mix deps.get`
- [ ] Added sync resources to Ash domain
- [ ] Generated and ran migrations with `mix ash.codegen --check` and `mix ash.migrate`
- [ ] Added basic configuration
- [ ] Set environment variables
- [ ] Verified installation with test
- [ ] **Recommended:** Added admin interface with `ncdb_sync_routes`
- [ ] **Optional:** Configured authentication and permissions for admin interface
- [ ] Ready to create first sync!

## Support

If you encounter issues during installation:

1. Check the [Troubleshooting Section](#troubleshooting) above
2. Review the [Configuration Guide](configuration.md)
3. Open an issue on [GitHub](https://github.com/shotleybuilder/ncdb_2_phx/issues)
4. Join discussions on [GitHub Discussions](https://github.com/shotleybuilder/ncdb_2_phx/discussions)