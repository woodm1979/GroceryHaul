defmodule GroceryHaul.Households.HouseholdCreationProcessManagerTest do
  use ExUnit.Case, async: true

  alias GroceryHaul.Households.Commands.JoinHousehold
  alias GroceryHaul.Households.Events.HouseholdCreated
  alias GroceryHaul.Households.HouseholdCreationProcessManager

  describe "interested?/1" do
    test "starts a process on HouseholdCreated" do
      event = %HouseholdCreated{household_id: "hh-1", name: "Test", created_by: "u-1"}
      assert {:start, "hh-1"} = HouseholdCreationProcessManager.interested?(event)
    end

    test "ignores other events" do
      assert false == HouseholdCreationProcessManager.interested?(%{})
    end
  end

  describe "handle/2" do
    test "returns JoinHousehold command for HouseholdCreated" do
      pm = %HouseholdCreationProcessManager{}

      event = %HouseholdCreated{
        household_id: "hh-1",
        name: "Test Household",
        created_by: "user-1"
      }

      command = HouseholdCreationProcessManager.handle(pm, event)

      assert %JoinHousehold{
               household_id: "hh-1",
               user_id: "user-1",
               role: :admin
             } = command
    end
  end

  describe "apply/2" do
    test "records household_id after HouseholdCreated" do
      pm = %HouseholdCreationProcessManager{}
      event = %HouseholdCreated{household_id: "hh-1", name: "Test", created_by: "u-1"}

      updated = HouseholdCreationProcessManager.apply(pm, event)

      assert %HouseholdCreationProcessManager{household_id: "hh-1"} = updated
    end
  end
end
