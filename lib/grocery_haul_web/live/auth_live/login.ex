defmodule GroceryHaulWeb.AuthLive.Login do
  use GroceryHaulWeb, :live_view

  alias GroceryHaul.Accounts

  def render(assigns) do
    ~H"""
    <div class="max-w-sm mx-auto mt-16">
      <h1 class="text-2xl font-bold mb-6">Log in</h1>
      <.form id="login-form" for={@form} phx-submit="login">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.button type="submit" phx-disable-with="Logging in...">Log in</.button>
      </.form>
      <%= if @error do %>
        <p class="mt-4 text-red-600">{@error}</p>
      <% end %>
      <p class="mt-4">No account? <.link href={~p"/register"}>Register</.link></p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user), error: nil)}
  end

  def handle_event("login", %{"user" => %{"email" => email, "password" => password}}, socket) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = Accounts.create_user_token(user)

        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> redirect(to: session_path(token))}

      {:error, :invalid_credentials} ->
        {:noreply, assign(socket, error: "Invalid email or password.")}
    end
  end

  defp session_path(token) do
    "/auth/session?token=#{Base.url_encode64(token, padding: false)}"
  end
end
