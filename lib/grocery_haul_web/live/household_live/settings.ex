defmodule GroceryHaulWeb.HouseholdLive.Settings do
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
           my_role: my_membership.role,
           error: nil
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
      <h1 class="text-2xl font-bold mb-4">{@household.name} — Settings</h1>

      <%= if @error do %>
        <div class="mb-4 text-red-600">{@error}</div>
      <% end %>

      <%= if @my_role == :admin do %>
        <section class="mb-8">
          <h2 class="text-lg font-semibold mb-2">Rename Household</h2>
          <form id="rename-household-form" phx-submit="rename_household">
            <input type="text" name="household[name]" value={@household.name} class="border rounded px-3 py-2 mr-2" />
            <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded">Rename</button>
          </form>
        </section>

        <section class="mb-8">
          <h2 class="text-lg font-semibold mb-2">Members</h2>
          <ul>
            <%= for member <- @members do %>
              <li class="flex items-center gap-4 mb-2">
                <span>{member.user_id}</span>
                <span class="text-sm text-gray-500">{member.role}</span>
                <%= if member.user_id != @current_user.id do %>
                  <button phx-click="remove_member" phx-value-user_id={member.user_id} class="text-red-600 text-sm underline">
                    Remove
                  </button>
                  <%= if member.role == :member do %>
                    <button phx-click="promote_admin" phx-value-user_id={member.user_id} class="text-blue-600 text-sm underline">
                      Promote to Admin
                    </button>
                  <% else %>
                    <button phx-click="demote_admin" phx-value-user_id={member.user_id} class="text-orange-600 text-sm underline">
                      Demote to Member
                    </button>
                  <% end %>
                <% else %>
                  <button phx-click="demote_admin" phx-value-user_id={member.user_id} class="text-orange-600 text-sm underline">
                    Demote self
                  </button>
                <% end %>
              </li>
            <% end %>
          </ul>
        </section>
      <% end %>

      <section>
        <button phx-click="leave_household" class="text-red-600 underline">
          Leave Household
        </button>
      </section>

      <.link navigate={~p"/households/#{@household.id}"} class="mt-4 inline-block text-gray-600">
        &larr; Back to Dashboard
      </.link>
    </div>
    """
  end

  def handle_event("rename_household", _params, %{assigns: %{my_role: role}} = socket)
      when role != :admin do
    {:noreply, assign(socket, error: "Not authorized.")}
  end

  def handle_event("rename_household", %{"household" => %{"name" => name}}, socket) do
    household_id = socket.assigns.household.id

    case Households.rename_household(household_id, name) do
      :ok ->
        household = Households.get_household(household_id)
        {:noreply, assign(socket, household: household, error: nil)}

      {:error, _} ->
        {:noreply, assign(socket, error: "Could not rename household.")}
    end
  end

  def handle_event("remove_member", _params, %{assigns: %{my_role: role}} = socket)
      when role != :admin do
    {:noreply, assign(socket, error: "Not authorized.")}
  end

  def handle_event("remove_member", %{"user_id" => user_id}, socket) do
    household_id = socket.assigns.household.id

    case Households.remove_member(household_id, user_id) do
      :ok ->
        members = Households.list_members(household_id)
        {:noreply, assign(socket, members: members, error: nil)}

      {:error, _} ->
        {:noreply, assign(socket, error: "Could not remove member.")}
    end
  end

  def handle_event("promote_admin", _params, %{assigns: %{my_role: role}} = socket)
      when role != :admin do
    {:noreply, assign(socket, error: "Not authorized.")}
  end

  def handle_event("promote_admin", %{"user_id" => user_id}, socket) do
    household_id = socket.assigns.household.id

    case Households.promote_admin(household_id, user_id) do
      :ok ->
        members = Households.list_members(household_id)
        {:noreply, assign(socket, members: members, error: nil)}

      {:error, _} ->
        {:noreply, assign(socket, error: "Could not promote member.")}
    end
  end

  def handle_event("demote_admin", _params, %{assigns: %{my_role: role}} = socket)
      when role != :admin do
    {:noreply, assign(socket, error: "Not authorized.")}
  end

  def handle_event("demote_admin", %{"user_id" => user_id}, socket) do
    household_id = socket.assigns.household.id

    case Households.demote_admin(household_id, user_id) do
      :ok ->
        members = Households.list_members(household_id)
        {:noreply, assign(socket, members: members, error: nil)}

      {:error, :sole_admin} ->
        {:noreply, assign(socket, error: "Cannot demote the sole admin.")}

      {:error, _} ->
        {:noreply, assign(socket, error: "Could not demote admin.")}
    end
  end

  def handle_event("leave_household", _params, socket) do
    household_id = socket.assigns.household.id
    user_id = socket.assigns.current_user.id

    case Households.leave_household(household_id, user_id) do
      :ok ->
        {:noreply, redirect(socket, to: ~p"/households/new")}

      {:error, _} ->
        {:noreply, assign(socket, error: "Could not leave household.")}
    end
  end
end
