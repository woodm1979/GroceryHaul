defmodule GroceryHaul.Households.HouseholdAggregateTest do
  use ExUnit.Case, async: true

  alias GroceryHaul.Households.Commands.CreateHousehold
  alias GroceryHaul.Households.Events.HouseholdCreated
  alias GroceryHaul.Households.Household

  describe "CreateHousehold" do
    test "successful creation emits HouseholdCreated" do
      household = %Household{}

      cmd = %CreateHousehold{
        household_id: "hh-uuid-1",
        name: "The Smith Family",
        created_by: "user-uuid-1"
      }

      assert [
               %HouseholdCreated{
                 household_id: "hh-uuid-1",
                 name: "The Smith Family",
                 created_by: "user-uuid-1"
               }
             ] = Household.execute(household, cmd)
    end

    test "already-created household rejects CreateHousehold" do
      household = %Household{created: true}

      cmd = %CreateHousehold{
        household_id: "hh-uuid-1",
        name: "Duplicate",
        created_by: "user-uuid-1"
      }

      assert {:error, :already_created} = Household.execute(household, cmd)
    end
  end
end
