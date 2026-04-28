defmodule GroceryHaul.Accounts.Commands.RegisterUser do
  defstruct [:user_id, :email, :hashed_password]
end
