defmodule GroceryHaul.Households.Router do
  use Commanded.Commands.Router

  alias GroceryHaul.Households.Commands.{
    CreateHousehold,
    DemoteAdmin,
    DissolveHousehold,
    GenerateJoinCode,
    JoinHousehold,
    LeaveHousehold,
    PromoteAdmin,
    RemoveMember,
    RenameHousehold
  }

  alias GroceryHaul.Households.Household

  dispatch(CreateHousehold, to: Household, identity: :household_id)
  dispatch(GenerateJoinCode, to: Household, identity: :household_id)
  dispatch(RenameHousehold, to: Household, identity: :household_id)

  dispatch(JoinHousehold, to: Household, identity: :household_id)
  dispatch(LeaveHousehold, to: Household, identity: :household_id)
  dispatch(RemoveMember, to: Household, identity: :household_id)
  dispatch(PromoteAdmin, to: Household, identity: :household_id)
  dispatch(DemoteAdmin, to: Household, identity: :household_id)
  dispatch(DissolveHousehold, to: Household, identity: :household_id)
end
