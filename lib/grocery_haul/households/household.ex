defmodule GroceryHaul.Households.Household do
  @moduledoc false
  defstruct created: false

  alias GroceryHaul.Households.Commands.CreateHousehold
  alias GroceryHaul.Households.Events.HouseholdCreated

  def execute(%__MODULE__{created: true}, %CreateHousehold{}), do: {:error, :already_created}

  def execute(%__MODULE__{created: false}, %CreateHousehold{} = cmd) do
    [
      %HouseholdCreated{
        household_id: cmd.household_id,
        name: cmd.name,
        created_by: cmd.created_by
      }
    ]
  end

  def apply(%__MODULE__{} = household, %HouseholdCreated{}) do
    %{household | created: true}
  end
end
