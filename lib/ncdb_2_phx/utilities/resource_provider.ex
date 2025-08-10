defmodule NCDB2Phx.Utilities.ResourceProvider do
  @moduledoc """
  Provides resource discovery and configuration for sync operations.
  
  This module offers multiple strategies to discover available Ash resources
  that can be used as sync targets, from simple configuration-based approaches
  to automatic runtime discovery.
  
  ## Configuration Approaches
  
  ### 1. Simple List Configuration (Recommended)
  
      # config/config.exs
      config :ncdb_2_phx,
        available_resources: [
          %{name: "Users", module: MyApp.Accounts.User, description: "User accounts"},
          %{name: "Cases", module: MyApp.Cases.Case, description: "Legal cases"},
          %{name: "Notices", module: MyApp.Notices.Notice, description: "Legal notices"}
        ]
  
  ### 2. Callback Module Configuration
  
      # config/config.exs
      config :ncdb_2_phx, resource_provider: MyApp.SyncResourceProvider
      
      # lib/my_app/sync_resource_provider.ex
      defmodule MyApp.SyncResourceProvider do
        @behaviour NCDB2Phx.Utilities.ResourceProvider
        
        def get_available_resources do
          [
            %{name: "Users", module: MyApp.Accounts.User, description: "User accounts"},
            %{name: "Cases", module: MyApp.Cases.Case, description: "Legal cases"}
          ]
        end
      end
  
  ### 3. Domain-Based Configuration
  
      # config/config.exs  
      config :ncdb_2_phx,
        sync_domains: [MyApp.Accounts, MyApp.Cases, MyApp.Notices]
  
  ### 4. Automatic Discovery (Fallback)
  
  If no configuration is provided, the system will attempt to discover
  all Ash resources from loaded domains automatically.
  """

  @type resource_info :: %{
    name: String.t(),
    module: module(),
    description: String.t() | nil,
    domain: module() | nil
  }

  @doc """
  Callback for custom resource providers.
  """
  @callback get_available_resources() :: [resource_info()]

  @doc """
  Gets all available resources for sync operations using the configured strategy.
  
  ## Examples
  
      iex> NCDB2Phx.Utilities.ResourceProvider.get_available_resources()
      [
        %{name: "Users", module: MyApp.Accounts.User, description: "User accounts"},
        %{name: "Cases", module: MyApp.Cases.Case, description: "Legal cases"}
      ]
  """
  @spec get_available_resources() :: [resource_info()]
  def get_available_resources do
    case get_resource_strategy() do
      {:config_list, resources} ->
        format_configured_resources(resources)

      {:callback_module, module} ->
        apply(module, :get_available_resources, [])

      {:domain_list, domains} ->
        load_resources_from_domains(domains)

      :auto_discovery ->
        discover_ash_resources()
    end
  end

  @doc """
  Builds resource options for form selects.
  
  ## Examples
  
      iex> NCDB2Phx.Utilities.ResourceProvider.build_resource_options()
      [{"Users (MyApp.Accounts.User)", "MyApp.Accounts.User"}, ...]
  """
  @spec build_resource_options() :: [{String.t(), String.t()}]
  def build_resource_options do
    get_available_resources()
    |> Enum.map(fn resource ->
      label = build_resource_label(resource)
      value = to_string(resource.module)
      {label, value}
    end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  # Private functions

  defp get_resource_strategy do
    cond do
      resources = Application.get_env(:ncdb_2_phx, :available_resources) ->
        {:config_list, resources}

      provider = Application.get_env(:ncdb_2_phx, :resource_provider) ->
        {:callback_module, provider}

      domains = Application.get_env(:ncdb_2_phx, :sync_domains) ->
        {:domain_list, domains}

      true ->
        :auto_discovery
    end
  end

  defp format_configured_resources(resources) do
    Enum.map(resources, fn
      %{} = resource ->
        %{
          name: Map.get(resource, :name, extract_resource_name(resource.module)),
          module: resource.module,
          description: Map.get(resource, :description),
          domain: Map.get(resource, :domain)
        }

      {name, module} when is_binary(name) and is_atom(module) ->
        %{
          name: name,
          module: module,
          description: nil,
          domain: nil
        }

      module when is_atom(module) ->
        %{
          name: extract_resource_name(module),
          module: module,
          description: nil,
          domain: nil
        }
    end)
  end

  defp load_resources_from_domains(domains) do
    domains
    |> Enum.flat_map(&get_domain_resources/1)
    |> Enum.map(fn {domain, resource} ->
      %{
        name: extract_resource_name(resource),
        module: resource,
        description: nil,
        domain: domain
      }
    end)
  end

  defp get_domain_resources(domain) do
    if function_exported?(domain, :__ash_resources__, 0) do
      domain.__ash_resources__()
      |> Enum.map(&{domain, &1})
    else
      []
    end
  rescue
    _ -> []
  end

  defp discover_ash_resources do
    :code.all_loaded()
    |> Enum.flat_map(fn {module, _} ->
      if function_exported?(module, :__ash_resources__, 0) do
        try do
          resources = module.__ash_resources__()
          Enum.map(resources, &{module, &1})
        rescue
          _ -> []
        end
      else
        []
      end
    end)
    |> Enum.uniq()
    |> Enum.map(fn {domain, resource} ->
      %{
        name: extract_resource_name(resource),
        module: resource,
        description: extract_resource_description(resource),
        domain: domain
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  defp extract_resource_name(module) when is_atom(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  defp extract_resource_description(resource) do
    if function_exported?(resource, :resource_description, 0) do
      apply(resource, :resource_description, [])
    else
      nil
    end
  rescue
    _ -> nil
  end

  defp build_resource_label(%{name: name, module: module, domain: domain}) do
    module_name = to_string(module) |> String.split(".") |> Enum.take(-2) |> Enum.join(".")
    
    case domain do
      nil -> "#{name} (#{module_name})"
      domain -> "#{name} (#{inspect(domain)} - #{module_name})"
    end
  end

  @doc """
  Validates if a resource module is available for sync operations.
  
  ## Examples
  
      iex> NCDB2Phx.Utilities.ResourceProvider.validate_resource(MyApp.Accounts.User)
      {:ok, %{name: "User", module: MyApp.Accounts.User, ...}}
      
      iex> NCDB2Phx.Utilities.ResourceProvider.validate_resource(InvalidModule)
      {:error, :resource_not_found}
  """
  @spec validate_resource(module() | String.t()) :: {:ok, resource_info()} | {:error, atom()}
  def validate_resource(module) when is_binary(module) do
    try do
      module
      |> String.to_existing_atom()
      |> validate_resource()
    rescue
      ArgumentError -> {:error, :invalid_module}
    end
  end

  def validate_resource(module) when is_atom(module) do
    case get_available_resources() |> Enum.find(&(&1.module == module)) do
      nil -> 
        if is_ash_resource?(module) do
          {:ok, %{
            name: extract_resource_name(module),
            module: module,
            description: extract_resource_description(module),
            domain: nil
          }}
        else
          {:error, :resource_not_found}
        end
      resource -> 
        {:ok, resource}
    end
  end

  defp is_ash_resource?(module) do
    Code.ensure_loaded?(module) and 
    function_exported?(module, :spark_dsl_config, 0) and
    function_exported?(module, :resource?, 0) and
    apply(module, :resource?, [])
  rescue
    _ -> false
  end

  @doc """
  Refreshes the resource cache (useful for development/testing).
  """
  @spec refresh_resources() :: :ok
  def refresh_resources do
    # In the future, if we add caching, this would clear it
    :ok
  end
end