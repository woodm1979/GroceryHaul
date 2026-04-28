defmodule GroceryHaul.Accounts.Router do
  use Commanded.Commands.Router

  alias GroceryHaul.Accounts.Commands.RegisterUser
  alias GroceryHaul.Accounts.User

  dispatch(RegisterUser, to: User, identity: :user_id)
end
