defmodule GroceryHaulWeb.HouseholdLive.New do
  use GroceryHaulWeb, :live_view

  alias GroceryHaul.Accounts
  alias GroceryHaul.Households

  def mount(_params, session, socket) do
    token = session["user_token"]
    user = token && Accounts.get_user_by_token(token)

    if user do
      {:ok,
       assign(socket,
         current_user: user,
         form: to_form(%{}, as: :household),
         join_form: to_form(%{}, as: :join),
         error: nil
       )}
    else
      {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-sm mx-auto mt-16">
      <h1 class="text-2xl font-bold mb-6">Create or Join a Household</h1>

      <h2 class="text-lg font-semibold mb-4">Create a new household</h2>
      <.form id="create-household-form" for={@form} phx-submit="create">
        <.input field={@form[:name]} type="text" label="Household name" required />
        <.button type="submit" phx-disable-with="Creating...">Create</.button>
      </.form>

      <%= if @error do %>
        <p class="mt-4 text-red-600">{@error}</p>
      <% end %>

      <.link href={~p"/logout"} method="delete" class="mt-4 inline-block text-red-600">
        Log out
      </.link>

      <div class="mt-8 border-t pt-6">
        <h2 class="text-lg font-semibold mb-4">Join an existing household</h2>
        <.form id="join-household-form" for={@join_form} phx-submit="join">
          <.input field={@join_form[:code]} type="text" label="Join code" />
          <.button type="submit" phx-disable-with="Joining...">Join</.button>
        </.form>
      </div>
    </div>
    """
  end

  def handle_event("create", %{"household" => %{"name" => name}}, socket) do
    user = socket.assigns.current_user

    case Households.create_household(user.id, name) do
      {:ok, household_id} ->
        {:noreply, redirect(socket, to: ~p"/households/#{household_id}")}

      {:error, _} ->
        {:noreply, assign(socket, error: "Failed to create household. Please try again.")}
    end
  end

  def handle_event("join", %{"join" => %{"code" => code}}, socket) do
    user = socket.assigns.current_user

    case Households.join_via_code(user.id, code) do
      {:ok, household_id} ->
        {:noreply, redirect(socket, to: ~p"/households/#{household_id}")}

      {:error, :invalid_code} ->
        {:noreply, assign(socket, error: "Invalid join code. Please check and try again.")}

      {:error, :already_member} ->
        {:noreply, assign(socket, error: "You are already a member of that household.")}

      {:error, _} ->
        {:noreply, assign(socket, error: "Failed to join household. Please try again.")}
    end
  end
end
