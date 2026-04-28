defmodule GroceryHaul.Repo.Migrations.CreateHouseholdProjections do
  use Ecto.Migration

  def change do
    create table(:household_projections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:household_members_projections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :household_id, references(:household_projections, type: :binary_id), null: false
      add :user_id, :binary_id, null: false
      add :role, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:household_members_projections, [:household_id])
    create index(:household_members_projections, [:user_id])
    create unique_index(:household_members_projections, [:household_id, :user_id])
  end
end
