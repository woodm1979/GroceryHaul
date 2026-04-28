# PRD: GroceryHaul Phase 1 — App Scaffolding

> Status: draft
> Plan: ./2026-04-28-phase1-scaffold-PLAN.md
> Created: 2026-04-28  |  Last touched: 2026-04-28

## Problem

GroceryHaul has no source files yet. Before any domain features can be built, the full technical stack must be bootstrapped: Phoenix + LiveView for the web layer, Commanded + EventStore for event sourcing, and Postgres for both the event store and read model projections. Development also requires a local Postgres instance and a consistent set of tooling guardrails to prevent style and lint issues from reaching CI.

## Solution

Generate a Phoenix application with UUID primary keys and LiveView, wire in Commanded with the EventStore adapter backed by Postgres, and set up a Docker Compose environment for local development. Add Lefthook pre-commit hooks for formatting and linting, configure Fly.io for deployment, and add a GitHub Actions workflow that runs tests on every push and deploys to Fly.io on merge to main.

## User stories

1. As a developer, I want `mix test` to pass on a fresh clone so I can start building features immediately.
2. As a developer, I want to run `docker compose up` to get a local Postgres instance so I don't need Postgres installed natively.
3. As a developer, I want pre-commit hooks to catch style and lint issues locally so CI never burns minutes on formatting.
4. As a developer, I want `git push` to `main` to automatically deploy to Fly.io so I don't manage deploys manually.
5. As a developer, I want the EventStore connected to Postgres so I can write Commanded aggregates in Phase 2 without revisiting infrastructure.

## Architecture & module sketch

- **`GroceryHaul.Application`** — OTP supervisor; starts `GroceryHaul.Repo`, `GroceryHaul.EventStore`, `GroceryHaul.Commanded.Application`, and `GroceryHaulWeb.Endpoint`
- **`GroceryHaul.Repo`** — Ecto repo; Postgres adapter; used for read model projections in later phases
- **`GroceryHaul.EventStore`** — thin EventStore wrapper; Postgres-backed with `event_store` schema prefix to avoid colliding with Ecto projection tables
- **`GroceryHaul.Commanded.Application`** — Commanded app module; uses `commanded_eventstore_adapter` pointing at `GroceryHaul.EventStore`
- **`GroceryHaulWeb.Endpoint` / `GroceryHaulWeb.Router`** — minimal Phoenix endpoint; no routes beyond the default Phoenix-generated health check

## Testing approach

- Smoke tests only: assert the Phoenix endpoint responds, the Repo connects, and the Commanded application starts without error
- Use Phoenix's generated test scaffolding (`test/grocery_haul_web/`) as the model
- No domain behavior to test yet; any test that proves the supervision tree starts counts

## Out of scope

- All domain logic: auth, households, stores, items, grocery lists, shopping view, real-time sync, LiveView Native, GPS detection (Phases 2–9)
- `commanded_ecto_projections` dep (add when the first projection is built in Phase 2)
- LiveDashboard customization
- Secrets management beyond documenting which secrets are required

## Open questions

- [ ] Confirm Elixir 1.18.x + OTP 27.x are the correct latest stable versions at execution time (pin whatever is latest then)
