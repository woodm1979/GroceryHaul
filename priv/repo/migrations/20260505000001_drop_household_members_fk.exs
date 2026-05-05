defmodule GroceryHaul.Repo.Migrations.DropHouseholdMembersFk do
  use Ecto.Migration

  def up do
    drop constraint(
           :household_members_projections,
           "household_members_projections_household_id_fkey"
         )
  end

  def down do
    alter table(:household_members_projections) do
      modify :household_id, references(:household_projections, type: :binary_id), null: false
    end
  end
end
