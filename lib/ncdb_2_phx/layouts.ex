defmodule NCDB2Phx.Layouts do
  @moduledoc """
  Default layouts for NCDB2Phx admin interface.
  """
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title><%= assigns[:page_title] || "Sync Administration" %></title>
        <link phx-track-static rel="stylesheet" href="/assets/ncdb_sync.css" />
        <script defer phx-track-static type="text/javascript" src="/assets/ncdb_sync.js"></script>
      </head>
      <body>
        <div id="sync-admin-root">
          <.sync_navigation current_route={assigns[:current_route]} />
          <main class="sync-main-content">
            <%= @inner_content %>
          </main>
        </div>
      </body>
    </html>
    """
  end

  defp sync_navigation(assigns) do
    ~H"""
    <nav class="sync-navbar">
      <div class="sync-navbar-brand">
        <h1>Sync Administration</h1>
      </div>
      <div class="sync-navbar-nav">
        <.nav_link href="/sync" current={@current_route}>Dashboard</.nav_link>
        <.nav_link href="/sync/sessions" current={@current_route}>Sessions</.nav_link>
        <.nav_link href="/sync/monitor" current={@current_route}>Monitor</.nav_link>
        <.nav_link href="/sync/logs" current={@current_route}>Logs</.nav_link>
        <.nav_link href="/sync/config" current={@current_route}>Config</.nav_link>
      </div>
    </nav>
    """
  end

  defp nav_link(assigns) do
    active = assigns[:current] == assigns[:href]
    class = if active, do: "nav-link active", else: "nav-link"

    assigns = assign(assigns, :class, class)

    ~H"""
    <a href={@href} class={@class}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end