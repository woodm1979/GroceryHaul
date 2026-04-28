defmodule GroceryHaulWeb.Plugs.RequireAuth do
  @moduledoc false
  import Plug.Conn
  import Phoenix.Controller

  alias GroceryHaul.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    token = get_session(conn, :user_token)

    case token && Accounts.get_user_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access that page.")
        |> redirect(to: "/login")
        |> halt()

      user ->
        assign(conn, :current_user, user)
    end
  end
end
