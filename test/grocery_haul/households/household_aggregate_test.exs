defmodule GroceryHaul.Households.HouseholdAggregateTest do
  use ExUnit.Case, async: true

  alias GroceryHaul.Households.Commands.{CreateHousehold, GenerateJoinCode, RenameHousehold}
  alias GroceryHaul.Households.Events.{HouseholdCreated, HouseholdRenamed, JoinCodeGenerated}
  alias GroceryHaul.Households.Household

  describe "CreateHousehold" do
    test "successful creation emits HouseholdCreated and JoinCodeGenerated" do
      household = %Household{}

      cmd = %CreateHousehold{
        household_id: "hh-uuid-1",
        name: "The Smith Family",
        created_by: "user-uuid-1"
      }

      events = Household.execute(household, cmd)

      assert [
               %HouseholdCreated{
                 household_id: "hh-uuid-1",
                 name: "The Smith Family",
                 created_by: "user-uuid-1"
               },
               %JoinCodeGenerated{household_id: "hh-uuid-1", code: code}
             ] = events

      assert is_binary(code)
      assert String.length(code) == 8
      assert code == String.upcase(code)
      assert String.match?(code, ~r/^[A-Z0-9]{8}$/)
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

  describe "GenerateJoinCode" do
    test "generates a new join code for an existing household" do
      household = %Household{created: true}
      cmd = %GenerateJoinCode{household_id: "hh-uuid-1"}

      assert [%JoinCodeGenerated{household_id: "hh-uuid-1", code: code}] =
               Household.execute(household, cmd)

      assert is_binary(code)
      assert String.length(code) == 8
      assert String.match?(code, ~r/^[A-Z0-9]{8}$/)
    end

    test "rejects GenerateJoinCode on non-existent household" do
      household = %Household{created: false}
      cmd = %GenerateJoinCode{household_id: "hh-uuid-1"}

      assert {:error, :not_found} = Household.execute(household, cmd)
    end

    test "consecutive codes are different (probabilistic)" do
      household = %Household{created: true}
      cmd = %GenerateJoinCode{household_id: "hh-uuid-1"}

      [%JoinCodeGenerated{code: code1}] = Household.execute(household, cmd)
      [%JoinCodeGenerated{code: code2}] = Household.execute(household, cmd)

      # With 8-char alphanumeric codes there are 36^8 possibilities;
      # collision probability is negligible
      refute code1 == code2
    end
  end

  describe "RenameHousehold" do
    test "renaming an existing household emits HouseholdRenamed" do
      household = %Household{created: true}

      cmd = %RenameHousehold{household_id: "hh-uuid-1", name: "New Name"}

      assert [%HouseholdRenamed{household_id: "hh-uuid-1", name: "New Name"}] =
               Household.execute(household, cmd)
    end

    test "rejects RenameHousehold on non-existent household" do
      household = %Household{created: false}
      cmd = %RenameHousehold{household_id: "hh-uuid-1", name: "Name"}

      assert {:error, :not_found} = Household.execute(household, cmd)
    end
  end
end
