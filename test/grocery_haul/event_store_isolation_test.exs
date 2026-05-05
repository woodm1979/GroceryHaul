defmodule GroceryHaul.EventStoreIsolationTest do
  # Must be async: false — event store reset is not sandbox-isolated.
  # Test order must be deterministic to prove isolation: the second test
  # dispatches the same command to the same aggregate and expects success,
  # which only holds if the event store was reset between tests.
  use GroceryHaul.DataCase, async: false

  alias GroceryHaul.Households.Commands.CreateHousehold
  alias GroceryHaul.Commanded.Application, as: App

  # Fixed household_id shared across both tests.
  @household_id "00000000-0000-0000-0000-000000000042"

  defp create_cmd do
    %CreateHousehold{
      household_id: @household_id,
      name: "Isolation Test Household",
      created_by: "00000000-0000-0000-0000-000000000099"
    }
  end

  test "A: write a HouseholdCreated event to a fixed stream" do
    assert :ok = App.dispatch(create_cmd())
  end

  test "B: same household stream is empty after reset — create succeeds again" do
    # If the event store was NOT reset, the aggregate would be in created: true
    # state and this dispatch would return {:error, :already_created}.
    assert :ok = App.dispatch(create_cmd())
  end
end
