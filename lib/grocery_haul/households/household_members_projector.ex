defmodule GroceryHaul.Households.HouseholdMembersProjector do
  @moduledoc false
  use Commanded.Event.Handler,
    application: GroceryHaul.Commanded.Application,
    name: __MODULE__,
    consistency: :strong,
    start_from: :current

  import Ecto.Query

  alias GroceryHaul.Households.Events.{AdminDemoted, AdminPromoted, MemberJoined, MemberLeft, MemberRemoved}
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

  def handle(%MemberLeft{} = event, _metadata) do
    Repo.delete_all(
      from m in HouseholdMembersProjection,
        where: m.household_id == ^event.household_id and m.user_id == ^event.user_id
    )

    :ok
  end

  def handle(%MemberRemoved{} = event, _metadata) do
    Repo.delete_all(
      from m in HouseholdMembersProjection,
        where: m.household_id == ^event.household_id and m.user_id == ^event.user_id
    )

    :ok
  end

  def handle(%AdminPromoted{} = event, _metadata) do
    Repo.update_all(
      from(m in HouseholdMembersProjection,
        where: m.household_id == ^event.household_id and m.user_id == ^event.user_id
      ),
      set: [role: :admin]
    )

    :ok
  end

  def handle(%AdminDemoted{} = event, _metadata) do
    Repo.update_all(
      from(m in HouseholdMembersProjection,
        where: m.household_id == ^event.household_id and m.user_id == ^event.user_id
      ),
      set: [role: :member]
    )

    :ok
  end
end
