# PLAN: Phase 2 — Auth + Households

> PRD: ./2026-04-28-phase2-auth-households-PRD.md
> Executor: /build
> Created: 2026-04-28  |  Last touched: 2026-04-28

## Architectural decisions

- **Auth mechanism**: username/password only. OAuth deferred. No `phx.gen.auth` — write a custom auth layer so everything is event sourced.
- **User aggregate**: `RegisterUser` command → `UserRegistered` event. Email uniqueness enforced at the router/process-manager level (or via a unique index on the projection that causes the command to fail fast).
- **Credential storage**: resolve the open question in the PRD before Section 1 starts. Default assumption: hashed password stored in `UserRegistered` event and projected into `UserProjection`. If the team decides otherwise, keep credentials in a separate plain Ecto table and omit them from events.
- **Session tokens**: `UserToken` is a plain Ecto schema (not event sourced). Created on login, deleted on logout. Uses Phoenix's standard token-in-cookie pattern.
- **Household aggregate**: one aggregate per household. `CreateHousehold` also triggers auto-creation of the creator's membership as admin (via a process manager or a router-dispatched command after `HouseholdCreated`).
- **HouseholdMembership aggregate**: keyed by `(household_id, user_id)`. Tracks role (`:member` | `:admin`).
- **Join codes**: short random strings (e.g. 8 uppercase alphanumeric chars). `JoinCodeIndex` is a plain Ecto projection mapping code → household_id. Regenerating a code via `GenerateJoinCode` overwrites the old entry.
- **Bodyguard policies**: any authenticated user can register and log in. Household-scoped resources require a `HouseholdMembership` projection row. Admin-only commands additionally require `role == :admin`.
- **Read models**: `UserProjection`, `HouseholdProjection` (name + join code), `HouseholdMembersProjection` (member list with roles), `JoinCodeIndex`. All built by Commanded event handlers.
- **Web layer**: Phoenix LiveView for all UI. No REST endpoints beyond what Phoenix/Plug needs for session management.

## Conventions

- TDD per section (test → impl → commit)
- Minimum one commit per completed section
- Review checkpoint between sections (spec compliance + code quality)
- Default implementer model: `sonnet`

---

## Section 1: User registration and auth

**Status:** [ ] not started
**Model:** sonnet
**User stories covered:** 1, 2

### What to build

A `User` Commanded aggregate that handles `RegisterUser` → `UserRegistered`. A `UserProjection` Ecto schema that stores email and hashed password for auth checks. A `UserToken` plain Ecto schema for session management. LiveView pages for registration, login, and logout.

### Acceptance criteria

- [ ] A user can submit the registration form with a valid email and password and is redirected to a logged-in state.
- [ ] Attempting to register with an already-registered email is rejected with a visible error message.
- [ ] A registered user can log in with correct credentials and receive a session.
- [ ] Logging in with an incorrect password is rejected with a visible error message.
- [ ] A logged-in user can log out and their session is invalidated (subsequent protected page visit redirects to login).
- [ ] `UserRegistered` event appears in the event store after a successful registration.
- [ ] Aggregate unit tests cover: successful registration, duplicate email rejection.
- [ ] Auth integration tests cover: register → login → logout round-trip.

### Notes for executor

- Resolve the PRD open question (hashed password in events vs. separate Ecto table) before writing the aggregate. The acceptance criteria are valid either way, but the implementation differs.
- `UserProjection` is the only read model needed for auth; do not build a full user profile page in this section.
- `UserToken` follows the Phoenix standard: a random binary stored in a DB row, referenced by a signed cookie. See Phoenix docs for `Phoenix.Token` or roll a simple `user_tokens` table.
- Email uniqueness: a unique index on `user_projection.email` is the simplest guard. The aggregate itself need not query the projection.
- Do not build household UI in this section. Post-login destination can be a simple placeholder page.

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:

---

## Section 2: Household creation and post-login flow

**Status:** [ ] not started
**Model:** sonnet
**User stories covered:** 3

### What to build

A `Household` Commanded aggregate handling `CreateHousehold` → `HouseholdCreated`. A `HouseholdMembership` aggregate auto-joined when a household is created (creator becomes admin). A `HouseholdProjection` read model. A post-login screen that lets a user create a household or enter a join code (join code form can be a stub at this stage — just the UI shell; the actual join logic ships in Section 3).

### Acceptance criteria

- [ ] A logged-in user can create a household by providing a name; they are redirected to a household dashboard.
- [ ] The creating user appears as admin in the `HouseholdMembersProjection` immediately after creation.
- [ ] A user who is not yet in any household is redirected to the "create or join" screen after login.
- [ ] A user who already has a household is redirected to their household dashboard after login.
- [ ] `HouseholdCreated` and `MemberJoined` (with role `:admin`) events appear in the event store after household creation.
- [ ] Aggregate unit tests cover: successful household creation, membership aggregate initialized with admin role.
- [ ] Integration test covers: create household end-to-end via LiveView.

### Notes for executor

- The "create or join" screen can have a non-functional join-code input at this stage — just enough UI to not look broken. The join logic ships in Section 3.
- Triggering the `JoinHousehold` command for the creator after `HouseholdCreated` can be done via a process manager or a router multi-dispatch. Whichever is simpler given the existing Commanded setup in `lib/grocery_haul/commanded/`.
- Household dashboard at this stage only needs to show the household name and the current user's name/role.
- Multi-household routing: a user can belong to multiple households (product decision). For Phase 2, if a user has exactly one household redirect there; if they have multiple, show a household picker. The picker can be minimal (just a list of names with links).

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:

---

## Section 3: Join code generation and joining

**Status:** [ ] not started
**Model:** sonnet
**User stories covered:** 4, 5

### What to build

`GenerateJoinCode` command on the `Household` aggregate → `JoinCodeGenerated` event → `JoinCodeIndex` projection (code → household_id). `JoinHousehold` command on `HouseholdMembership` → `MemberJoined` event. UI for admins to view/regenerate the join code and for any logged-in user to join via code.

### Acceptance criteria

- [ ] The household dashboard shows the current join code; an admin can regenerate it.
- [ ] After regeneration, the old join code no longer works.
- [ ] A logged-in user who is not a member of a household can enter a valid join code and join successfully, ending up on the household dashboard.
- [ ] Entering an invalid or expired join code shows a visible error message.
- [ ] A user who is already a member cannot join the same household again (duplicate membership rejected).
- [ ] `JoinCodeGenerated` and `MemberJoined` events appear in the event store.
- [ ] Aggregate unit tests cover: join code generation, joining with valid code, joining with invalid code (rejected), duplicate join (rejected).
- [ ] Integration test covers: admin generates code → second user joins via that code.

### Notes for executor

- `JoinCodeIndex` is a plain Ecto projection — a table with columns `(code, household_id)`. Kept in sync by an event handler on `JoinCodeGenerated`. The old code row can be deleted or marked inactive on regeneration.
- Join code format: 8 uppercase alphanumeric characters is a reasonable default. Generate in the aggregate so it appears in the event.
- The "create or join" stub from Section 2 should be wired up here with the real join logic.
- A household is automatically given a join code when it is created (emit `JoinCodeGenerated` alongside `HouseholdCreated`, or generate inside `CreateHousehold`). Resolve which approach fits the existing aggregate pattern before implementing.

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:

---

## Section 4: Member management and rename

**Status:** [ ] not started
**Model:** sonnet
**User stories covered:** 6, 7, 8, 9

### What to build

`LeaveHousehold`, `RemoveMember`, `PromoteAdmin`, `DemoteAdmin` commands on `HouseholdMembership` → corresponding events. `RenameHousehold` command on `Household` aggregate. Admin management UI on the household settings page. Bodyguard policies enforcing role constraints.

### Acceptance criteria

- [ ] A member can leave a household; they are redirected to the "create or join" screen.
- [ ] An admin can remove another member; that member no longer appears in the member list.
- [ ] An admin can promote a member to admin; the promoted user gains admin capabilities.
- [ ] An admin can demote another admin to member (but cannot demote themselves if they are the sole admin — this should be rejected with a visible error).
- [ ] An admin can rename the household; the new name is reflected immediately in the UI.
- [ ] A non-admin cannot access member management actions (attempting to do so is rejected).
- [ ] `MemberLeft`, `MemberRemoved`, `AdminPromoted`, `AdminDemoted`, `HouseholdRenamed` events appear in the event store as appropriate.
- [ ] Aggregate unit tests cover: all five commands, plus the sole-admin demotion guard.
- [ ] Integration tests cover: leave, remove, promote, demote, rename via LiveView.

### Notes for executor

- "Sole admin" guard: the `HouseholdMembership` aggregate does not have visibility into other memberships. This guard may require reading the `HouseholdMembersProjection` in the command handler or enforcing it at the policy/process level before dispatching. Choose the simplest approach that passes the test.
- Removing a member is an admin action on the household, not a self-action — route it through the Household or HouseholdMembership aggregate with an admin check.
- The household settings page can be a sub-page of the household dashboard introduced in Section 2.

### Completion log

<!-- Executor fills in after section completes -->
- Commits:
- Tests added:
- Deviations from plan:
