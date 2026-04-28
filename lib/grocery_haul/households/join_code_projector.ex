defmodule GroceryHaul.Households.JoinCodeProjector do
  @moduledoc false
  use Commanded.Event.Handler,
    application: GroceryHaul.Commanded.Application,
    name: __MODULE__,
    consistency: :strong,
    start_from: :current

  import Ecto.Query

  alias GroceryHaul.Households.Events.JoinCodeGenerated
  alias GroceryHaul.Households.JoinCodeIndex
  alias GroceryHaul.Repo

  def handle(%JoinCodeGenerated{} = event, _metadata) do
    # Delete old code(s) for this household, then insert new one
    Repo.delete_all(from j in JoinCodeIndex, where: j.household_id == ^event.household_id)

    %JoinCodeIndex{}
    |> Ecto.Changeset.change(%{
      code: event.code,
      household_id: event.household_id
    })
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :code)
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
