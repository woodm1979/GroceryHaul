defmodule GroceryHaul.Households.HouseholdAggregateTest do
  use ExUnit.Case, async: true

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

  alias GroceryHaul.Households.Events.{
    AdminDemoted,
    AdminPromoted,
    HouseholdCreated,
    HouseholdRenamed,
    JoinCodeGenerated,
    MemberJoined,
    MemberLeft,
    MemberRemoved
  }

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

  describe "JoinHousehold" do
    test "joining a household as admin emits MemberJoined with admin role" do
      household = %Household{created: true}

      cmd = %JoinHousehold{household_id: "hh-uuid-1", user_id: "user-uuid-1", role: :admin}

      assert [%MemberJoined{household_id: "hh-uuid-1", user_id: "user-uuid-1", role: :admin}] =
               Household.execute(household, cmd)
    end

    test "joining a household as member emits MemberJoined with member role" do
      household = %Household{created: true}

      cmd = %JoinHousehold{household_id: "hh-uuid-1", user_id: "user-uuid-2", role: :member}

      assert [%MemberJoined{household_id: "hh-uuid-1", user_id: "user-uuid-2", role: :member}] =
               Household.execute(household, cmd)
    end

    test "joining when already a member returns :already_member" do
      household = %Household{created: true, members: %{"user-uuid-1" => :admin}}

      cmd = %JoinHousehold{household_id: "hh-uuid-1", user_id: "user-uuid-1", role: :member}

      assert {:error, :already_member} = Household.execute(household, cmd)
    end
  end

  describe "LeaveHousehold" do
    test "member can leave a household" do
      household = %Household{created: true, members: %{"user-uuid-1" => :member}}

      cmd = %LeaveHousehold{household_id: "hh-uuid-1", user_id: "user-uuid-1"}

      assert [%MemberLeft{household_id: "hh-uuid-1", user_id: "user-uuid-1"}] =
               Household.execute(household, cmd)
    end

    test "admin can leave a household" do
      household = %Household{created: true, members: %{"user-uuid-1" => :admin}}

      cmd = %LeaveHousehold{household_id: "hh-uuid-1", user_id: "user-uuid-1"}

      assert [%MemberLeft{household_id: "hh-uuid-1", user_id: "user-uuid-1"}] =
               Household.execute(household, cmd)
    end

    test "cannot leave if not a member" do
      household = %Household{created: true, members: %{}}

      cmd = %LeaveHousehold{household_id: "hh-uuid-1", user_id: "user-uuid-1"}

      assert {:error, :not_member} = Household.execute(household, cmd)
    end
  end

  describe "RemoveMember" do
    test "removing a member emits MemberRemoved" do
      household = %Household{created: true, members: %{"user-uuid-2" => :member}}

      cmd = %RemoveMember{household_id: "hh-uuid-1", user_id: "user-uuid-2"}

      assert [%MemberRemoved{household_id: "hh-uuid-1", user_id: "user-uuid-2"}] =
               Household.execute(household, cmd)
    end

    test "cannot remove if not a member" do
      household = %Household{created: true, members: %{}}

      cmd = %RemoveMember{household_id: "hh-uuid-1", user_id: "user-uuid-2"}

      assert {:error, :not_member} = Household.execute(household, cmd)
    end
  end

  describe "PromoteAdmin" do
    test "a member can be promoted to admin" do
      household = %Household{created: true, members: %{"user-uuid-2" => :member}}

      cmd = %PromoteAdmin{household_id: "hh-uuid-1", user_id: "user-uuid-2"}

      assert [%AdminPromoted{household_id: "hh-uuid-1", user_id: "user-uuid-2"}] =
               Household.execute(household, cmd)
    end

    test "cannot promote if not a member" do
      household = %Household{created: true, members: %{}}

      cmd = %PromoteAdmin{household_id: "hh-uuid-1", user_id: "user-uuid-2"}

      assert {:error, :not_member} = Household.execute(household, cmd)
    end
  end

  describe "DemoteAdmin" do
    test "an admin can be demoted when another admin exists" do
      household = %Household{
        created: true,
        members: %{"user-uuid-1" => :admin, "user-uuid-2" => :admin}
      }

      cmd = %DemoteAdmin{household_id: "hh-uuid-1", user_id: "user-uuid-2"}

      assert [%AdminDemoted{household_id: "hh-uuid-1", user_id: "user-uuid-2"}] =
               Household.execute(household, cmd)
    end

    test "sole admin cannot be demoted - returns {:error, :sole_admin}" do
      household = %Household{
        created: true,
        members: %{"user-uuid-1" => :admin}
      }

      cmd = %DemoteAdmin{household_id: "hh-uuid-1", user_id: "user-uuid-1"}

      assert {:error, :sole_admin} = Household.execute(household, cmd)
    end

    test "cannot demote if not a member" do
      household = %Household{created: true, members: %{}}

      cmd = %DemoteAdmin{household_id: "hh-uuid-1", user_id: "user-uuid-2"}

      assert {:error, :not_member} = Household.execute(household, cmd)
    end
  end

  describe "state tracking via apply/2" do
    test "members map is updated after JoinHousehold → apply MemberJoined" do
      household = %Household{created: true, members: %{}}
      event = %MemberJoined{household_id: "hh-uuid-1", user_id: "user-uuid-1", role: :admin}
      updated = Household.apply(household, event)
      assert updated.members == %{"user-uuid-1" => :admin}
    end

    test "members map is updated after MemberLeft" do
      household = %Household{created: true, members: %{"user-uuid-1" => :member}}
      event = %MemberLeft{household_id: "hh-uuid-1", user_id: "user-uuid-1"}
      updated = Household.apply(household, event)
      assert updated.members == %{}
    end

    test "members map is updated after MemberRemoved" do
      household = %Household{created: true, members: %{"user-uuid-2" => :member}}
      event = %MemberRemoved{household_id: "hh-uuid-1", user_id: "user-uuid-2"}
      updated = Household.apply(household, event)
      assert updated.members == %{}
    end

    test "members map is updated after AdminPromoted" do
      household = %Household{created: true, members: %{"user-uuid-2" => :member}}
      event = %AdminPromoted{household_id: "hh-uuid-1", user_id: "user-uuid-2"}
      updated = Household.apply(household, event)
      assert updated.members == %{"user-uuid-2" => :admin}
    end

    test "members map is updated after AdminDemoted" do
      household = %Household{
        created: true,
        members: %{"user-uuid-1" => :admin, "user-uuid-2" => :admin}
      }

      event = %AdminDemoted{household_id: "hh-uuid-1", user_id: "user-uuid-2"}
      updated = Household.apply(household, event)
      assert updated.members == %{"user-uuid-1" => :admin, "user-uuid-2" => :member}
    end
  end
end
