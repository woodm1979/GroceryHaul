defmodule GroceryHaul.HouseholdsTest do
  use GroceryHaul.DataCase, async: false

  alias GroceryHaul.Households

  setup do
    # Allow projector processes to use the sandbox connection
    for projector <- [
          GroceryHaul.Households.HouseholdProjector,
          GroceryHaul.Households.HouseholdMembersProjector
        ] do
      key =
        {GroceryHaul.Commanded.Application, Commanded.Event.Handler, inspect(projector)}

      case Registry.lookup(GroceryHaul.Commanded.Application.LocalRegistry, key) do
        [{pid, _}] ->
          Ecto.Adapters.SQL.Sandbox.allow(GroceryHaul.Repo, self(), pid)

        [] ->
          :ok
      end
    end

    :ok
  end

  describe "create_household/2" do
    test "returns {:ok, household_id} on success" do
      user_id = Ecto.UUID.generate()
      assert {:ok, household_id} = Households.create_household(user_id, "Test Household")
      assert is_binary(household_id)
    end

    test "projects HouseholdProjection after creation" do
      user_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(user_id, "Smith Family")
      household = Households.get_household(household_id)
      assert household != nil
      assert household.name == "Smith Family"
    end

    test "creator appears as admin in HouseholdMembersProjection" do
      user_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(user_id, "My Household")
      members = Households.list_members(household_id)
      assert length(members) == 1
      [member] = members
      assert member.user_id == user_id
      assert member.role == :admin
    end
  end

  describe "list_households_for_user/1" do
    test "returns empty list when user has no households" do
      user_id = Ecto.UUID.generate()
      assert [] = Households.list_households_for_user(user_id)
    end

    test "returns households after creation" do
      user_id = Ecto.UUID.generate()
      {:ok, _id} = Households.create_household(user_id, "Family Haul")
      households = Households.list_households_for_user(user_id)
      assert length(households) == 1
      assert hd(households).name == "Family Haul"
    end
  end
end
