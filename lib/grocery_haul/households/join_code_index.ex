defmodule GroceryHaul.Households.JoinCodeIndex do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:code, :string, autogenerate: false}
  @foreign_key_type :binary_id
  schema "join_code_index" do
    field :household_id, :binary_id

    timestamps(type: :utc_datetime)
  end
end
