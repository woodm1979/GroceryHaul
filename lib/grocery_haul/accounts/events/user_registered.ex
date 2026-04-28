defmodule GroceryHaul.Accounts.Events.UserRegistered do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:user_id, :email, :hashed_password]
end
