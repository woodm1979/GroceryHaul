defmodule GroceryHaul.Repo.Migrations.DropJoinCodeIndexFk do
  use Ecto.Migration

  def up do
    drop constraint(:join_code_index, "join_code_index_household_id_fkey")
  end

  def down do
    alter table(:join_code_index) do
      modify :household_id, references(:household_projections, type: :binary_id), null: false
    end
  end
end
