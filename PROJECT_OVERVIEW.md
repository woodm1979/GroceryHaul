# GroceryHaul — Project Overview

## Vision

A grocery list app that eliminates backtracking in the store. When shopping at a specific store, your list is sorted by the order you actually walk the aisles. Aisle data is crowdsourced across all users — the more people use the app, the more accurate the sort becomes.

---

## Product Decisions

### Users & Households

- Users authenticate via **OAuth** (Google, Apple, extensible via `ueberauth`)
- A **household** is a shared tenant: multiple users, multiple named grocery lists
- Users can belong to **multiple households** (home + parents, etc.)
- Households are joined via a **shareable join code** (no email invite needed)
- One household member is the **admin** (can remove members, regenerate join code, delete household)

### Stores

- Each physical store location is its own entity (no chain/location hierarchy)
- Store has: name, address, coordinates (for future GPS-based auto-detection)
- Any authenticated user can add or edit stores
- Each store has a list of named **aisles** (e.g., "1", "2", "Produce", "Bakery")

### Item Catalog

- **Global shared catalog** — items are shared across all households
- Each item has a name and a list of known **brands** (crowdsourced; defaults to "any brand")
- Any authenticated user can add items or brands
- No item categories — use separate items for variations (e.g., "Bakery Bread" vs "Packaged Bread")

### Aisle Mappings

- Any authenticated user can map an item to an aisle at a specific store
- One aisle per item per store
- **Primary crowdsourcing UX**: when checking off an unmapped item, the app prompts "which aisle are you in?"
- For already-mapped items: the aisle label is shown on the item with a small "wrong?" correction button

### Shopping View

- List has a **store selector** — selecting a store activates aisle-sorted order
- Sort order is **per-user per store** (not per-household): each person can configure the order they walk the aisles at a given store
- Default walk order: numbered aisles ascending; named sections at their contributed default position
- Items with no aisle mapping at the selected store **sort to the top** as a separate group
- No separate "shopping mode" — store selector drives everything
- GPS auto-detection (suggest nearest store) is a planned follow-on feature; manual selection ships first

### Grocery Lists

- Households can have **multiple named lists** (e.g., "Weekly", "Costco Run")
- List items carry: item, optional brand, optional quantity, optional unit, optional note, checked status
- **Real-time sync** across household members via Phoenix PubSub / LiveView
- **Persistent lists** — no auto-clear; use "clear checked items" action after shopping
- Checked items stay visible in place (strikethrough) during shopping

---

## Technical Stack

| Layer | Choice |
|---|---|
| Language | Elixir |
| Web framework | Phoenix + LiveView |
| Mobile | LiveView Native (single codebase → web + iOS + Android) |
| Event sourcing | Commanded |
| Event store | `eventstore` adapter on Postgres |
| Auth | `ueberauth` (OAuth strategies) |
| Authorization | `bodyguard` + ReBAC (permissions from relationships) |
| Database | Postgres (event store + read model projections) |
| Deployment | Fly.io |

---

## Domain Model

### Aggregates

| Aggregate | Commands | Events |
|---|---|---|
| **Store** | AddStore, UpdateStore, AddAisle, UpdateAisle, RemoveAisle, SetItemAisle, RemoveItemAisle | StoreAdded, StoreUpdated, AisleAdded, AisleUpdated, AisleRemoved, ItemAisleMapped, ItemAisleRemoved |
| **CatalogItem** | AddItem, UpdateItem, AddBrand, RemoveBrand | ItemAdded, ItemUpdated, BrandAdded, BrandRemoved |
| **Household** | CreateHousehold, RenameHousehold, GenerateJoinCode | HouseholdCreated, HouseholdRenamed, JoinCodeGenerated |
| **HouseholdMembership** | JoinHousehold, LeaveHousehold, RemoveMember, PromoteAdmin, DemoteAdmin | MemberJoined, MemberLeft, MemberRemoved, AdminPromoted, AdminDemoted |
| **GroceryList** | CreateList, RenameList, DeleteList, AddItem, UpdateItem, RemoveItem, CheckItem, UncheckItem, ClearChecked | ListCreated, ListRenamed, ListDeleted, ItemAdded, ItemUpdated, ItemRemoved, ItemChecked, ItemUnchecked, CheckedCleared |
| **UserPreferences** | UpdateStoreWalkOrder | StoreWalkOrderUpdated |

### Read Models (Projections)

| Projection | Purpose |
|---|---|
| StoreList | All stores — for store picker |
| StoreDetail | Store with ordered aisles + item-aisle mappings |
| HouseholdLists | All lists for a household |
| ListDetail | List items with aisle info, sorted by user's walk order for selected store |
| UserStoreOrder | User's custom aisle ordering per store |
| ItemSearch | Global item + brand catalog for autocomplete |

### Authorization (ReBAC via Bodyguard)

- **Global resources** (stores, catalog items, aisle mappings) → any authenticated user
- **Household resources** (lists, memberships) → household members only
- **Admin actions** (remove member, regenerate join code, delete household) → `membership.role == :admin`

---

## Development Phases

Each phase delivers a working vertical slice end-to-end.

1. **Foundation** — `mix.exs`, Phoenix, Commanded, Postgres EventStore, Fly.io CI/CD pipeline
2. **Auth + Households** — `ueberauth` OAuth, user registration, household create/join (join code), Bodyguard policies
3. **Store Catalog** — add/edit stores with address + coordinates, aisle management UI
4. **Item Catalog** — add/edit items + brands, search/autocomplete
5. **Grocery Lists** — create/rename/delete lists, add/update/remove list items, check/uncheck, clear-checked
6. **Shopping View** — store selector on list, per-user walk order config, aisle-sorted view, unmapped-item prompt, aisle correction button
7. **Real-time Sync** — PubSub broadcast for household list updates across live sessions
8. **LiveView Native** — iOS + Android targets via `liveview-native`
9. **GPS Store Detection** — auto-detect current store by coordinates with manual fallback

---

## Out of Scope (MVP)

- Offline mode (online-only for MVP)
- Push notifications
- Item categories / taxonomy
- Multi-store trip pre-planning (use separate lists instead)
- Email-based household invites
