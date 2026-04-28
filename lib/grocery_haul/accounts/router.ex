defmodule GroceryHaul.Accounts.Router do
  use Commanded.Commands.Router

  alias GroceryHaul.Accounts.User
  alias GroceryHaul.Accounts.Commands.RegisterUser

  dispatch(RegisterUser, to: User, identity: :user_id)
end
