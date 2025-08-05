# Quickstart Guide

This guide will get you syncing data from Airtable to your Phoenix application in under 10 minutes.

## Prerequisites

Before starting, ensure you have:

- ✅ Completed the [Installation Guide](installation.md)
- ✅ An Airtable account with a base containing data
- ✅ An Airtable API key ([Get yours here](https://airtable.com/create/tokens))
- ✅ At least one Ash resource defined in your application

## Step 1: Get Your Airtable Information

First, gather the required information from your Airtable base:

### Find Your Base ID

1. Open your Airtable base
2. Go to Help > API Documentation
3. Your base ID starts with `app` (e.g., `appXXXXXXXXXXXXXX`)

### Find Your Table ID

1. In the API documentation, select your table
2. Your table ID starts with `tbl` (e.g., `tblXXXXXXXXXXXXXX`)

### Create an API Token

1. Go to [Airtable Tokens](https://airtable.com/create/tokens)
2. Create a new token with access to your base
3. Your token starts with `pat` (e.g., `patXXXXXXXXXXXXXX`)

## Step 2: Set Environment Variables

Add your Airtable credentials to your environment:

```bash
# .env (development)
export AIRTABLE_API_KEY="patXXXXXXXXXXXXXX"
export AIRTABLE_BASE_ID="appXXXXXXXXXXXXXX"
export AIRTABLE_TABLE_ID="tblXXXXXXXXXXXXXX"
```

For production, set these in your deployment environment.

## Step 3: Create Your First Sync

Let's sync data from your Airtable table to an existing Ash resource. For this example, we'll assume you have a `User` resource.

Create a sync module:

```elixir
# lib/my_app/syncs/user_sync.ex
defmodule MyApp.Syncs.UserSync do
  @moduledoc """
  Sync users from Airtable to the local database.
  """
  
  def sync_users_from_airtable(opts \\ []) do
    config = %{
      # Source: Airtable
      source_adapter: AirtableSyncPhoenix.Adapters.AirtableAdapter,
      source_config: %{
        api_key: System.get_env("AIRTABLE_API_KEY"),
        base_id: System.get_env("AIRTABLE_BASE_ID"),
        table_id: System.get_env("AIRTABLE_TABLE_ID")
      },
      
      # Target: Your Ash resource
      target_resource: MyApp.Accounts.User,  # Replace with your actual resource
      target_config: %{
        unique_field: :email,  # Field to check for duplicates
        create_action: :create,
        update_action: :update
      },
      
      # Processing settings
      processing_config: %{
        batch_size: 50,         # Start small for testing
        limit: 100,             # Limit for testing
        enable_error_recovery: true,
        enable_progress_tracking: true
      },
      
      # Real-time updates
      pubsub_config: %{
        module: MyApp.PubSub,   # Replace with your PubSub module
        topic: "user_sync_progress"
      },
      
      # Session info
      session_config: %{
        sync_type: :import_users,
        description: "Import users from Airtable"
      }
    }
    
    # Get actor if needed (for Ash policies)
    actor = Keyword.get(opts, :actor)
    
    # Execute the sync
    case AirtableSyncPhoenix.execute_sync(config, actor: actor) do
      {:ok, result} ->
        IO.puts("✅ Sync completed successfully!")
        IO.puts("📊 Stats: #{result.records_processed} processed, #{result.records_created} created, #{result.records_updated} updated")
        {:ok, result}
        
      {:error, reason} ->
        IO.puts("❌ Sync failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
```

## Step 4: Run Your First Sync

Test your sync in IEx:

```bash
iex -S mix
```

```elixir
# Run the sync
iex> MyApp.Syncs.UserSync.sync_users_from_airtable()

# You should see output like:
# ✅ Sync completed successfully!
# 📊 Stats: 25 processed, 20 created, 5 updated
```

## Step 5: Add Field Mapping (If Needed)

If your Airtable fields don't match your Ash resource attributes exactly, add field mapping:

```elixir
# In your sync config, add record transformation
processing_config: %{
  batch_size: 50,
  limit: 100,
  enable_error_recovery: true,
  
  # Add field mapping
  record_transformer: fn airtable_record, _target_resource, _config ->
    # Transform Airtable fields to match your resource
    {:ok, %{
      name: airtable_record.data["Full Name"],        # Map "Full Name" to :name
      email: airtable_record.data["Email Address"],   # Map "Email Address" to :email
      phone: airtable_record.data["Phone Number"],    # Map "Phone Number" to :phone
      status: String.downcase(airtable_record.data["Status"] || "active"),
      created_from_sync: true,                        # Add computed fields
      external_id: airtable_record.source_record_id   # Store Airtable record ID
    }}
  end
}
```

## Step 6: Monitor Sync Progress (Optional)

Add real-time monitoring to see sync progress:

```elixir
# lib/my_app_web/live/sync_monitor_live.ex
defmodule MyAppWeb.SyncMonitorLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    # Subscribe to sync progress events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "user_sync_progress")
    
    {:ok, assign(socket, 
      progress: 0, 
      status: :idle, 
      stats: %{processed: 0, created: 0, updated: 0, errors: 0}
    )}
  end
  
  def handle_info({:sync_progress, progress_data}, socket) do
    {:noreply, assign(socket,
      progress: progress_data.progress_percentage,
      status: progress_data.status,
      stats: progress_data.stats
    )}
  end
  
  def handle_event("start_sync", _params, socket) do
    # Start sync in background
    Task.start(fn -> 
      MyApp.Syncs.UserSync.sync_users_from_airtable()
    end)
    
    {:noreply, assign(socket, status: :starting)}
  end
  
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-6">
      <h1 class="text-2xl font-bold mb-4">User Sync Monitor</h1>
      
      <div class="mb-4">
        <div class="flex justify-between mb-2">
          <span>Progress</span>
          <span><%= @progress %>%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div class="bg-blue-600 h-2 rounded-full" style={"width: #{@progress}%"}></div>
        </div>
      </div>
      
      <div class="grid grid-cols-2 gap-4 mb-4">
        <div class="text-center">
          <div class="text-2xl font-bold text-green-600"><%= @stats.created %></div>
          <div class="text-sm text-gray-600">Created</div>
        </div>
        <div class="text-center">
          <div class="text-2xl font-bold text-blue-600"><%= @stats.updated %></div>
          <div class="text-sm text-gray-600">Updated</div>
        </div>
      </div>
      
      <button 
        phx-click="start_sync" 
        class="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        disabled={@status in [:starting, :running]}
      >
        <%= if @status in [:starting, :running], do: "Syncing...", else: "Start Sync" %>
      </button>
    </div>
    """
  end
end
```

Add the route:

```elixir
# lib/my_app_web/router.ex
live "/sync-monitor", SyncMonitorLive
```

## Step 7: Handle Common Data Types

### Dates and Times

```elixir
# In your record transformer
record_transformer: fn airtable_record, _target_resource, _config ->
  {:ok, %{
    name: airtable_record.data["Name"],
    
    # Handle Airtable date format
    birth_date: case airtable_record.data["Birth Date"] do
      nil -> nil
      date_string -> Date.from_iso8601!(date_string)
    end,
    
    # Handle Airtable datetime format  
    created_at: case airtable_record.data["Created"] do
      nil -> DateTime.utc_now()
      datetime_string -> DateTime.from_iso8601!(datetime_string)
    end
  }}
end
```

### Multiple Select Fields

```elixir
# Handle Airtable multiple select fields (arrays)
tags: case airtable_record.data["Tags"] do
  nil -> []
  tags when is_list(tags) -> tags
  tag_string when is_binary(tag_string) -> [tag_string]
end
```

### Linked Records

```elixir
# Handle Airtable linked records (references to other tables)
category_id: case airtable_record.data["Category"] do
  [category_airtable_id | _] -> 
    # Look up the local category by its Airtable ID
    find_local_category_id(category_airtable_id)
  _ -> nil
end
```

## Step 8: Error Handling

Add robust error handling to your sync:

```elixir
def sync_users_with_error_handling(opts \\ []) do
  config = build_sync_config()
  
  case AirtableSyncPhoenix.execute_sync(config, opts) do
    {:ok, %{status: :completed} = result} ->
      notify_sync_success(result)
      {:ok, result}
      
    {:ok, %{status: :completed_with_errors} = result} ->
      notify_sync_partial_success(result)
      {:ok, result}
      
    {:error, %{reason: :validation_failed} = error} ->
      Logger.error("Sync validation failed: #{inspect(error)}")
      notify_admin_of_sync_failure(error)
      {:error, error}
      
    {:error, %{reason: :source_unavailable} = error} ->
      Logger.error("Airtable unavailable: #{inspect(error)}")
      schedule_retry_later()
      {:error, error}
      
    {:error, reason} ->
      Logger.error("Unexpected sync failure: #{inspect(reason)}")
      {:error, reason}
  end
end

defp notify_sync_success(result) do
  # Send notification, log metrics, etc.
  Logger.info("User sync completed: #{result.records_processed} records processed")
end

defp schedule_retry_later do
  # Schedule a retry using Oban or similar
  # %{sync_type: :users} |> MyApp.SyncWorker.new(schedule_in: 300) |> Oban.insert()
end
```

## Step 9: Automate Syncs (Optional)

Set up automated syncing using Oban or similar:

```elixir
# lib/my_app/workers/user_sync_worker.ex
defmodule MyApp.Workers.UserSyncWorker do
  use Oban.Worker, queue: :sync
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"sync_type" => "users"}}) do
    case MyApp.Syncs.UserSync.sync_users_from_airtable() do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
```

Schedule regular syncs:

```elixir
# Schedule daily sync at 2 AM
%{sync_type: "users"}
|> MyApp.Workers.UserSyncWorker.new(schedule_in: next_2am())
|> Oban.insert()
```

## Troubleshooting

### Common Issues

**"Resource not found" error:**
- Ensure your target resource is properly defined and in your domain
- Check that migrations have been run

**"Invalid API key" error:**
- Verify your Airtable API key is correct
- Ensure the token has access to your base

**"Field not found" errors:**
- Check field names match exactly (case-sensitive)
- Use field mapping in record transformer

**Timeout errors:**
- Reduce batch size
- Increase timeout in processing config

### Debug Mode

Enable detailed logging for troubleshooting:

```elixir
config = %{
  # ... your existing config
  processing_config: %{
    batch_size: 10,  # Smaller batches for debugging
    enable_detailed_logging: true,
    debug_mode: true
  }
}
```

## Next Steps

Now that you have a working sync:

1. **Scale Up**: Increase batch size and remove limits for production use
2. **Add More Resources**: Create syncs for other Airtable tables
3. **Custom Adapters**: Build adapters for other data sources ([Adapter Guide](adapters.md))
4. **Advanced Configuration**: Fine-tune performance and error handling ([Configuration Guide](configuration.md))
5. **Scheduling**: Set up automated syncs with Oban or cron jobs
6. **Monitoring**: Add comprehensive monitoring and alerting

## Success Checklist

- [ ] Gathered Airtable API credentials
- [ ] Set environment variables
- [ ] Created sync module
- [ ] Ran successful test sync
- [ ] Added field mapping (if needed)
- [ ] Set up progress monitoring (optional)
- [ ] Added error handling
- [ ] Tested with real data
- [ ] Ready for production use!

## Support

Having issues? Check out:

- [Configuration Guide](configuration.md) for advanced settings
- [Adapter Guide](adapters.md) for custom data sources
- [GitHub Issues](https://github.com/your-org/airtable_sync_phoenix/issues) for bug reports
- [GitHub Discussions](https://github.com/your-org/airtable_sync_phoenix/discussions) for questions

Congratulations! You now have AirtableSyncPhoenix working in your application. 🎉