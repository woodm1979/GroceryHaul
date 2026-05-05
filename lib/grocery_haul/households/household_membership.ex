defmodule GroceryHaul.Households.HouseholdMembership do
  @moduledoc false
  defstruct joined: false, role: nil

  alias GroceryHaul.Households.Commands.{
    DemoteAdmin,
    JoinHousehold,
    LeaveHousehold,
    PromoteAdmin,
    RemoveMember
  }

  alias GroceryHaul.Households.Events.{
    AdminDemoted,
    AdminPromoted,
    MemberJoined,
    MemberLeft,
    MemberRemoved
  }

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

  def execute(%__MODULE__{joined: false}, %LeaveHousehold{}), do: {:error, :not_member}

  def execute(%__MODULE__{joined: true}, %LeaveHousehold{} = cmd) do
    [%MemberLeft{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def execute(%__MODULE__{joined: false}, %RemoveMember{}), do: {:error, :not_member}

  def execute(%__MODULE__{joined: true}, %RemoveMember{} = cmd) do
    [%MemberRemoved{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def execute(%__MODULE__{joined: false}, %PromoteAdmin{}), do: {:error, :not_member}

  def execute(%__MODULE__{joined: true}, %PromoteAdmin{} = cmd) do
    [%AdminPromoted{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def execute(%__MODULE__{joined: false}, %DemoteAdmin{}), do: {:error, :not_member}

  def execute(%__MODULE__{joined: true}, %DemoteAdmin{} = cmd) do
    [%AdminDemoted{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def apply(%__MODULE__{} = membership, %MemberJoined{} = event) do
    %{membership | joined: true, role: event.role}
  end

  def apply(%__MODULE__{} = membership, %MemberLeft{}) do
    %{membership | joined: false, role: nil}
  end

  def apply(%__MODULE__{} = membership, %MemberRemoved{}) do
    %{membership | joined: false, role: nil}
  end

  def apply(%__MODULE__{} = membership, %AdminPromoted{}) do
    %{membership | role: :admin}
  end

  def apply(%__MODULE__{} = membership, %AdminDemoted{}) do
    %{membership | role: :member}
  end
end
