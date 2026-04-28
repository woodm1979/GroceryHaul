defmodule GroceryHaul.Households.Router do
  use Commanded.Commands.Router

  alias GroceryHaul.Households.Commands.{CreateHousehold, JoinHousehold}
  alias GroceryHaul.Households.{Household, HouseholdMembership}

  dispatch(CreateHousehold, to: Household, identity: :household_id)

  dispatch(JoinHousehold, to: HouseholdMembership, identity: :membership_id)
end
