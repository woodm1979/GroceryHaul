defmodule GroceryHaul.Repo do
  use Ecto.Repo,
    otp_app: :grocery_haul,
    adapter: Ecto.Adapters.Postgres
end
