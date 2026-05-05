defmodule GroceryHaul.EventStoreIsolationTest do
  # Must be async: false — event store reset is not sandbox-isolated.
  # Test order must be deterministic to prove isolation: the second test
  # dispatches the same command to the same aggregate and expects success,
  # which only holds if the event store was reset between tests.
  use GroceryHaul.DataCase, async: false

  alias GroceryHaul.Households.Commands.JoinHousehold
  alias GroceryHaul.Commanded.Application, as: App

  # Fixed membership_id shared across both tests.
  @membership_id "isolation-test-membership-42"
  @household_id "00000000-0000-0000-0000-000000000042"
  @user_id "00000000-0000-0000-0000-000000000099"

  defp join_cmd do
    %JoinHousehold{
      membership_id: @membership_id,
      household_id: @household_id,
      user_id: @user_id,
      role: :member
    }
  end

  test "A: write a MemberJoined event to a fixed stream" do
    assert :ok = App.dispatch(join_cmd())
  end

  test "B: same membership stream is empty after reset — join succeeds again" do
    # If the event store was NOT reset, the aggregate would be in joined: true
    # state and this dispatch would return {:error, :already_member}.
    assert :ok = App.dispatch(join_cmd())
  end
end
