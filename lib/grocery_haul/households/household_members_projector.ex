defmodule GroceryHaul.Households.HouseholdMembersProjector do
  @moduledoc false
  use Commanded.Event.Handler,
    application: GroceryHaul.Commanded.Application,
    name: __MODULE__,
    consistency: :strong,
    start_from: :current

  alias GroceryHaul.Households.Events.MemberJoined
  alias GroceryHaul.Households.HouseholdMembersProjection
  alias GroceryHaul.Repo

  def handle(%MemberJoined{} = event, _metadata) do
    role = if is_binary(event.role), do: String.to_existing_atom(event.role), else: event.role

    %HouseholdMembersProjection{}
    |> Ecto.Changeset.change(%{
      household_id: event.household_id,
      user_id: event.user_id,
      role: role
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:household_id, :user_id])
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
