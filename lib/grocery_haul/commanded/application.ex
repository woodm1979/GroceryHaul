defmodule GroceryHaul.Commanded.Application do
  @moduledoc false
  use Commanded.Application, otp_app: :grocery_haul

  router(GroceryHaul.Accounts.Router)
  router(GroceryHaul.Households.Router)
end
