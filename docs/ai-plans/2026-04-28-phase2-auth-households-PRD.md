# PRD: Phase 2 — Auth + Households

> Status: draft
> Plan: ./2026-04-28-phase2-auth-households-PLAN.md
> Created: 2026-04-28  |  Last touched: 2026-04-28

## Problem

GroceryHaul has no users. The Phase 1 foundation — Phoenix, Commanded, Postgres EventStore, Fly.io CI/CD — is in place, but there is no way to register, log in, or group users into households. Without these primitives, no one can own a grocery list, share it with family, or accumulate the per-store aisle data that makes the app valuable.

This phase delivers the first vertical slice that turns the scaffolding into a real multi-user product.

## Solution

Add username/password registration and login backed by an event-sourced User aggregate. Sessions are stored as plain Ecto tokens (infrastructure, not domain). A User projection provides the read model used for auth checks (email + hashed password).

On top of auth, add household management: a logged-in user can create a household (becoming its admin), generate a shareable join code, and invite others to join. Members can leave; admins can remove members, promote/demote admins, and rename the household. All household state is event sourced via Household and HouseholdMembership aggregates with read-model projections for the UI.

OAuth (ueberauth) is explicitly deferred — the username/password layer is designed to be extended later without migrating existing users.

## User stories

1. As a new user, I can register with an email address and password so that I have a personal account.
2. As a registered user, I can log in with my email and password, and log out, so that my session is managed securely.
3. As a logged-in user, I can create a new household and become its admin so that I have a space to manage grocery lists.
4. As a household admin, I can generate and view a join code so that I can share it with people I want to invite.
5. As a logged-in user, I can enter a join code to join an existing household so that I can collaborate with its members.
6. As a household member, I can leave a household so that I am no longer associated with it.
7. As a household admin, I can remove another member from the household.
8. As a household admin, I can promote a member to admin or demote an existing admin to member.
9. As a household admin, I can rename the household.

## Architecture & module sketch

- **User aggregate** — handles `RegisterUser` command; emits `UserRegistered`. Enforces email uniqueness via process manager or router middleware.
- **UserProjection** — Ecto schema (`id`, `email`, `hashed_password`, `display_name`, `inserted_at`). Built from `UserRegistered` events. Used exclusively for auth checks and session creation.
- **UserToken** — plain Ecto schema for session tokens. Not event sourced; created/deleted directly. Standard Phoenix session token pattern.
- **Household aggregate** — handles `CreateHousehold`, `RenameHousehold`, `GenerateJoinCode`; emits corresponding events. Join codes are random short strings generated inside the aggregate on command.
- **HouseholdMembership aggregate** — one aggregate per (household_id, user_id) pair; handles `JoinHousehold`, `LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin`.
- **HouseholdProjection** — Ecto schemas for household detail and member list. Consumed by the web layer.
- **JoinCodeIndex** — read model mapping join codes to household IDs, used to resolve a code before issuing `JoinHousehold`.
- **Bodyguard policies** — any authenticated user can act on their own account; household resources require membership; admin-only actions check `role == :admin` in the projection.

## Testing approach

- **Aggregate unit tests**: use `Commanded.AggregateCase` to test each aggregate in isolation — given a sequence of prior events, assert the correct new events are emitted for a given command, and that invalid commands are rejected.
- **Integration tests**: use `ConnCase` (controllers) and Phoenix `LiveViewTest` (LiveView) against the full stack including a real Postgres event store. No mocking of the event store or projections.
- **Key behaviors to cover**: duplicate email registration is rejected; invalid credentials are rejected at login; join code resolves to the correct household; membership commands respect role constraints (non-admins cannot remove members or promote/demote); leaving the last-admin household is handled gracefully.
- **Follow the existing `test/support/` patterns** (`ConnCase`, `DataCase`) already scaffolded in the repo.

## Out of scope

- OAuth / ueberauth (deferred to a later phase; username/password layer is designed for easy extension)
- Email confirmation
- Password reset / forgot-password flow
- GPS-based store detection
- Any grocery list or store catalog functionality

## Open questions

- [ ] Hashed password in `UserRegistered` event: acceptable to persist in the event log permanently? Alternative: keep credentials in a separate Ecto table (`user_credentials`) that is updated directly and never event sourced, using the User aggregate only for non-credential identity events. Resolve before implementing Section 1.
