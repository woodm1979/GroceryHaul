# PLAN: GroceryHaul Phase 1 — App Scaffolding

> PRD: ./2026-04-28-phase1-scaffold-PRD.md
> Executor: /build
> Created: 2026-04-28  |  Last touched: 2026-04-28

## Architectural decisions

- **App name**: `grocery_haul`; OTP module `GroceryHaul`; web module `GroceryHaulWeb`
- **UUID PKs**: `--binary-id` flag sets `:binary_id` as default PK type across all Ecto schemas
- **No mailer**: `--no-mailer` flag; auth is OAuth-only, no email flows in any phase
- **Single Postgres instance**: one DB, two schemas — `public` (Ecto projections) and `event_store` (Commanded EventStore tables)
- **EventStore config**: `prefix: "event_store"` keeps Commanded tables out of the Ecto migrations schema
- **Docker Compose**: single `postgres:16` service on port 5432, named volume; credentials match Phoenix default (`postgres`/`postgres`/`localhost`)
- **Lefthook**: `lefthook.yml` at repo root; developers run `lefthook install` once after cloning (not auto-installed)
- **GitHub Actions**: test job runs on all push/PR events; deploy job runs only on `refs/heads/main` and depends on test passing; requires `FLY_API_TOKEN` secret
- **Fly.io**: region `iad`, `shared-cpu-1x`, 256 MB RAM; Postgres cluster on Fly free tier

## Conventions

- TDD per section (test → impl → commit)
- Minimum one commit per completed section
- Review checkpoint between sections (spec compliance + code quality)
- Default implementer model: `sonnet`

---

## Section 1: Phoenix app + Docker Compose

**Status:** [x] complete
**Model:** haiku
**User stories covered:** 1, 2

### What to build

Generate the Phoenix application with UUID PKs and no mailer, add a `docker-compose.yml` for local Postgres, and pin Elixir/OTP versions in `.mise.toml`. Verify `mix test` passes against the Docker Compose database.

### Acceptance criteria

- [x] `mix phx.new grocery_haul --binary-id --no-mailer` generates the project (committed output)
- [x] `docker compose up -d` starts a Postgres 16 container on port 5432
- [x] `mix test` passes with the Docker Compose Postgres running
- [x] `.mise.toml` pins Elixir and OTP to the latest stable versions

### Notes for executor

- Use `--binary-id`; this configures `@primary_key {:id, :binary_id, autogenerate: true}` project-wide
- Docker Compose credentials must match Phoenix's default dev config: user `postgres`, password `postgres`, host `localhost`
- Confirm latest stable Elixir 1.18.x + OTP 27.x patch versions when writing `.mise.toml`
- Do NOT add `--no-html` or `--no-assets`; LiveView requires the HTML layer

### Completion log

- Commits: 6d920d9 57b4f86
- Tests added: 0 (5 Phoenix-generated tests pass)
- Deviations from plan: Initially used port 5433 (local conflict); remediated to 5432 per spec. Used Elixir 1.19.4/OTP 28 (latest stable) instead of plan note 1.18.x/OTP 27.x.

---

## Section 2: Commanded + EventStore

**Status:** [x] complete
**Model:** sonnet
**User stories covered:** 5

### What to build

Add `commanded`, `commanded_eventstore_adapter`, and `eventstore` deps, configure EventStore with the `event_store` schema prefix, create `GroceryHaul.EventStore` and `GroceryHaul.Commanded.Application` modules, and register them in the OTP supervision tree. Verify EventStore tables are created and the app starts cleanly.

### Acceptance criteria

- [x] `mix deps.get` resolves without conflicts
- [x] `mix event_store.init` creates EventStore tables under the `event_store` schema
- [x] `GroceryHaul.Commanded.Application` starts without error when `mix test` runs
- [x] `mix test` still passes after wiring in Commanded

### Notes for executor

- EventStore config: `config :grocery_haul, GroceryHaul.EventStore, prefix: "event_store", serializer: EventStore.JsonBase64Serializer, ...` (standard Postgres opts)
- Commanded app config: `config :grocery_haul, GroceryHaul.Commanded.Application, event_store: [adapter: Commanded.EventStore.Adapters.EventStore, event_store: GroceryHaul.EventStore]`
- `GroceryHaul.EventStore` is a module using `EventStore, otp_app: :grocery_haul`
- Supervision order: `Repo` → `EventStore` → `Commanded.Application` → `Endpoint`
- Either add `mix event_store.init` to the `mix ecto.setup` alias in `mix.exs`, or document it as a separate setup step

### Completion log

- Commits: dc56baa
- Tests added: 1
- Deviations from plan: Plan notes referenced `EventStore.JsonBase64Serializer` which doesn't exist in eventstore 1.4.x; used `EventStore.JsonbSerializer` with `column_data_type: "jsonb"` (correct modern API). EventStore supervised internally by Commanded adapter (not as separate supervision child); effective order is still Repo → Commanded.Application(→EventStore) → Endpoint.

---

## Section 3: Dev tooling (Lefthook + Credo)

**Status:** [ ] not started
**Model:** haiku
**User stories covered:** 3

### What to build

Add `credo` as a dev/test dep, generate `.credo.exs`, create `lefthook.yml` with pre-commit hooks for `mix format --check-formatted` and `mix credo`, and document the one-time `lefthook install` step.

### Acceptance criteria

- [ ] `mix credo` runs without crashing
- [ ] `lefthook.yml` has a `pre-commit` section running format check and credo
- [ ] Attempting to commit unformatted code triggers the hook and blocks the commit
- [ ] `CLAUDE.md` notes that `lefthook install` must be run after cloning

### Notes for executor

- Lefthook is a system binary (install via `brew install lefthook`), not a Mix dep — no `mix.exs` change needed
- Generate `.credo.exs` via `mix credo gen.config`; defaults are fine for Phase 1
- Do not add `dialyxir` to pre-commit or CI; it is available as a dev dep for manual runs only
- `dialyxir` should still be added to `mix.exs` as a dev dependency so `mix dialyzer` works when the developer wants it

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:

---

## Section 4: Fly.io + GitHub Actions

**Status:** [ ] not started
**Model:** sonnet
**User stories covered:** 4

### What to build

Create `fly.toml` for a `shared-cpu-1x 256 MB` machine in `iad`, and write `.github/workflows/ci.yml` with a test job (all branches/PRs) and a deploy job (main only, requires test to pass). Document the `FLY_API_TOKEN` secret.

### Acceptance criteria

- [ ] `fly.toml` specifies app name, region `iad`, `shared-cpu-1x` machine, 256 MB RAM
- [ ] `.github/workflows/ci.yml` runs `mix test` on every push and pull request
- [ ] The deploy job only runs on `refs/heads/main` and has `needs: test`
- [ ] A note in `CLAUDE.md` documents that `FLY_API_TOKEN` must be added as a GitHub Actions secret

### Notes for executor

- GitHub Actions test job needs a Postgres service container: `postgres:16`, same credentials as `docker-compose.yml`
- Deploy step: `uses: superfly/flyctl-actions/setup-flyctl@master` then `flyctl deploy --remote-only`
- Free tier constraint: do NOT configure multiple machines or memory > 256 MB in `fly.toml`
- The Fly.io app does not need to exist yet to commit `fly.toml`; it is created via `fly launch` when first deploying

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:
