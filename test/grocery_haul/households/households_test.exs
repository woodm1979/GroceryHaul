defmodule GroceryHaul.HouseholdsTest do
  use GroceryHaul.DataCase, async: false

  alias GroceryHaul.Households

  setup do
    # Allow projector processes to use the sandbox connection
    for projector <- [
          GroceryHaul.Households.HouseholdProjector,
          GroceryHaul.Households.HouseholdMembersProjector,
          GroceryHaul.Households.JoinCodeProjector
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

    test "projects a join code for the new household" do
      user_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(user_id, "Code Household")
      entry = Households.get_join_code(household_id)
      assert entry != nil
      assert String.length(entry.code) == 8
      assert String.match?(entry.code, ~r/^[A-Z0-9]{8}$/)
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

  describe "regenerate_join_code/1" do
    test "changes the join code" do
      user_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(user_id, "Regen Test")
      old_entry = Households.get_join_code(household_id)
      old_code = old_entry.code

      :ok = Households.regenerate_join_code(household_id)

      new_entry = Households.get_join_code(household_id)
      assert new_entry != nil
      # Old code removed from index
      assert Households.lookup_join_code(old_code) == nil
      # New code points to same household
      assert new_entry.household_id == household_id
    end
  end

  describe "join_via_code/2" do
    test "a second user can join with a valid code" do
      creator_id = Ecto.UUID.generate()
      joiner_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(creator_id, "Join Test")
      %{code: code} = Households.get_join_code(household_id)

      assert {:ok, ^household_id} = Households.join_via_code(joiner_id, code)
      members = Households.list_members(household_id)
      assert length(members) == 2
      joiner = Enum.find(members, fn m -> m.user_id == joiner_id end)
      assert joiner.role == :member
    end

    test "invalid code returns {:error, :invalid_code}" do
      user_id = Ecto.UUID.generate()
      assert {:error, :invalid_code} = Households.join_via_code(user_id, "BADCODE1")
    end

    test "joining twice with same code returns already_member error" do
      creator_id = Ecto.UUID.generate()
      joiner_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(creator_id, "Dup Test")
      %{code: code} = Households.get_join_code(household_id)

      {:ok, _} = Households.join_via_code(joiner_id, code)
      assert {:error, :already_member} = Households.join_via_code(joiner_id, code)
    end

    test "old code no longer works after regeneration" do
      creator_id = Ecto.UUID.generate()
      joiner_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(creator_id, "Expired Code Test")
      %{code: old_code} = Households.get_join_code(household_id)

      :ok = Households.regenerate_join_code(household_id)

      assert {:error, :invalid_code} = Households.join_via_code(joiner_id, old_code)
    end

    test "integration: admin generates code, second user joins" do
      creator_id = Ecto.UUID.generate()
      joiner_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(creator_id, "Integration HH")

      :ok = Households.regenerate_join_code(household_id)
      %{code: new_code} = Households.get_join_code(household_id)

      assert {:ok, ^household_id} = Households.join_via_code(joiner_id, new_code)
      members = Households.list_members(household_id)
      assert length(members) == 2
    end
  end
end
