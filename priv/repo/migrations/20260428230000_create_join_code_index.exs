defmodule GroceryHaul.Repo.Migrations.CreateJoinCodeIndex do
  use Ecto.Migration

  def change do
    create table(:join_code_index, primary_key: false) do
      add :code, :string, primary_key: true
      add :household_id, references(:household_projections, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:join_code_index, [:household_id])
  end
end
