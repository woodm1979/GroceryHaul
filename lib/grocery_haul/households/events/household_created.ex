defmodule GroceryHaul.Households.Events.HouseholdCreated do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :name, :created_by]
end
