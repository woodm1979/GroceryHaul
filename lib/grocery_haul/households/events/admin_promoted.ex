defmodule GroceryHaul.Households.Events.AdminPromoted do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :user_id]
end
