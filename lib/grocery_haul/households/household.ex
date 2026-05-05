defmodule GroceryHaul.Households.Household do
  @moduledoc false
  defstruct created: false, members: %{}

  alias GroceryHaul.Households.Commands.{
    CreateHousehold,
    DemoteAdmin,
    DissolveHousehold,
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
    HouseholdDissolved,
    HouseholdRenamed,
    JoinCodeGenerated,
    MemberJoined,
    MemberLeft,
    MemberRemoved
  }

  def execute(%__MODULE__{created: true}, %CreateHousehold{}), do: {:error, :already_created}

  def execute(%__MODULE__{created: false}, %CreateHousehold{} = cmd) do
    [
      %HouseholdCreated{
        household_id: cmd.household_id,
        name: cmd.name,
        created_by: cmd.created_by
      },
      %JoinCodeGenerated{
        household_id: cmd.household_id,
        code: generate_code()
      },
      %MemberJoined{
        household_id: cmd.household_id,
        user_id: cmd.created_by,
        role: :admin
      }
    ]
  end

  def execute(%__MODULE__{created: false}, %GenerateJoinCode{}), do: {:error, :not_found}

  def execute(%__MODULE__{created: true}, %GenerateJoinCode{} = cmd) do
    [%JoinCodeGenerated{household_id: cmd.household_id, code: generate_code()}]
  end

  def execute(%__MODULE__{created: false}, %RenameHousehold{}), do: {:error, :not_found}

  def execute(%__MODULE__{created: true}, %RenameHousehold{} = cmd) do
    [%HouseholdRenamed{household_id: cmd.household_id, name: cmd.name}]
  end

  def execute(%__MODULE__{members: members}, %JoinHousehold{user_id: user_id})
      when is_map_key(members, user_id),
      do: {:error, :already_member}

  def execute(%__MODULE__{}, %JoinHousehold{} = cmd) do
    [%MemberJoined{household_id: cmd.household_id, user_id: cmd.user_id, role: cmd.role}]
  end

  def execute(%__MODULE__{members: members}, %LeaveHousehold{user_id: user_id})
      when not is_map_key(members, user_id),
      do: {:error, :not_member}

  def execute(%__MODULE__{}, %LeaveHousehold{} = cmd) do
    [%MemberLeft{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def execute(%__MODULE__{members: members}, %RemoveMember{user_id: user_id})
      when not is_map_key(members, user_id),
      do: {:error, :not_member}

  def execute(%__MODULE__{}, %RemoveMember{} = cmd) do
    [%MemberRemoved{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def execute(%__MODULE__{members: members}, %PromoteAdmin{user_id: user_id})
      when not is_map_key(members, user_id),
      do: {:error, :not_member}

  def execute(%__MODULE__{}, %PromoteAdmin{} = cmd) do
    [%AdminPromoted{household_id: cmd.household_id, user_id: cmd.user_id}]
  end

  def execute(%__MODULE__{members: members}, %DemoteAdmin{user_id: user_id})
      when not is_map_key(members, user_id),
      do: {:error, :not_member}

  def execute(%__MODULE__{members: members}, %DemoteAdmin{} = cmd) do
    admin_count = Enum.count(members, fn {_, role} -> role == :admin end)

    if admin_count <= 1 do
      {:error, :sole_admin}
    else
      [%AdminDemoted{household_id: cmd.household_id, user_id: cmd.user_id}]
    end
  end

  def execute(%__MODULE__{created: false}, %DissolveHousehold{}), do: {:error, :not_found}

  def execute(%__MODULE__{members: members}, %DissolveHousehold{user_id: user_id})
      when not is_map_key(members, user_id),
      do: {:error, :not_admin}

  def execute(%__MODULE__{members: members}, %DissolveHousehold{user_id: user_id})
      when :erlang.map_get(user_id, members) != :admin,
      do: {:error, :not_admin}

  def execute(%__MODULE__{}, %DissolveHousehold{} = cmd) do
    [%HouseholdDissolved{household_id: cmd.household_id, dissolved_at: DateTime.utc_now()}]
  end

  def apply(%__MODULE__{} = household, %HouseholdCreated{}) do
    %{household | created: true}
  end

  def apply(%__MODULE__{} = household, %JoinCodeGenerated{}) do
    household
  end

  def apply(%__MODULE__{} = household, %HouseholdRenamed{}) do
    household
  end

  def apply(%__MODULE__{members: members} = household, %MemberJoined{} = event) do
    %{household | members: Map.put(members, event.user_id, event.role)}
  end

  def apply(%__MODULE__{members: members} = household, %MemberLeft{} = event) do
    %{household | members: Map.delete(members, event.user_id)}
  end

  def apply(%__MODULE__{members: members} = household, %MemberRemoved{} = event) do
    %{household | members: Map.delete(members, event.user_id)}
  end

  def apply(%__MODULE__{members: members} = household, %AdminPromoted{} = event) do
    %{household | members: Map.put(members, event.user_id, :admin)}
  end

  def apply(%__MODULE__{members: members} = household, %AdminDemoted{} = event) do
    %{household | members: Map.put(members, event.user_id, :member)}
  end

  def apply(%__MODULE__{} = household, %HouseholdDissolved{}) do
    household
  end

  defp generate_code do
    chars = Enum.concat(?A..?Z, ?0..?9) |> Enum.map(&<<&1>>)
    Enum.map_join(1..8, fn _ -> Enum.random(chars) end)
  end
end
