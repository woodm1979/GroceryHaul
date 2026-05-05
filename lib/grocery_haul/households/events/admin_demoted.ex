defmodule GroceryHaul.Households.Events.AdminDemoted do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:household_id, :user_id]
end
