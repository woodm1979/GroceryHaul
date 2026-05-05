defmodule GroceryHaul.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use GroceryHaul.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias GroceryHaul.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import GroceryHaul.DataCase
    end
  end

  setup tags do
    GroceryHaul.DataCase.setup_sandbox(tags)
    GroceryHaul.DataCase.reset_event_store()
    :ok
  end

  @doc """
  Resets the event store between tests.
  In the test environment, Commanded uses the InMemory adapter.
  Clears streams/events and stops all aggregate processes so their cached
  state is flushed, without touching subscription (projector) processes.
  """
  def reset_event_store do
    event_store = Module.concat([GroceryHaul.Commanded.Application, EventStore])

    aggregates_sup =
      Module.concat([GroceryHaul.Commanded.Application, Commanded.Aggregates.Supervisor])

    :sys.replace_state(event_store, fn state ->
      %{state | streams: %{}, persisted_events: [], next_event_number: 1}
    end)

    for {_, pid, _, _} <- DynamicSupervisor.which_children(aggregates_sup) do
      DynamicSupervisor.terminate_child(aggregates_sup, pid)
    end
  rescue
    _ -> :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(GroceryHaul.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
