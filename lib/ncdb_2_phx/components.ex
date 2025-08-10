defmodule NCDB2Phx.Components do
  @moduledoc """
  Basic form components for NCDB2Phx admin interface.
  These are simple implementations that can be overridden by the host application.
  """
  use Phoenix.Component
  

  @doc """
  Basic input component with support for various input types.
  """
  attr :type, :string, default: "text"
  attr :class, :string, default: "form-input"
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :rest, :global, include: ~w(placeholder required disabled readonly)
  
  def input(assigns) do
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
  attr :type, :string, default: "button"
  attr :class, :string, default: "btn"
  attr :rest, :global, include: ~w(disabled form)
  
  slot :inner_block, required: true
  
  def button(assigns) do
    ~H"""
    <button type={@type} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Basic label component.
  """
  attr :class, :string, default: "form-label"
  attr :for, :string, default: nil
  attr :rest, :global
  
  slot :inner_block, required: true
  
  def label(assigns) do
    ~H"""
    <label class={@class} for={@for} {@rest}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Basic form wrapper component. Note: renamed to avoid conflict with Phoenix.Component.form/1
  """
  attr :class, :string, default: "form"
  attr :method, :string, default: "post"
  attr :rest, :global, include: ~w(action enctype novalidate target)
  
  slot :inner_block, required: true
  
  def simple_form(assigns) do
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
  attr :class, :string, default: "table"
  attr :rest, :global
  
  slot :inner_block, required: true
  
  def table(assigns) do
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