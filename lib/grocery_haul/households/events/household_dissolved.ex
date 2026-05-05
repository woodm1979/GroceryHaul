defmodule GroceryHaul.Households.Events.HouseholdDissolved do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :dissolved_at]
end
