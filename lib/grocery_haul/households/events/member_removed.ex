defmodule GroceryHaul.Households.Events.MemberRemoved do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :user_id]
end
