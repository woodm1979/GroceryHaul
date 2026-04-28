defmodule GroceryHaulWeb.HouseholdLive.Show do
  use GroceryHaulWeb, :live_view

  alias GroceryHaul.Accounts
  alias GroceryHaul.Households

  def mount(%{"id" => household_id}, session, socket) do
    token = session["user_token"]
    user = token && Accounts.get_user_by_token(token)

    if user do
      household = Households.get_household(household_id)
      members = Households.list_members(household_id)
      my_membership = Enum.find(members, fn m -> m.user_id == user.id end)

      if household && my_membership do
        {:ok,
         assign(socket,
           current_user: user,
           household: household,
           members: members,
           my_role: my_membership.role
         )}
      else
        {:ok, redirect(socket, to: ~p"/households/new")}
      end
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-16">
      <h1 class="text-2xl font-bold mb-4">{@household.name}</h1>
      <p class="mb-2">
        Welcome, {@current_user.email}! Your role: <strong>{@my_role}</strong>
      </p>
      <h2 class="text-lg font-semibold mt-6 mb-2">Members</h2>
      <ul>
        <%= for member <- @members do %>
          <li>{member.user_id} — {member.role}</li>
        <% end %>
      </ul>
      <.link href={~p"/logout"} method="delete" class="mt-6 inline-block text-red-600">
        Log out
      </.link>
    </div>
    """
  end
end
