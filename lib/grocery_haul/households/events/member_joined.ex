defmodule GroceryHaul.Households.Events.MemberJoined do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :user_id, :role]
end
