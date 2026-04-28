defmodule GroceryHaul.Households.Commands.JoinHousehold do
  @moduledoc false
  defstruct [:membership_id, :household_id, :user_id, :role]
end
