defmodule GroceryHaul.Accounts.UserAggregateTest do
  use ExUnit.Case, async: true

  alias GroceryHaul.Accounts.Commands.RegisterUser
  alias GroceryHaul.Accounts.Events.UserRegistered
  alias GroceryHaul.Accounts.User

  describe "RegisterUser" do
    test "successful registration emits UserRegistered" do
      user = %User{}

      cmd = %RegisterUser{
        user_id: "uuid-1",
        email: "alice@example.com",
        hashed_password: "hashed"
      }

      assert [
               %UserRegistered{
                 user_id: "uuid-1",
                 email: "alice@example.com",
                 hashed_password: "hashed"
               }
             ] =
               User.execute(user, cmd)
    end

    test "duplicate registration is rejected" do
      user = %User{registered: true}

      cmd = %RegisterUser{
        user_id: "uuid-1",
        email: "alice@example.com",
        hashed_password: "hashed"
      }

      assert {:error, :already_registered} = User.execute(user, cmd)
    end
  end
end
