defmodule GroceryHaul.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_tokens" do
    field :token, :binary
    belongs_to :user, GroceryHaul.Accounts.UserProjection

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def build_token(%{id: user_id}) do
    token = :crypto.strong_rand_bytes(32)
    %__MODULE__{user_id: user_id, token: token}
  end

  def by_token_query(token) do
    from t in __MODULE__, where: t.token == ^token, preload: :user
  end
end
