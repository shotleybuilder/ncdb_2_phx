defmodule NCDB2Phx.Components do
  @moduledoc """
  Basic form components for NCDB2Phx admin interface.
  These are simple implementations that can be overridden by the host application.
  """
  use Phoenix.Component
  

  @doc """
  Basic input component with support for various input types.
  """
  def input(assigns) do
    assigns = 
      assigns
      |> assign_new(:type, fn -> "text" end)
      |> assign_new(:class, fn -> "form-input" end)
      |> assign_new(:id, fn -> nil end)
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)
      |> assign_rest(~w(type class id name value)a)
    
    ~H"""
    <input 
      type={@type}
      class={@class}
      id={@id}
      name={@name}
      value={@value}
      {@rest}
    />
    """
  end

  @doc """
  Basic button component.
  """
  def button(assigns) do
    assigns = 
      assigns
      |> assign_new(:type, fn -> "button" end)
      |> assign_new(:class, fn -> "btn" end)
      |> assign_rest(~w(type class)a)
    
    ~H"""
    <button type={@type} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Basic label component.
  """
  def label(assigns) do
    assigns = 
      assigns
      |> assign_new(:class, fn -> "form-label" end)
      |> assign_new(:for, fn -> nil end)
      |> assign_rest(~w(class for)a)
    
    ~H"""
    <label class={@class} for={@for} {@rest}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Basic form wrapper component. Note: renamed to avoid conflict with Phoenix.Component.form/1
  """
  def simple_form(assigns) do
    assigns = 
      assigns
      |> assign_new(:class, fn -> "form" end)
      |> assign_new(:method, fn -> "post" end)
      |> assign_rest(~w(class method)a)
    
    ~H"""
    <form class={@class} method={@method} {@rest}>
      <%= render_slot(@inner_block) %>
    </form>
    """
  end

  @doc """
  Field wrapper component for grouping label and input.
  """
  def field(assigns) do
    assigns = assign_new(assigns, :class, fn -> "field" end)
    
    ~H"""
    <div class={@class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Simple card component.
  """
  def card(assigns) do
    assigns = assign_new(assigns, :class, fn -> "card" end)
    
    ~H"""
    <div class={@class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Basic table component.
  """
  def table(assigns) do
    assigns = 
      assigns
      |> assign_new(:class, fn -> "table" end)
      |> assign_rest(~w(class)a)
    
    ~H"""
    <table class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </table>
    """
  end

  @doc """
  Status badge component.
  """
  def status_badge(assigns) do
    assigns = assign_new(assigns, :status, fn -> "unknown" end)
    assigns = assign_new(assigns, :class, fn -> "status-badge status-#{assigns.status}" end)
    
    ~H"""
    <span class={@class}>
      <%= @status %>
    </span>
    """
  end

  @doc """
  Progress bar component.
  """
  def progress_bar(assigns) do
    assigns = assign_new(assigns, :value, fn -> 0 end)
    assigns = assign_new(assigns, :max, fn -> 100 end)
    assigns = assign_new(assigns, :class, fn -> "progress-bar" end)
    
    percentage = if assigns.max > 0, do: (assigns.value / assigns.max) * 100, else: 0
    
    assigns = assign(assigns, :percentage, percentage)
    
    ~H"""
    <div class={@class}>
      <div class="progress-fill" style={"width: #{@percentage}%"}></div>
    </div>
    """
  end

  @doc """
  Raw HTML helper (re-exported from Phoenix.HTML)
  """
  def raw(content), do: Phoenix.HTML.raw(content)
end