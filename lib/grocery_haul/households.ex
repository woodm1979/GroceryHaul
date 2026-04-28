defmodule GroceryHaul.Households do
  @moduledoc "Context for household creation and membership."
  import Ecto.Query

  alias GroceryHaul.Commanded.Application, as: App
  alias GroceryHaul.Households.Commands.{CreateHousehold, JoinHousehold}
  alias GroceryHaul.Households.{HouseholdMembersProjection, HouseholdProjection}
  alias GroceryHaul.Repo

  @doc "Creates a household and auto-joins the creator as admin."
  def create_household(user_id, name) do
    household_id = Ecto.UUID.generate()

    with :ok <-
           App.dispatch(
             %CreateHousehold{household_id: household_id, name: name, created_by: user_id},
             consistency: :strong
           ),
         :ok <-
           App.dispatch(
             %JoinHousehold{
               membership_id: "#{household_id}:#{user_id}",
               household_id: household_id,
               user_id: user_id,
               role: :admin
             },
             consistency: :strong
           ) do
      {:ok, household_id}
    end
  end

  @doc "Gets a household projection by id."
  def get_household(id), do: Repo.get(HouseholdProjection, id)

  @doc "Lists all members of a household."
  def list_members(household_id) do
    Repo.all(from m in HouseholdMembersProjection, where: m.household_id == ^household_id)
  end

  @doc "Lists all households a user belongs to."
  def list_households_for_user(user_id) do
    Repo.all(
      from m in HouseholdMembersProjection,
        where: m.user_id == ^user_id,
        join: h in HouseholdProjection,
        on: h.id == m.household_id,
        select: h
    )
  end
end
