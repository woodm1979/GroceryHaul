defmodule GroceryHaul.Accounts.UserProjection do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "user_projections" do
    field :email, :string
    field :hashed_password, :string

    timestamps(type: :utc_datetime)
  end
end
