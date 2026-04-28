defmodule GroceryHaul.Accounts do
  @moduledoc "Context for user accounts: registration, authentication, and session management."
  import Ecto.Query

  alias GroceryHaul.Accounts.Commands.RegisterUser
  alias GroceryHaul.Accounts.UserProjection
  alias GroceryHaul.Accounts.UserToken
  alias GroceryHaul.Commanded.Application, as: App
  alias GroceryHaul.Repo

  @doc "Registers a user. Returns {:ok, user_id} or {:error, reason}."
  def register_user(email, password) do
    if Repo.exists?(from u in UserProjection, where: u.email == ^email) do
      {:error, :email_taken}
    else
      hashed = Bcrypt.hash_pwd_salt(password)
      user_id = Ecto.UUID.generate()
      cmd = %RegisterUser{user_id: user_id, email: email, hashed_password: hashed}

      case App.dispatch(cmd, consistency: :strong) do
        :ok -> {:ok, user_id}
        {:error, _} = err -> err
      end
    end
  end

  @doc "Looks up a user by email and verifies the password."
  def authenticate_user(email, password) do
    user = Repo.one(from u in UserProjection, where: u.email == ^email)

    if user && Bcrypt.verify_pass(password, user.hashed_password) do
      {:ok, user}
    else
      Bcrypt.no_user_verify()
      {:error, :invalid_credentials}
    end
  end

  @doc "Creates a session token for a user."
  def create_user_token(user) do
    token_struct = UserToken.build_token(user)
    Repo.insert!(token_struct)
    token_struct.token
  end

  @doc "Gets the user for a given session token."
  def get_user_by_token(token) do
    case Repo.one(UserToken.by_token_query(token)) do
      nil -> nil
      token_struct -> token_struct.user
    end
  end

  @doc "Deletes all tokens for a user (logout)."
  def delete_user_tokens(user) do
    Repo.delete_all(from t in UserToken, where: t.user_id == ^user.id)
    :ok
  end

  @doc "Gets user by id."
  def get_user(id), do: Repo.get(UserProjection, id)
end
