defmodule GroceryHaul.Households.Events.HouseholdRenamed do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :name]
end
