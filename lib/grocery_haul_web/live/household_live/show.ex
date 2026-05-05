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
        join_code_entry = Households.get_join_code(household_id)

        {:ok,
         assign(socket,
           current_user: user,
           household: household,
           members: members,
           my_role: my_membership.role,
           join_code: join_code_entry && join_code_entry.code
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

      <div class="mt-6 mb-4 p-4 bg-gray-100 rounded">
        <span class="font-semibold">Join Code:</span>
        <span class="font-mono ml-2">{@join_code}</span>
        <%= if @my_role == :admin do %>
          <button phx-click="regenerate_code" class="ml-4 text-sm text-blue-600 underline">
            Regenerate
          </button>
        <% end %>
      </div>

      <h2 class="text-lg font-semibold mt-6 mb-2">Members</h2>
      <ul>
        <%= for member <- @members do %>
          <li>{member.user_id} — {member.role}</li>
        <% end %>
      </ul>

      <%= if @my_role == :admin do %>
        <.link navigate={~p"/households/#{@household.id}/settings"} class="mt-4 inline-block text-blue-600 underline">
          Settings
        </.link>
      <% end %>

      <.link href={~p"/logout"} method="delete" class="mt-6 inline-block text-red-600">
        Log out
      </.link>
    </div>
    """
  end

  def handle_event("regenerate_code", _params, socket) do
    household_id = socket.assigns.household.id

    case Households.regenerate_join_code(household_id) do
      :ok ->
        entry = Households.get_join_code(household_id)
        {:noreply, assign(socket, join_code: entry && entry.code)}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
