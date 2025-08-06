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
    assigns = assign_new(assigns, :type, fn -> "text" end)
    assigns = assign_new(assigns, :class, fn -> "form-input" end)
    assigns = assign_new(assigns, :id, fn -> nil end)
    assigns = assign_new(assigns, :name, fn -> nil end)
    assigns = assign_new(assigns, :value, fn -> nil end)
    
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
    assigns = assign_new(assigns, :type, fn -> "button" end)
    assigns = assign_new(assigns, :class, fn -> "btn" end)
    
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
    assigns = assign_new(assigns, :class, fn -> "form-label" end)
    assigns = assign_new(assigns, :for, fn -> nil end)
    
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
    assigns = assign_new(assigns, :class, fn -> "form" end)
    assigns = assign_new(assigns, :method, fn -> "post" end)
    
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
    assigns = assign_new(assigns, :class, fn -> "table" end)
    
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