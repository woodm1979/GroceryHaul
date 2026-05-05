defmodule GroceryHaul.CiConfigTest do
  use ExUnit.Case, async: true

  @ci_path Path.join([File.cwd!(), ".github/workflows/ci.yml"])

  test "dialyzer job exists in ci.yml" do
    content = File.read!(@ci_path)
    assert content =~ "dialyzer:"
  end

  test "dialyzer job uses MIX_ENV=dev" do
    content = File.read!(@ci_path)
    # The dialyzer section sets MIX_ENV: dev
    assert content =~ ~r/dialyzer:.*?MIX_ENV: dev/s
  end

  test "dialyzer job caches PLT under key including mix.lock and .mise.toml" do
    content = File.read!(@ci_path)
    assert content =~ "dialyzer-${{ hashFiles('**/mix.lock', '.mise.toml') }}"
  end

  test "dialyzer job runs mix dialyzer --halt-exit-status" do
    content = File.read!(@ci_path)
    assert content =~ "mix dialyzer --halt-exit-status"
  end

  test "ci.yml triggers on push and pull_request" do
    content = File.read!(@ci_path)
    assert content =~ "push:"
    assert content =~ "pull_request:"
  end
end
