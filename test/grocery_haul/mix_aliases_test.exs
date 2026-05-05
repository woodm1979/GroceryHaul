defmodule GroceryHaul.MixAliasesTest do
  use ExUnit.Case, async: true

  @mix_exs_path Path.join([File.cwd!(), "mix.exs"])

  test "db.reset alias chains ecto.reset and event_store.reset" do
    content = File.read!(@mix_exs_path)
    assert content =~ ~s("db.reset": ["ecto.reset", "event_store.reset"])
  end
end
