defmodule GroceryHaulWeb.AuthLive.Register do
  use GroceryHaulWeb, :live_view

  alias GroceryHaul.Accounts

  def render(assigns) do
    ~H"""
    <div class="max-w-sm mx-auto mt-16">
      <h1 class="text-2xl font-bold mb-6">Create an account</h1>
      <.form id="registration-form" for={@form} phx-submit="register">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.button type="submit" phx-disable-with="Creating account...">Create account</.button>
      </.form>
      <%= if @error do %>
        <p class="mt-4 text-red-600">{@error}</p>
      <% end %>
      <p class="mt-4">Already have an account? <.link href={~p"/login"}>Log in</.link></p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user), error: nil)}
  end

  def handle_event("register", %{"user" => %{"email" => email, "password" => password}}, socket) do
    case Accounts.register_user(email, password) do
      {:ok, user_id} ->
        user = Accounts.get_user(user_id)
        token = Accounts.create_user_token(user)

        {:noreply,
         socket
         |> put_flash(:info, "Account created!")
         |> redirect(to: session_path(token))}

      {:error, :email_taken} ->
        {:noreply, assign(socket, error: "This email is already registered.")}

      {:error, _} ->
        {:noreply, assign(socket, error: "Registration failed. Please try again.")}
    end
  end

  defp session_path(token) do
    "/auth/session?token=#{Base.url_encode64(token, padding: false)}"
  end
end
