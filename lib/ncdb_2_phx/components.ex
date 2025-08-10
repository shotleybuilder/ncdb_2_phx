defmodule NCDB2Phx.Components do
  @moduledoc """
  Basic form components for NCDB2Phx admin interface.
  These are simple implementations that can be overridden by the host application.
  """
  use Phoenix.Component
  import Phoenix.Component
  

  @doc """
  Basic input component with support for various input types.
  """
  attr :type, :string, default: "text"
  attr :class, :string, default: "form-input"
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :field, :any, default: nil
  attr :options, :list, default: []
  attr :checked, :boolean, default: false
  attr :accept, :string, default: nil
  attr :min, :string, default: nil
  attr :max, :string, default: nil
  attr :step, :string, default: nil
  attr :rows, :string, default: nil
  attr :rest, :global, include: ~w(placeholder required disabled readonly)
  
  def input(assigns) do
    assigns = assign_new(assigns, :errors, fn -> [] end)
    
    # Handle Phoenix.HTML.Form field attributes
    {field_name, field_value, field_errors} = if assigns.field do
      {assigns.field.field, Phoenix.HTML.Form.input_value(assigns.field.form, assigns.field.field), 
       Phoenix.HTML.Form.input_validations(assigns.field.form, assigns.field.field)}
    else
      {assigns.name, assigns.value, []}
    end
    
    assigns = assign(assigns, :field_name, field_name)
    assigns = assign(assigns, :field_value, field_value)
    assigns = assign(assigns, :field_errors, field_errors)
    
    ~H"""
    <%= cond do %>
      <% @type == "select" -> %>
        <select 
          class={@class}
          id={@id || @field_name}
          name={@name || @field_name}
          {@rest}
        >
          <%= for {label, value} <- @options do %>
            <option value={value} selected={value == @field_value}><%= label %></option>
          <% end %>
        </select>
      <% @type == "textarea" -> %>
        <textarea 
          class={@class}
          id={@id || @field_name}
          name={@name || @field_name}
          rows={@rows}
          {@rest}
        ><%= @field_value %></textarea>
      <% @type == "checkbox" -> %>
        <input 
          type="checkbox"
          class={@class}
          id={@id || @field_name}
          name={@name || @field_name}
          checked={@checked || @field_value}
          {@rest}
        />
      <% true -> %>
        <input 
          type={@type}
          class={@class}
          id={@id || @field_name}
          name={@name || @field_name}
          value={@field_value}
          accept={@accept}
          min={@min}
          max={@max}
          step={@step}
          {@rest}
        />
    <% end %>
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
  attr :class, :string, default: "field"
  slot :inner_block, required: true
  
  def field(assigns) do
    ~H"""
    <div class={@class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Simple card component.
  """
  attr :class, :string, default: "card"
  slot :inner_block, required: true
  
  def card(assigns) do
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
  attr :status, :string, default: "unknown"
  attr :class, :string, default: nil
  
  def status_badge(assigns) do
    assigns = assign(assigns, :class, assigns.class || "status-badge status-#{assigns.status}")
    
    ~H"""
    <span class={@class}>
      <%= @status %>
    </span>
    """
  end

  @doc """
  Progress bar component.
  """
  attr :value, :integer, default: 0
  attr :max, :integer, default: 100
  attr :class, :string, default: "progress-bar"
  
  def progress_bar(assigns) do
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