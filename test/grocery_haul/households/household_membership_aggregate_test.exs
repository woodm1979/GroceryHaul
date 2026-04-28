defmodule GroceryHaul.Households.HouseholdMembershipAggregateTest do
  use ExUnit.Case, async: true

  alias GroceryHaul.Households.Commands.JoinHousehold
  alias GroceryHaul.Households.Events.MemberJoined
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
end
