defmodule GroceryHaul.CiConfigTest do
  use ExUnit.Case, async: true

  @ci_path Path.join([File.cwd!(), ".github/workflows/ci.yml"])

  setup_all do
    {:ok, content: File.read!(@ci_path)}
  end

  test "dialyzer job exists in ci.yml", %{content: content} do
    assert content =~ "dialyzer:"
  end

  test "dialyzer job uses MIX_ENV=dev", %{content: content} do
    assert content =~ ~r/dialyzer:.*?MIX_ENV: dev/s
  end

  test "dialyzer job caches PLT under key including mix.lock and .mise.toml", %{content: content} do
    assert content =~ "dialyzer-${{ hashFiles('**/mix.lock', '.mise.toml') }}"
  end

  test "dialyzer job runs mix dialyzer --halt-exit-status", %{content: content} do
    assert content =~ "mix dialyzer --halt-exit-status"
  end

  test "ci.yml triggers on push and pull_request", %{content: content} do
    assert content =~ "push:"
    assert content =~ "pull_request:"
  end
end
