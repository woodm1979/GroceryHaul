defmodule GroceryHaul.Households.HouseholdMembersProjection do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "household_members_projections" do
    field :household_id, :binary_id
    field :user_id, :binary_id
    field :role, Ecto.Enum, values: [:member, :admin]

    timestamps(type: :utc_datetime)
  end
end
