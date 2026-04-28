defmodule GroceryHaulWeb.DashboardLive do
  use GroceryHaulWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-16">
      <h1 class="text-2xl font-bold mb-4">Dashboard</h1>
      <p>Welcome, {@current_user.email}!</p>
      <.link href={~p"/logout"} method="delete" class="mt-4 inline-block text-red-600">
        Log out
      </.link>
    </div>
    """
  end

  def mount(_params, session, socket) do
    token = session["user_token"]
    user = token && GroceryHaul.Accounts.get_user_by_token(token)

    if user do
      {:ok, assign(socket, current_user: user)}
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end
end
