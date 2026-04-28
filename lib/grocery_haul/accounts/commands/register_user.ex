defmodule GroceryHaul.Accounts.Commands.RegisterUser do
  @moduledoc false
  defstruct [:user_id, :email, :hashed_password]
end
