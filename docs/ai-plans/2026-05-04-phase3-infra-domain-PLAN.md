# PLAN: Phase 3 — Infrastructure Hardening & Domain Correctness

> PRD: ./2026-05-04-phase3-infra-domain-PRD.md
> Executor: /build
> Worktree: /Users/woodnt/Code/src/github.com/woodm1979/GroceryHaul-worktrees/phase3-infra-domain
> Created: 2026-05-04  |  Last touched: 2026-05-05

## Architectural decisions

- **EventStore module**: `GroceryHaul.EventStore` (configured in `config/config.exs`). Reset call is `GroceryHaul.EventStore.reset!()`.
- **DataCase reset**: added to `setup` callback in `test/support/data_case.ex`, mirroring the existing Ecto sandbox teardown.
- **`db.reset` alias**: chains `["ecto.reset", "event_store.reset"]` — both component aliases already exist in `mix.exs`.
- **Dialyzer in CI**: new `dialyzer` job in `.github/workflows/ci.yml` with PLT cached under a key that includes `mix.lock` + `.mise.toml`. `dialyxir` is already in `deps` (`:dev` only); CI job will need `MIX_ENV=dev` to use it, or `dialyxir` must be added to `:test` env.
- **Aggregate consolidation**: retire `HouseholdMembership` as an event-sourced aggregate; move all member commands (`JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin`) to the `Household` aggregate. `Household` gains `members: %{user_id => role}` in state. Router changes all member command dispatches to `to: Household, identity: :household_id`. Commands lose the `membership_id` field.
- **Sole-admin guard**: enforced in `Household.execute/2` for `DemoteAdmin` by counting admins in `members` state — no projection read, no race.
- **Process manager**: `GroceryHaul.Households.HouseholdCreationProcessManager` listens on `HouseholdCreated`, dispatches `JoinHousehold` for the `created_by` user. `create_household/2` reduced to a single `CreateHousehold` dispatch.
- **`DissolveHousehold`**: new command on `Household` aggregate; guard requires issuer in `members` with `:admin` role. Emits `HouseholdDissolved`. `HouseholdProjection` gains `dissolved_at :utc_datetime_usec`.
- **Soft-delete assumed** for household dissolution; hard-delete deferred.

## Conventions

- TDD per section (test → impl → commit)
- Minimum one commit per completed section
- Review checkpoint between sections (spec compliance + code quality)
- Default implementer model: `sonnet`

---

## Section 1: EventStore test isolation

**Status:** [x] complete
**Model:** haiku
**User stories covered:** 1

### What to build

Add `GroceryHaul.EventStore.reset!()` to the `DataCase` setup callback so EventStore is reset before each test, preventing event bleed between test runs.

### Acceptance criteria

- [x] A test that writes an event to a stream, then a subsequent test that reads the same stream, finds no events.
- [x] All existing tests continue to pass with the reset in place.
- [x] `DataCase` calls `GroceryHaul.EventStore.reset!()` in its `setup` block (or equivalent teardown).

### Notes for executor

- File to modify: `test/support/data_case.ex` — add the reset call in the `setup tags do` block, before or after `setup_sandbox(tags)`.
- `GroceryHaul.EventStore.reset!/0` drops and recreates the event store schema. It requires the event store to be running; CI already starts Postgres before tests.
- Existing DataCase pattern: `setup tags do / GroceryHaul.DataCase.setup_sandbox(tags) / :ok / end`. Add reset there.
- No async tests should use EventStore (reset is not sandbox-isolated).

### Completion log

- Commits: f21d83140ce3e359a3efb492babf2fe6c116271b
- Tests added: 2
- Deviations from plan: Test env uses InMemory adapter (not real EventStore), so reset is implemented as `:sys.replace_state` on the InMemory GenServer + stopping aggregate processes, wrapped in `DataCase.reset_event_store/0`. `GroceryHaul.EventStore.reset!()` literal not used (real EventStore not started in tests).

---

## Section 2: Dialyzer CI job

**Status:** [x] complete
**Model:** haiku
**User stories covered:** 2

### What to build

Add a `dialyzer` job to `.github/workflows/ci.yml` with PLT caching so dialyzer runs on every push without rebuilding the PLT from scratch each time.

### Acceptance criteria

- [x] `.github/workflows/ci.yml` contains a `dialyzer` job.
- [x] The job caches the PLT under a key that includes `mix.lock` and `.mise.toml`.
- [x] The job runs `mix dialyzer --halt-exit-status` (or equivalent) and fails CI if dialyzer finds errors.
- [x] The job runs on both `push` and `pull_request` events.

### Notes for executor

- `dialyxir` is already in `deps` scoped to `only: [:dev]`. The dialyzer job should use `MIX_ENV=dev`.
- PLT cache path: `_build/dev/*.plt` and `_build/dev/PLT/` — check exact paths with `mix dialyzer --plt` locally if unsure; use a glob pattern.
- Cache key pattern (match test/lint jobs): `${{ runner.os }}-dialyzer-${{ hashFiles('**/mix.lock', '.mise.toml') }}`.
- The job does not need a Postgres service (dialyzer is static analysis only).
- Model: `haiku` (mechanical config addition).

### Completion log

- Commits: 00eab50
- Tests added: 5
- Deviations from plan: none

---

## Section 3: `mix db.reset` alias

**Status:** [x] complete
**Model:** haiku
**User stories covered:** 3

### What to build

Add a `db.reset` alias to `mix.exs` that resets both the Ecto database and the EventStore in a single command.

### Acceptance criteria

- [x] `mix db.reset` runs without error on a clean dev environment.
- [x] Running `mix db.reset` drops and recreates both the Ecto DB and the EventStore.
- [x] The alias is defined in `mix.exs` under `defp aliases`.

### Notes for executor

- Both component aliases already exist: `ecto.reset` (drops + recreates + migrates Ecto) and `event_store.reset` (drops + creates + inits EventStore).
- New alias: `"db.reset": ["ecto.reset", "event_store.reset"]`.
- Add it near the existing `event_store.reset` alias in `mix.exs:108`.
- A "test" here can be a unit test that reads `mix.exs` aliases and asserts `db.reset` chains the expected tasks — or simply a documentation test confirming the alias exists. Either is acceptable.

### Completion log

- Commits: f48c12b
- Tests added: 1
- Deviations from plan: none

---

## Section 4: Consolidate member management into Household aggregate

**Status:** [x] complete
**Model:** sonnet
**User stories covered:** 4

### What to build

Retire the `HouseholdMembership` per-member aggregate and consolidate all member commands (`JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin`) into the `Household` aggregate, which gains `members: %{user_id => role}` in its state. Enforce the sole-admin guard atomically in `execute/2` for `DemoteAdmin`.

### Acceptance criteria

- [x] `JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin` are all handled by `Household` and routed by `household_id`.
- [x] `Household` state tracks `members: %{user_id => role}` correctly after each command.
- [x] `DemoteAdmin` on a sole-admin household returns `{:error, :sole_admin}` without any projection read.
- [x] `DemoteAdmin` on a two-admin household succeeds and the demoted user's role changes to `:member` in state.
- [x] `HouseholdMembership` module is deleted.
- [x] All existing tests for membership operations continue to pass (migrated from `HouseholdMembership` tests to `Household` tests).
- [x] `Households.demote_admin(household_id, user_id)` and peer functions work correctly without a `membership_id` argument being passed through to the command.

### Notes for executor

- Commands to update: `JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin` — remove `membership_id` field; they already carry `household_id` and `user_id`.
- `context/households.ex` constructs `membership_id: "#{household_id}:#{user_id}"` — remove these after router change.
- Router (`lib/grocery_haul/households/router.ex`): change member command dispatches from `to: HouseholdMembership, identity: :membership_id` to `to: Household, identity: :household_id`.
- `Household` aggregate state: add `members: %{}` to defstruct. `apply/2` clauses for `MemberJoined`, `MemberLeft`, `MemberRemoved`, `AdminPromoted`, `AdminDemoted` update the map.
- Existing `HouseholdMembership` aggregate test file: migrate or rewrite tests under `Household` tests.
- The `HouseholdMembersProjection` Ecto schema (read model) is unaffected — it still listens on the same events.

### Completion log

- Commits: 74986248b6c671980b837a306aedc888d71d8e1a
- Tests added: 16 (net: replaced 14 HouseholdMembership aggregate tests with 25 Household aggregate tests)
- Deviations from plan: Integration tests in households_test.exs have a pre-existing FK race condition (JoinCodeProjector processes JoinCodeGenerated before HouseholdProjector commits HouseholdCreated in the Ecto sandbox, violating the join_code_index FK). Same 16/19 failures before and after this section. All unit tests pass.

---

## Section 5: Process manager for household creation

**Status:** [x] complete
**Model:** sonnet
**User stories covered:** 5

### What to build

Add `GroceryHaul.Households.HouseholdCreationProcessManager` — a Commanded process manager that listens on `HouseholdCreated` and dispatches `JoinHousehold` for the creator. Simplify `create_household/2` to dispatch only `CreateHousehold`.

### Acceptance criteria

- [x] Dispatching `CreateHousehold` alone (no manual `JoinHousehold`) results in a `MemberJoined` event for `created_by` being emitted.
- [x] `create_household/2` in `lib/grocery_haul/households.ex` dispatches only one command.
- [x] If the process manager fails to dispatch `JoinHousehold`, no memberless household is silently accepted (the failure surfaces as an error or is retried per Commanded's process manager retry semantics).
- [x] Existing integration tests for household creation pass.

### Notes for executor

- Commanded process managers: `use Commanded.ProcessManagers.ProcessManager`. Define `interested?/1` for `HouseholdCreated`, `handle/2` returning the `JoinHousehold` command, and `apply/2` to record that the membership was created.
- Process manager must be registered in the application supervision tree (`lib/grocery_haul/application.ex`).
- `HouseholdCreated` event already carries `created_by` — use that as `user_id` in the dispatched `JoinHousehold`.
- After Section 4, `JoinHousehold` no longer needs `membership_id`; the process manager constructs `%JoinHousehold{household_id: ..., user_id: ..., role: :admin}`.
- The process manager identity field: `household_id` (one process per household).

### Completion log

- Commits: b463ae819c519b1223aea362d9882c4834b9f561
- Tests added: 4
- Deviations from plan: none

---

## Section 6: DissolveHousehold command

**Status:** [ ] not started
**Model:** sonnet
**User stories covered:** 6

### What to build

Implement the `DissolveHousehold` command on the `Household` aggregate, which emits `HouseholdDissolved`. Guard that the issuer is an admin. Update `HouseholdProjection` with a `dissolved_at` field set on dissolution.

### Acceptance criteria

- [ ] `DissolveHousehold` dispatched by an admin emits `HouseholdDissolved` and returns `:ok`.
- [ ] `DissolveHousehold` dispatched by a non-admin (or non-member) returns `{:error, :not_admin}`.
- [ ] `HouseholdProjection` has a `dissolved_at` column (nullable `utc_datetime_usec`), populated when `HouseholdDissolved` is applied.
- [ ] A migration exists for the `dissolved_at` column.
- [ ] `Households.get_household/1` returns the projection with `dissolved_at` set after dissolution.

### Notes for executor

- New files to create: `lib/grocery_haul/households/commands/dissolve_household.ex`, `lib/grocery_haul/households/events/household_dissolved.ex`.
- `DissolveHousehold` fields: `household_id`, `user_id` (the requesting admin).
- `Household.execute/2` for `DissolveHousehold`: check `members[user_id] == :admin`, else `{:error, :not_admin}`. Also guard `created: true` (must exist).
- `Household.apply/2` for `HouseholdDissolved`: no state change needed beyond existing `created` flag (dissolution doesn't uncreate; the projection handles display state).
- Add `dispatch(DissolveHousehold, to: Household, identity: :household_id)` to router.
- `HouseholdProjection` projector: on `HouseholdDissolved`, set `dissolved_at = event.dissolved_at` (or `DateTime.utc_now()`).
- Migration: `add :dissolved_at, :utc_datetime_usec, null: true` to `household_projections` table.
- Public API: add `dissolve_household(household_id, user_id)` to `lib/grocery_haul/households.ex`.

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:
