defmodule GroceryHaul.Households.HouseholdMembershipAggregateTest do
  use ExUnit.Case, async: true

  alias GroceryHaul.Households.Commands.{JoinHousehold, LeaveHousehold, RemoveMember, PromoteAdmin, DemoteAdmin}
  alias GroceryHaul.Households.Events.{MemberJoined, MemberLeft, MemberRemoved, AdminPromoted, AdminDemoted}
  alias GroceryHaul.Households.HouseholdMembership

  describe "JoinHousehold" do
    test "joining a household as admin emits MemberJoined with admin role" do
      membership = %HouseholdMembership{}

      cmd = %JoinHousehold{
        membership_id: "hh-uuid-1:user-uuid-1",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-1",
        role: :admin
      }

      assert [
               %MemberJoined{
                 household_id: "hh-uuid-1",
                 user_id: "user-uuid-1",
                 role: :admin
               }
             ] = HouseholdMembership.execute(membership, cmd)
    end

    test "joining a household as member emits MemberJoined with member role" do
      membership = %HouseholdMembership{}

      cmd = %JoinHousehold{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2",
        role: :member
      }

      assert [
               %MemberJoined{
                 household_id: "hh-uuid-1",
                 user_id: "user-uuid-2",
                 role: :member
               }
             ] = HouseholdMembership.execute(membership, cmd)
    end

    test "joining when already a member is rejected" do
      membership = %HouseholdMembership{joined: true}

      cmd = %JoinHousehold{
        membership_id: "hh-uuid-1:user-uuid-1",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-1",
        role: :member
      }

      assert {:error, :already_member} = HouseholdMembership.execute(membership, cmd)
    end
  end

  describe "LeaveHousehold" do
    test "member can leave a household" do
      membership = %HouseholdMembership{joined: true, role: :member}

      cmd = %LeaveHousehold{
        membership_id: "hh-uuid-1:user-uuid-1",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-1"
      }

      assert [%MemberLeft{household_id: "hh-uuid-1", user_id: "user-uuid-1"}] =
               HouseholdMembership.execute(membership, cmd)
    end

    test "admin can leave a household" do
      membership = %HouseholdMembership{joined: true, role: :admin}

      cmd = %LeaveHousehold{
        membership_id: "hh-uuid-1:user-uuid-1",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-1"
      }

      assert [%MemberLeft{household_id: "hh-uuid-1", user_id: "user-uuid-1"}] =
               HouseholdMembership.execute(membership, cmd)
    end

    test "cannot leave if not a member" do
      membership = %HouseholdMembership{joined: false}

      cmd = %LeaveHousehold{
        membership_id: "hh-uuid-1:user-uuid-1",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-1"
      }

      assert {:error, :not_member} = HouseholdMembership.execute(membership, cmd)
    end
  end

  describe "RemoveMember" do
    test "removing a non-self member emits MemberRemoved" do
      membership = %HouseholdMembership{joined: true, role: :member}

      cmd = %RemoveMember{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2"
      }

      assert [%MemberRemoved{household_id: "hh-uuid-1", user_id: "user-uuid-2"}] =
               HouseholdMembership.execute(membership, cmd)
    end

    test "cannot remove if not a member" do
      membership = %HouseholdMembership{joined: false}

      cmd = %RemoveMember{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2"
      }

      assert {:error, :not_member} = HouseholdMembership.execute(membership, cmd)
    end
  end

  describe "PromoteAdmin" do
    test "a member can be promoted to admin" do
      membership = %HouseholdMembership{joined: true, role: :member}

      cmd = %PromoteAdmin{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2"
      }

      assert [%AdminPromoted{household_id: "hh-uuid-1", user_id: "user-uuid-2"}] =
               HouseholdMembership.execute(membership, cmd)
    end

    test "cannot promote if not a member" do
      membership = %HouseholdMembership{joined: false}

      cmd = %PromoteAdmin{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2"
      }

      assert {:error, :not_member} = HouseholdMembership.execute(membership, cmd)
    end
  end

  describe "DemoteAdmin" do
    test "an admin can be demoted to member" do
      membership = %HouseholdMembership{joined: true, role: :admin}

      cmd = %DemoteAdmin{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2"
      }

      assert [%AdminDemoted{household_id: "hh-uuid-1", user_id: "user-uuid-2"}] =
               HouseholdMembership.execute(membership, cmd)
    end

    test "cannot demote if not a member" do
      membership = %HouseholdMembership{joined: false}

      cmd = %DemoteAdmin{
        membership_id: "hh-uuid-1:user-uuid-2",
        household_id: "hh-uuid-1",
        user_id: "user-uuid-2"
      }

      assert {:error, :not_member} = HouseholdMembership.execute(membership, cmd)
    end
  end
end
