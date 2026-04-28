defmodule GroceryHaulWeb.AuthController do
  use GroceryHaulWeb, :controller

  alias GroceryHaul.Accounts

  # Called after successful register or login to set the session
  def create(conn, %{"token" => encoded_token}) do
    token = Base.url_decode64!(encoded_token, padding: false)

    conn
    |> put_session(:user_token, token)
    |> redirect(to: ~p"/dashboard")
  end

  def delete(conn, _params) do
    token = get_session(conn, :user_token)

    if token do
      user = Accounts.get_user_by_token(token)
      if user, do: Accounts.delete_user_tokens(user)
    end

    conn
    |> delete_session(:user_token)
    |> redirect(to: ~p"/login")
  end
end
