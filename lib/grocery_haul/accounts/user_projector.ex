defmodule GroceryHaul.Accounts.UserProjector do
  @moduledoc false
  use Commanded.Event.Handler,
    application: GroceryHaul.Commanded.Application,
    name: __MODULE__,
    consistency: :strong,
    start_from: :current

  alias GroceryHaul.Accounts.Events.UserRegistered
  alias GroceryHaul.Accounts.UserProjection
  alias GroceryHaul.Repo

  def handle(%UserRegistered{} = event, _metadata) do
    %UserProjection{}
    |> Ecto.Changeset.change(%{
      id: event.user_id,
      email: event.email,
      hashed_password: event.hashed_password
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: :id)
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
