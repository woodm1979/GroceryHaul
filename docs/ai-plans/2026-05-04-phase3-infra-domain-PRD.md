# PRD: Phase 3 — Infrastructure Hardening & Domain Correctness

> Status: draft
> Plan: ./2026-05-04-phase3-infra-domain-PLAN.md
> Created: 2026-05-04  |  Last touched: 2026-05-04

## Problem

Two classes of gaps exist before the application is production-ready.

The first class is infrastructure: EventStore state bleeds between test runs because no reset helper exists in `DataCase`, dialyzer is not run in CI and has no cached PLT, and there is no single `mix db.reset` command that resets both databases together (an `event_store.reset` alias exists but there is no combined shortcut).

The second class is domain correctness: the sole-admin guard on `DemoteAdmin` is a read-before-dispatch race in the context layer (two concurrent calls can both observe "2 admins" and both succeed, leaving zero admins), household creation is not atomic (if the `JoinHousehold` dispatch fails after `CreateHousehold` succeeds, a memberless household persists), and there is no way to dissolve a household once it is no longer needed.

## Solution

Address the infrastructure gaps: add `GroceryHaul.EventStore.reset!()` to `DataCase`; add a `dialyzer` CI job with PLT caching to `.github/workflows/ci.yml`; add a `db.reset` mix alias that chains the existing `ecto.reset` and `event_store.reset` aliases.

Address the domain correctness gaps by consolidating all member commands into the `Household` aggregate so it tracks `members: %{user_id => role}` and can enforce the sole-admin invariant atomically; by introducing a `HouseholdCreationProcessManager` that listens on `HouseholdCreated` and dispatches `JoinHousehold` for the creator (removing the two-dispatch sequence from `create_household/2`); and by implementing a `DissolveHousehold` command with a `HouseholdDissolved` event that only an admin can trigger.

## User stories

1. As a developer, tests run in isolation — no EventStore state bleeds between test runs.
2. As a developer, CI runs dialyzer with a cached PLT so type errors are caught on every push.
3. As a developer, `mix db.reset` resets both Ecto and EventStore databases in one command.
4. As an admin, two concurrent `DemoteAdmin` calls cannot leave a household with zero admins.
5. As the system, if the creator-membership step fails after household creation, no memberless household persists.
6. As an admin, I can dissolve a household I administer, removing it from active state.

## Architecture & module sketch

- **DataCase (`test/support/data_case.ex`)** — add `GroceryHaul.EventStore.reset!()` in the `setup` callback so EventStore is cleared alongside the Ecto sandbox on each test.
- **`mix.exs` aliases** — add `db.reset` alias: `["ecto.reset", "event_store.reset"]`. Both component aliases already exist.
- **`.github/workflows/ci.yml`** — add `dialyzer` job with PLT cache step (cache key on `mix.lock` + `.mise.toml`). Lint job and cache key already include `.mise.toml`; no changes needed there.
- **`Household` aggregate** — consolidate all member commands (`JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin`) into the `Household` aggregate (replacing `HouseholdMembership`). `Household` tracks `members: %{user_id => role}` in state. All member events are emitted from the `Household` stream. Sole-admin guard enforced in `execute/2` for `DemoteAdmin`.
- **Router** — change all member command dispatches to use `to: Household, identity: :household_id`. Retire `HouseholdMembership` as an event-sourced aggregate.
- **`HouseholdCreationProcessManager`** — Commanded process manager listening on `HouseholdCreated`; dispatches `JoinHousehold` for `created_by`. Simplifies `create_household/2` to a single `CreateHousehold` dispatch.
- **`DissolveHousehold` command / `HouseholdDissolved` event** — new command on the `Household` aggregate; guards that the issuer is in `members` with role `:admin`; emits `HouseholdDissolved`. `HouseholdProjection` gains a `dissolved_at` field.

## Testing approach

TDD throughout: write a failing test first for every item, then implement. Key behaviors to cover:

- EventStore isolation: verify that an event written in one test does not appear in a subsequent test's stream (run two tests sequentially against the same stream ID; second test should see no events).
- Dialyzer CI job: verify the job exists in `ci.yml` with a cache step.
- `mix db.reset`: verify the alias exists in `mix.exs` and chains `ecto.reset` and `event_store.reset`.
- Sole-admin guard: dispatch `DemoteAdmin` on a sole-admin household and assert `{:error, :sole_admin}`; dispatch on a two-admin household and assert success.
- Aggregate consolidation: verify `JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin` all route to `Household` and emit expected events.
- Process manager: verify that dispatching `CreateHousehold` alone (without a manual `JoinHousehold`) results in a `MemberJoined` event for the creator.
- `DissolveHousehold`: verify accepted by admin, rejected by non-admin, emits `HouseholdDissolved`; projection has `dissolved_at` set.

Prior-art: existing aggregate tests under `test/grocery_haul/households/`, `DataCase` in `test/support/data_case.ex`, existing `HouseholdMembership` aggregate for migration reference.

## Out of scope

- CI lint job and cache key (already implemented)
- `event_store.reset` alias (already implemented)
- Fly.io `EVENT_STORE_DATABASE_URL` validation (revisit before first production deploy)
- Audit trail / event replay UI
- Password reset / forgot-password flow
- OAuth / social login
- Email confirmation on registration

## Open questions

- [ ] Should `DissolveHousehold` soft-delete (mark dissolved in projection) or hard-delete (remove projection rows)? Soft-delete assumed; revisit if storage becomes a concern.
- [ ] `HouseholdMembership` aggregate: delete module entirely, or keep as dead code until the branch is merged and verified? Delete assumed.

## Future Considerations

- **Hard-delete for dissolved households**: the current soft-delete approach leaves dissolved households in the projection indefinitely. If storage grows, a background job or admin command to purge projection rows for dissolved households would be needed.
- **`reset_event_store/0` brittleness**: the InMemory adapter's internal state map keys (`streams`, `persisted_events`, `next_event_number`) are private implementation details of Commanded. A library version bump could silently break test isolation. Track the upstream API for an official `reset!/0` call and migrate when available.
- **Integration test FK race condition**: 16–19 integration tests in `households_test.exs` fail due to a projector ordering race in the Ecto sandbox (JoinCodeProjector commits before HouseholdProjector, violating FK). This is pre-existing, not introduced here, but will block a clean `mix test` run — worth a dedicated fix before the next phase.
- **Sole-admin guard on `LeaveHousehold`**: a sole admin can currently leave a household, leaving it admin-less. The same guard pattern used for `DemoteAdmin` should be applied to `LeaveHousehold` (and possibly `RemoveMember` when the target is the last admin).
- **`DissolveHousehold` cascading state**: once a household is dissolved, member commands (`JoinHousehold`, `LeaveHousehold`, etc.) will still succeed because the aggregate has no `dissolved` flag. Adding a `dissolved: boolean` to `Household` state and guarding all commands against it would prevent post-dissolution mutations.
- **Dialyzer PLT warm-up time in CI**: the first CI run after a `mix.lock` change will rebuild the PLT from scratch, which can take several minutes. Pre-seeding the PLT in a separate scheduled job or using a broader cache restore key would reduce cold-start pain.
- **Process manager persistence in production**: `HouseholdCreationProcessManager` uses the in-memory Commanded backend in tests, but in production it needs a persistent store (Postgres event store) for crash recovery. Verify that the process manager state is correctly serialized and recovered after a node restart before first production deploy.
