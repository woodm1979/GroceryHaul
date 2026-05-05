defmodule GroceryHaul.Households.Events.MemberLeft do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :user_id]
end
