defmodule GroceryHaul.Households.Household do
  @moduledoc false
  defstruct created: false

  alias GroceryHaul.Households.Commands.{CreateHousehold, GenerateJoinCode, RenameHousehold}
  alias GroceryHaul.Households.Events.{HouseholdCreated, HouseholdRenamed, JoinCodeGenerated}

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

  def apply(%__MODULE__{} = household, %HouseholdCreated{}) do
    %{household | created: true}
  end

  def apply(%__MODULE__{} = household, %JoinCodeGenerated{}) do
    household
  end

  def apply(%__MODULE__{} = household, %HouseholdRenamed{}) do
    household
  end

  defp generate_code do
    chars = Enum.concat(?A..?Z, ?0..?9) |> Enum.map(&<<&1>>)
    Enum.map_join(1..8, fn _ -> Enum.random(chars) end)
  end
end
