defmodule GroceryHaul.AccountsTest do
  use GroceryHaul.DataCase, async: false

  alias GroceryHaul.Accounts

  setup do
    projector_key =
      {GroceryHaul.Commanded.Application, Commanded.Event.Handler,
       inspect(GroceryHaul.Accounts.UserProjector)}

    [{projector_pid, _}] =
      Registry.lookup(GroceryHaul.Commanded.Application.LocalRegistry, projector_key)

    Ecto.Adapters.SQL.Sandbox.allow(GroceryHaul.Repo, self(), projector_pid)
    :ok
  end

  describe "register_user/2" do
    test "successful registration returns {:ok, user_id}" do
      assert {:ok, user_id} = Accounts.register_user("bob@example.com", "password123")
      assert is_binary(user_id)
    end

    test "successful registration stores a UserProjection row" do
      {:ok, user_id} = Accounts.register_user("proj@example.com", "password123")
      user = Accounts.get_user(user_id)
      assert user != nil
      assert user.email == "proj@example.com"
    end

    test "duplicate email returns an error" do
      {:ok, _} = Accounts.register_user("dup@example.com", "password123")
      assert {:error, _} = Accounts.register_user("dup@example.com", "password123")
    end
  end

  describe "authenticate_user/2" do
    setup do
      {:ok, _} = Accounts.register_user("auth@example.com", "correctpass")
      :ok
    end

    test "correct credentials returns {:ok, user}" do
      assert {:ok, user} = Accounts.authenticate_user("auth@example.com", "correctpass")
      assert user.email == "auth@example.com"
    end

    test "wrong password returns {:error, :invalid_credentials}" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("auth@example.com", "wrongpass")
    end
  end

  describe "token lifecycle" do
    setup do
      {:ok, _} = Accounts.register_user("token@example.com", "password123")
      {:ok, user} = Accounts.authenticate_user("token@example.com", "password123")
      %{user: user}
    end

    test "create and retrieve token", %{user: user} do
      token = Accounts.create_user_token(user)
      assert fetched = Accounts.get_user_by_token(token)
      assert fetched.id == user.id
    end

    test "delete tokens invalidates session", %{user: user} do
      token = Accounts.create_user_token(user)
      Accounts.delete_user_tokens(user)
      assert is_nil(Accounts.get_user_by_token(token))
    end
  end
end
