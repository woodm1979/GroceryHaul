defmodule GroceryHaul.Households do
  @moduledoc "Context for household creation and membership."
  import Ecto.Query

  alias GroceryHaul.Commanded.Application, as: App

  alias GroceryHaul.Households.Commands.{
    CreateHousehold,
    DemoteAdmin,
    GenerateJoinCode,
    JoinHousehold,
    LeaveHousehold,
    PromoteAdmin,
    RemoveMember,
    RenameHousehold
  }

  alias GroceryHaul.Households.{HouseholdMembersProjection, HouseholdProjection, JoinCodeIndex}
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

  @doc "Regenerates the join code for a household."
  def regenerate_join_code(household_id) do
    App.dispatch(%GenerateJoinCode{household_id: household_id}, consistency: :strong)
  end

  @doc "Returns the current join code entry for a household, or nil."
  def get_join_code(household_id) do
    Repo.one(from j in JoinCodeIndex, where: j.household_id == ^household_id)
  end

  @doc "Looks up a household_id by join code. Returns nil if not found."
  def lookup_join_code(code) do
    Repo.get(JoinCodeIndex, String.upcase(code))
  end

  @doc "Joins a household using a join code. Returns {:ok, household_id} or {:error, reason}."
  def join_via_code(user_id, code) do
    case lookup_join_code(code) do
      nil ->
        {:error, :invalid_code}

      %JoinCodeIndex{household_id: household_id} ->
        case App.dispatch(
               %JoinHousehold{
                 membership_id: "#{household_id}:#{user_id}",
                 household_id: household_id,
                 user_id: user_id,
                 role: :member
               },
               consistency: :strong
             ) do
          :ok -> {:ok, household_id}
          {:error, reason} -> {:error, reason}
        end
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

  @doc "Renames a household."
  def rename_household(household_id, name) do
    App.dispatch(%RenameHousehold{household_id: household_id, name: name}, consistency: :strong)
  end

  @doc "A member leaves a household."
  def leave_household(household_id, user_id) do
    App.dispatch(
      %LeaveHousehold{
        membership_id: "#{household_id}:#{user_id}",
        household_id: household_id,
        user_id: user_id
      },
      consistency: :strong
    )
  end

  @doc "Admin removes a member from a household."
  def remove_member(household_id, user_id) do
    App.dispatch(
      %RemoveMember{
        membership_id: "#{household_id}:#{user_id}",
        household_id: household_id,
        user_id: user_id
      },
      consistency: :strong
    )
  end

  @doc "Promotes a member to admin. Returns {:error, :not_member} if user is not in the household."
  def promote_admin(household_id, user_id) do
    App.dispatch(
      %PromoteAdmin{
        membership_id: "#{household_id}:#{user_id}",
        household_id: household_id,
        user_id: user_id
      },
      consistency: :strong
    )
  end

  @doc """
  Demotes an admin to member. Returns {:error, :sole_admin} if user is the only admin.
  """
  def demote_admin(household_id, user_id) do
    admin_count =
      Repo.aggregate(
        from(m in HouseholdMembersProjection,
          where: m.household_id == ^household_id and m.role == :admin
        ),
        :count
      )

    if admin_count <= 1 do
      {:error, :sole_admin}
    else
      App.dispatch(
        %DemoteAdmin{
          membership_id: "#{household_id}:#{user_id}",
          household_id: household_id,
          user_id: user_id
        },
        consistency: :strong
      )
    end
  end

  @doc "Returns the role of a user in a household, or nil."
  def get_member_role(household_id, user_id) do
    case Repo.one(
           from m in HouseholdMembersProjection,
             where: m.household_id == ^household_id and m.user_id == ^user_id
         ) do
      nil -> nil
      m -> m.role
    end
  end
end
