defmodule GroceryHaul.Households.HouseholdCreationProcessManager do
  @moduledoc "Listens for HouseholdCreated and auto-joins the creator as admin."

  use Commanded.ProcessManagers.ProcessManager,
    application: GroceryHaul.Commanded.Application,
    name: __MODULE__

  alias GroceryHaul.Households.Commands.JoinHousehold
  alias GroceryHaul.Households.Events.HouseholdCreated

  @derive Jason.Encoder
  defstruct [:household_id]

  def interested?(%HouseholdCreated{household_id: household_id}),
    do: {:start, household_id}

  def interested?(_), do: false

  def handle(%__MODULE__{}, %HouseholdCreated{} = event) do
    %JoinHousehold{
      household_id: event.household_id,
      user_id: event.created_by,
      role: :admin
    }
  end

  def apply(%__MODULE__{} = pm, %HouseholdCreated{household_id: household_id}) do
    %__MODULE__{pm | household_id: household_id}
  end
end
