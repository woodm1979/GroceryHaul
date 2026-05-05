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

  # Projector processes are intentionally left running — only aggregate state is flushed.
  # Subscription checkpoints must also be reset so projectors see new events after the
  # event store is cleared (InMemory uses global event numbers; stale checkpoints cause
  # new events to be silently skipped).
  # last_seen_event in each handler must be reset to nil: if left set, new events whose
  # event_number <= last_seen_event are silently skipped as "already seen" after reset.
  def reset_event_store do
    event_store = Module.concat([GroceryHaul.Commanded.Application, EventStore])
    registry = Module.concat([GroceryHaul.Commanded.Application, LocalRegistry])

    aggregates_sup =
      Module.concat([GroceryHaul.Commanded.Application, Commanded.Aggregates.Supervisor])

    :sys.replace_state(event_store, fn state ->
      reset_subs = Map.new(state.persistent_subscriptions, &reset_sub/1)

      %{
        state
        | streams: %{},
          persisted_events: [],
          next_event_number: 1,
          persistent_subscriptions: reset_subs
      }
    end)

    Registry.select(registry, [{{{:_, Commanded.Event.Handler, :_}, :"$1", :_}, [], [:"$1"]}])
    |> Enum.each(fn pid ->
      :sys.replace_state(pid, fn state -> %{state | last_seen_event: nil} end)
    end)

    for {_, pid, _, _} <- DynamicSupervisor.which_children(aggregates_sup) do
      DynamicSupervisor.terminate_child(aggregates_sup, pid)
    end
  rescue
    _ -> :ok
  catch
    :exit, _ -> :ok
  end

  defp reset_sub({name, sub}) do
    reset_subscribers =
      Enum.map(sub.subscribers, &%{&1 | in_flight_events: [], pending_events: []})

    {name, %{sub | checkpoint: 0, subscribers: reset_subscribers}}
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
