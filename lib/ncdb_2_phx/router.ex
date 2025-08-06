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
  defmacro ncdb_sync_routes(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      # Extract options with defaults
      as = Keyword.get(opts, :as, :ncdb_sync)
      live_session_name = Keyword.get(opts, :live_session_name, :ncdb_sync_admin)
      root_layout = Keyword.get(opts, :root_layout, {NCDB2Phx.Layouts, :root})
      session_args = Keyword.get(opts, :session_args, %{})
      private_data = Keyword.get(opts, :private, %{})

      # Generate LiveView session wrapper
      live_session live_session_name,
        on_mount: [{NCDB2Phx.Live.Hooks.AssignDefaults, session_args}],
        root_layout: root_layout do
        
        # Dashboard and overview routes
        live path, NCDB2Phx.Live.DashboardLive, :index, 
          as: :"#{as}_dashboard",
          private: private_data
        
        # Session management routes
        live "#{path}/sessions", NCDB2Phx.Live.SessionLive.Index, :index,
          as: :"#{as}_session_index",
          private: private_data
        live "#{path}/sessions/new", NCDB2Phx.Live.SessionLive.New, :new,
          as: :"#{as}_session_new",
          private: private_data
        live "#{path}/sessions/:id", NCDB2Phx.Live.SessionLive.Show, :show,
          as: :"#{as}_session_show",
          private: private_data
        live "#{path}/sessions/:id/edit", NCDB2Phx.Live.SessionLive.Edit, :edit,
          as: :"#{as}_session_edit",
          private: private_data
        
        # Real-time monitoring routes
        live "#{path}/monitor", NCDB2Phx.Live.MonitorLive, :index,
          as: :"#{as}_monitor",
          private: private_data
        live "#{path}/monitor/:session_id", NCDB2Phx.Live.MonitorLive.Session, :show,
          as: :"#{as}_monitor_session",
          private: private_data
        
        # Batch tracking routes
        live "#{path}/batches", NCDB2Phx.Live.BatchLive.Index, :index,
          as: :"#{as}_batch_index",
          private: private_data
        live "#{path}/batches/:id", NCDB2Phx.Live.BatchLive.Show, :show,
          as: :"#{as}_batch_show",
          private: private_data
        
        # Log viewing routes
        live "#{path}/logs", NCDB2Phx.Live.LogLive.Index, :index,
          as: :"#{as}_log_index",
          private: private_data
        live "#{path}/logs/:session_id", NCDB2Phx.Live.LogLive.Session, :session,
          as: :"#{as}_log_session",
          private: private_data
        
        # Configuration routes
        live "#{path}/config", NCDB2Phx.Live.ConfigLive, :index,
          as: :"#{as}_config",
          private: private_data
      end
      
      # API endpoints for real-time data
      scope "#{path}/api", NCDB2Phx.API, as: as do
        get "/sessions/:id/progress", SessionController, :progress,
          as: :api_session_progress,
          private: private_data
        get "/sessions/:id/logs", SessionController, :logs,
          as: :api_session_logs,
          private: private_data
        post "/sessions/:id/cancel", SessionController, :cancel,
          as: :api_session_cancel,
          private: private_data
        post "/sessions/:id/retry", SessionController, :retry,
          as: :api_session_retry,
          private: private_data
      end
    end
  end
end