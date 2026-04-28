defmodule GroceryHaul.Repo.Migrations.CreateUserProjections do
  use Ecto.Migration

  def change do
    create table(:user_projections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :hashed_password, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_projections, [:email])

    create table(:user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id,
          references(:user_projections, type: :binary_id, on_delete: :delete_all),
          null: false

      add :token, :binary, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_tokens, [:user_id])
    create unique_index(:user_tokens, [:token])
  end
end
