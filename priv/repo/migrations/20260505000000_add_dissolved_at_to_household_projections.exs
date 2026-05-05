defmodule GroceryHaul.Repo.Migrations.AddDissolvedAtToHouseholdProjections do
  use Ecto.Migration

  def change do
    alter table(:household_projections) do
      add :dissolved_at, :utc_datetime_usec, null: true
    end
  end
end
