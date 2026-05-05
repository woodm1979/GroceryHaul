defmodule GroceryHaul.Households.HouseholdProjection do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "household_projections" do
    field :name, :string
    field :dissolved_at, :utc_datetime_usec

    timestamps(type: :utc_datetime)
  end
end
