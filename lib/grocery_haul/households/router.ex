defmodule GroceryHaul.Households.Router do
  use Commanded.Commands.Router

  alias GroceryHaul.Households.Commands.{
    CreateHousehold,
    DemoteAdmin,
    GenerateJoinCode,
    JoinHousehold,
    LeaveHousehold,
    PromoteAdmin,
    RemoveMember,
    RenameHousehold
  }

  alias GroceryHaul.Households.{Household, HouseholdMembership}

  dispatch(CreateHousehold, to: Household, identity: :household_id)
  dispatch(GenerateJoinCode, to: Household, identity: :household_id)
  dispatch(RenameHousehold, to: Household, identity: :household_id)

  dispatch(JoinHousehold, to: HouseholdMembership, identity: :membership_id)
  dispatch(LeaveHousehold, to: HouseholdMembership, identity: :membership_id)
  dispatch(RemoveMember, to: HouseholdMembership, identity: :membership_id)
  dispatch(PromoteAdmin, to: HouseholdMembership, identity: :membership_id)
  dispatch(DemoteAdmin, to: HouseholdMembership, identity: :membership_id)
end
