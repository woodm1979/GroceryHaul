defmodule GroceryHaul.Accounts.User do
  defstruct registered: false

  alias GroceryHaul.Accounts.Commands.RegisterUser
  alias GroceryHaul.Accounts.Events.UserRegistered

  def execute(%__MODULE__{registered: true}, %RegisterUser{}), do: {:error, :already_registered}

  def execute(%__MODULE__{registered: false}, %RegisterUser{} = cmd) do
    [
      %UserRegistered{
        user_id: cmd.user_id,
        email: cmd.email,
        hashed_password: cmd.hashed_password
      }
    ]
  end

  def apply(%__MODULE__{} = user, %UserRegistered{}) do
    %{user | registered: true}
  end
end
