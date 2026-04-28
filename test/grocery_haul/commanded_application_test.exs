defmodule GroceryHaul.Commanded.ApplicationTest do
  use ExUnit.Case, async: false

  test "GroceryHaul.Commanded.Application is running" do
    assert Process.whereis(GroceryHaul.Commanded.Application) != nil
  end
end
