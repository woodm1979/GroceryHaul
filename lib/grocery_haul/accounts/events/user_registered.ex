defmodule GroceryHaul.Accounts.Events.UserRegistered do
  @derive Jason.Encoder
  defstruct [:user_id, :email, :hashed_password]
end
