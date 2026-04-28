defmodule GroceryHaul.Households.HouseholdMembership do
  @moduledoc false
  defstruct joined: false, role: nil

  alias GroceryHaul.Households.Commands.JoinHousehold
  alias GroceryHaul.Households.Events.MemberJoined

  def execute(%__MODULE__{joined: true}, %JoinHousehold{}), do: {:error, :already_member}

  def execute(%__MODULE__{joined: false}, %JoinHousehold{} = cmd) do
    [
      %MemberJoined{
        household_id: cmd.household_id,
        user_id: cmd.user_id,
        role: cmd.role
      }
    ]
  end

  def apply(%__MODULE__{} = membership, %MemberJoined{} = event) do
    %{membership | joined: true, role: event.role}
  end
end
