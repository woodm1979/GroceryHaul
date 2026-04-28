defmodule GroceryHaul.Households.HouseholdProjector do
  @moduledoc false
  use Commanded.Event.Handler,
    application: GroceryHaul.Commanded.Application,
    name: __MODULE__,
    consistency: :strong,
    start_from: :current

  alias GroceryHaul.Households.Events.HouseholdCreated
  alias GroceryHaul.Households.HouseholdProjection
  alias GroceryHaul.Repo

  def handle(%HouseholdCreated{} = event, _metadata) do
    %HouseholdProjection{}
    |> Ecto.Changeset.change(%{
      id: event.household_id,
      name: event.name
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: :id)
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
