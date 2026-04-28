defmodule GroceryHaulWeb.DashboardLive do
  use GroceryHaulWeb, :live_view

  alias GroceryHaul.Accounts
  alias GroceryHaul.Households

  def mount(_params, session, socket) do
    token = session["user_token"]
    user = token && Accounts.get_user_by_token(token)

    if user do
      case Households.list_households_for_user(user.id) do
        [] ->
          {:ok, redirect(socket, to: ~p"/households/new")}

        [household] ->
          {:ok, redirect(socket, to: ~p"/households/#{household.id}")}

        _multiple ->
          {:ok, assign(socket, current_user: user)}
      end
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  # Only rendered when user has multiple households (picker)
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-16">
      <h1 class="text-2xl font-bold mb-4">Your Households</h1>
      <p>Welcome, {@current_user.email}!</p>
    </div>
    """
  end
end
