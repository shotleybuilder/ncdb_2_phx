defmodule NCDB2Phx.Config.ResourceConfig do
  @moduledoc """
  Helper module for configuring sync resources in host applications.
  
  This module provides convenient functions to configure resources that can
  be used as sync targets in the NCDB2Phx admin interface.
  
  ## Usage
  
  In your application configuration:
  
      # config/config.exs
      import NCDB2Phx.Config.ResourceConfig
      
      config :ncdb_2_phx,
        available_resources: [
          resource("Users", MyApp.Accounts.User, "System user accounts"),
          resource("Cases", MyApp.Cases.Case, "Legal case records"),
          resource("Notices", MyApp.Notices.Notice)
        ]
  
  Or define all resources from specific domains:
  
      # config/config.exs  
      config :ncdb_2_phx,
        sync_domains: [MyApp.Accounts, MyApp.Cases]
  """

  @doc """
  Defines a resource configuration for sync operations.
  
  ## Parameters
  
  - `name` - Human-readable name for the resource (e.g., "User Accounts")
  - `module` - The Ash resource module (e.g., `MyApp.Accounts.User`)  
  - `description` - Optional description of what this resource contains
  - `opts` - Additional options (reserved for future use)
  
  ## Examples
  
      resource("Users", MyApp.Accounts.User, "System user accounts")
      
      resource("Cases", MyApp.Cases.Case)
      
      resource("Legal Notices", MyApp.Notices.Notice, "Court notices and legal documents",
        domain: MyApp.Legal)
  """
  @spec resource(String.t(), module(), String.t() | nil, keyword()) :: map()
  def resource(name, module, description \\ nil, opts \\ []) do
    %{
      name: name,
      module: module,
      description: description,
      domain: Keyword.get(opts, :domain),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Quick helper to define a resource with just name and module.
  
  ## Examples
  
      simple_resource("Users", MyApp.Accounts.User)
  """
  @spec simple_resource(String.t(), module()) :: map()
  def simple_resource(name, module) do
    resource(name, module)
  end

  @doc """
  Defines resources from a domain module.
  
  Automatically discovers all resources in the given Ash domain
  and creates resource configurations for them.
  
  ## Examples
  
      from_domain(MyApp.Accounts)
      
      from_domain(MyApp.Cases, prefix: "Legal")
  """
  @spec from_domain(module(), keyword()) :: [map()]
  def from_domain(domain, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    
    if function_exported?(domain, :__ash_resources__, 0) do
      domain.__ash_resources__()
      |> Enum.map(fn resource ->
        name = extract_resource_name(resource)
        name = if prefix != "", do: "#{prefix} #{name}", else: name
        
        %{
          name: name,
          module: resource,
          description: extract_resource_description(resource),
          domain: domain,
          metadata: %{}
        }
      end)
    else
      []
    end
  end

  @doc """
  Validates a resource configuration at compile time.
  
  ## Examples
  
      validate_resource_config!(%{name: "Users", module: MyApp.Accounts.User})
  """
  @spec validate_resource_config!(map()) :: map()
  def validate_resource_config!(%{name: name, module: module} = config) 
      when is_binary(name) and is_atom(module) do
    # Basic validation - could be expanded
    unless Code.ensure_loaded?(module) do
      raise ArgumentError, "Resource module #{inspect(module)} is not available"
    end
    
    config
  end
  
  def validate_resource_config!(config) do
    raise ArgumentError, "Invalid resource config: #{inspect(config)}. Must have :name and :module keys."
  end

  # Private helpers
  
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

  @doc """
  Configuration validation helper for use in config files.
  
  ## Examples
  
      # config/config.exs
      config :ncdb_2_phx,
        available_resources: [
          resource("Users", MyApp.Accounts.User),
          resource("Cases", MyApp.Cases.Case)
        ]
        |> validate_config!()
  """
  @spec validate_config!([map()]) :: [map()]
  def validate_config!(resources) when is_list(resources) do
    Enum.map(resources, &validate_resource_config!/1)
  end

  @doc """
  Creates a resource configuration from minimal input.
  
  Accepts various input formats and normalizes them to the standard format.
  
  ## Examples
  
      normalize_resource({MyApp.Accounts.User, "User Accounts"})
      normalize_resource(MyApp.Accounts.User)
      normalize_resource(%{name: "Users", module: MyApp.Accounts.User})
  """
  @spec normalize_resource(any()) :: map()
  def normalize_resource({module, name}) when is_atom(module) and is_binary(name) do
    resource(name, module)
  end
  
  def normalize_resource({name, module}) when is_binary(name) and is_atom(module) do
    resource(name, module)
  end
  
  def normalize_resource(module) when is_atom(module) do
    name = extract_resource_name(module)
    resource(name, module)
  end
  
  def normalize_resource(%{name: _name, module: _module} = config) do
    config
  end
  
  def normalize_resource(invalid) do
    raise ArgumentError, "Invalid resource format: #{inspect(invalid)}"
  end
end