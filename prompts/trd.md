# Technical Requirements Document (TRD)
## Drop Vault — Cross-Platform Personal Knowledge Vault

| Field | Detail |
|---|---|
| Product Name | Drop Vault |
| Document Type | Technical Requirements Document (TRD) |
| Version | 1.0 |
| Date | June 2026 |
| Companion Document | Drop Vault PRD v1.0 |
| Prepared By | Ajay Singh |

> Scope note: This TRD defines architecture, data model, and system behavior. It does not define screen layouts, visual design, or component styling — frontend screen implementation is being built separately.

---

## 1. Purpose

This document translates the functional requirements in the PRD into a concrete technical architecture: stack, folder structure, database schema, security model, sync strategy, and performance plan — sufficient for implementation to begin without further architectural ambiguity.

---

## 2. Technology Stack Summary

| Layer | Choice |
|---|---|
| Target Platforms | Android, Windows |
| Frontend Framework | Flutter 3.32+ |
| Language | Dart |
| Architecture Pattern | Feature-First (modular, per-feature data/domain/presentation layering) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Key-Value Storage | SharedPreferences (scope clarified in §5.5) |
| Backend Platform | Supabase |
| Auth | Supabase Auth (Email/Password + Google OAuth) |
| Database | Supabase PostgreSQL |
| File Storage | Supabase Storage |
| Realtime Sync | Supabase Realtime (Postgres Changes) |
| Scheduled Jobs | Supabase pg_cron / Edge Functions |

---

## 3. System Architecture Overview

```
┌─────────────────────────────┐        ┌──────────────────────────────────┐
│   Flutter Client (Android)   │        │   Flutter Client (Windows)        │
│  Feature-First + Riverpod    │        │  Feature-First + Riverpod         │
└──────────────┬────────────────┘        └────────────────┬───────────────┘
               │                                           │
               │            Supabase Client SDK            │
               └──────────────────┬────────────────────────┘
                                   │
                     ┌─────────────▼─────────────┐
                     │         Supabase            │
                     │  ┌───────────────────────┐  │
                     │  │  Auth (JWT, OAuth)     │  │
                     │  ├───────────────────────┤  │
                     │  │  PostgreSQL + RLS      │  │
                     │  ├───────────────────────┤  │
                     │  │  Storage (Buckets)     │  │
                     │  ├───────────────────────┤  │
                     │  │  Realtime (Postgres    │  │
                     │  │  Changes channels)     │  │
                     │  ├───────────────────────┤  │
                     │  │  pg_cron / Edge Fns    │  │
                     │  │  (trash purge, link    │  │
                     │  │   metadata fetch)      │  │
                     │  └───────────────────────┘  │
                     └─────────────────────────────┘
```

Both clients talk to the same Supabase project. There is no custom backend server — Supabase serves as the single backend, with PostgreSQL Row Level Security enforcing per-user data isolation rather than a custom API authorization layer.

---

## 4. Frontend Architecture

### 4.1 Architecture Pattern — Feature-First

Each feature is a self-contained module owning its own data access, business logic, and UI, rather than splitting the app by technical layer first (e.g., a global `screens/` folder). This keeps each feature independently testable and reduces cross-feature coupling — important given the number of distinct modules (10) in this app.

Within each feature, a lightweight three-layer split is used:
- **data/** — Supabase queries, repository implementations, DTOs/mappers
- **domain/** — models, business rules independent of Supabase specifics
- **presentation/** — screens, widgets, and feature-local providers

### 4.2 Folder Structure (Detailed)

```
lib/
├── core/
│   ├── config/                  # Supabase URL/anon key loading, env config
│   ├── constants/                # app-wide constants (retention days, limits)
│   ├── errors/                   # custom exceptions, failure types
│   ├── network/                  # Supabase client singleton, connectivity service
│   ├── router/                   # GoRouter configuration, route guards
│   └── utils/                    # date formatting, validators, debouncer, etc.
│
├── shared/
│   ├── models/                   # cross-feature models (ItemType enum, etc.)
│   ├── widgets/                  # cross-feature reusable widgets (non-visual stubs)
│   └── extensions/               # Dart extension methods
│
├── features/
│   ├── onboarding/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── auth/
│   │   ├── data/                 # auth_repository.dart (Supabase Auth calls)
│   │   ├── domain/                # AuthUser model
│   │   └── presentation/
│   │       ├── screens/           # login, signup, forgot_password
│   │       └── providers/         # authControllerProvider, authStateProvider
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── search/
│   │   ├── data/                 # search_repository.dart
│   │   ├── domain/
│   │   └── presentation/
│   │       └── providers/         # searchQueryProvider, searchFiltersProvider, searchResultsProvider
│   ├── collections/
│   │   ├── data/                 # collections_repository.dart
│   │   ├── domain/
│   │   └── presentation/
│   ├── items/                     # shared item CRUD logic used by home/search/collections/favorites
│   │   ├── data/                 # items_repository.dart, storage_repository.dart
│   │   ├── domain/                 # Item model, ItemType enum
│   │   └── presentation/
│   ├── favorites/
│   ├── reminders/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── services/          # local_notification_service.dart
│   ├── profile/
│   ├── settings/
│   └── trash/
│
├── providers/
│   ├── connectivity_provider.dart
│   ├── sync_status_provider.dart
│   └── theme_provider.dart
│
└── main.dart
```

> Note: An `items/` feature module is introduced beyond the originally listed modules, since Items are the core entity referenced by `home`, `search`, `collections`, and `favorites`. Without a shared `items` data/domain layer, those four modules would each duplicate item CRUD and storage logic. This is a structural recommendation, not a deviation in scope.

### 4.3 State Management — Riverpod

| Provider | Type | Purpose |
|---|---|---|
| `authStateProvider` | `StreamProvider` | Wraps Supabase `onAuthStateChange`; drives router redirects |
| `authControllerProvider` | `AsyncNotifierProvider` | Handles login/signup/logout actions |
| `itemsRepositoryProvider` | `Provider` | Exposes repository instance (Supabase-backed) |
| `userItemsProvider` | `StreamProvider` / `AsyncNotifierProvider` | Live list of the user's items, fed by Realtime |
| `collectionsProvider` | `StreamProvider` | Live list of collections |
| `tagsProvider` | `StreamProvider` | Live list of tags |
| `favoritesProvider` | derived `Provider` | Filters `userItemsProvider` by favorite flag |
| `remindersProvider` | `StreamProvider` | Live list of reminders, sorted by trigger time |
| `trashProvider` | `StreamProvider` | Live list of trashed items with countdown data |
| `searchQueryProvider` | `StateProvider<String>` | Current search text |
| `searchFiltersProvider` | `StateProvider<SearchFilters>` | Active filter selection |
| `searchResultsProvider` | derived `Provider` | Computed from query + filters + local item cache |
| `connectivityProvider` | `StreamProvider<bool>` | Online/offline status |
| `syncStatusProvider` | `StateProvider<SyncStatus>` | synced / syncing / pending / error |
| `themeModeProvider` | `NotifierProvider` (persisted via SharedPreferences) | Light/Dark/System |

Realtime-backed providers (`userItemsProvider`, `collectionsProvider`, `tagsProvider`, `remindersProvider`, `trashProvider`) subscribe to Supabase Realtime channels on initialization and update automatically when the backend pushes a change — this is the mechanism that satisfies the ≤5 second cross-device sync target.

### 4.4 Navigation — GoRouter

| Route | Screen | Guard |
|---|---|---|
| `/splash` | Splash | none |
| `/login` | Login | redirect to `/home` if authenticated |
| `/signup` | Signup | redirect to `/home` if authenticated |
| `/home` | Home Dashboard | requires auth |
| `/search` | Search | requires auth |
| `/collections` | Collections list | requires auth |
| `/collections/:id` | Collection Details | requires auth |
| `/add` | Add New | requires auth |
| `/item/:id` | Item Details | requires auth |
| `/favorites` | Favorites | requires auth |
| `/reminders` | Reminders | requires auth |
| `/profile` | Profile | requires auth |
| `/settings` | Settings | requires auth |
| `/trash` | Trash | requires auth |

Auth guarding is implemented via GoRouter's `redirect` callback, listening to `authStateProvider` through a `Listenable` adapter (e.g., `GoRouterRefreshStream`), so navigation reacts immediately to login/logout events.

### 4.5 Local Storage — Scope and a Flagged Gap

**SharedPreferences is appropriate for:**
- Theme preference (light/dark/system)
- Onboarding-completed flag
- Last successful sync timestamp
- Sync preference (Wi-Fi only vs. any network)
- Lightweight UI state (e.g., last-used filter set)

**SharedPreferences is *not* appropriate for:** caching the user's item list for offline browsing and offline search. It is a flat key-value store with no querying capability, and the PRD requires (a) full offline browsing/search of previously synced content, and (b) search latency under 1 second across vaults of up to ~10,000 items. Attempting to serialize the entire item list into SharedPreferences as JSON would require deserializing and linear-scanning the whole blob on every keystroke, which will not hold up at scale and isn't a sound basis for an offline data store.

**Recommendation:** introduce a local embedded database (e.g., **Drift** or **sqflite**) as the offline cache layer, separate from SharedPreferences. Supabase Realtime data would be mirrored into this local DB, and `userItemsProvider`/`searchResultsProvider` would read from the local DB first (instant, offline-capable), with Supabase as the sync source of truth pushing updates into it. This does not change the backend (still Supabase/PostgreSQL) — it only changes what the *client* uses for local persistence. This should be confirmed before implementation begins, since it affects the `core/` and `items/data/` layer design (see §16, Alignment Notes).

---

## 5. Backend Architecture (Supabase)

### 5.1 Authentication

- Supabase Auth handles email/password and Google OAuth sign-in.
- JWT access tokens are issued by Supabase and used for all authenticated requests; RLS policies use `auth.uid()` extracted from the JWT to scope every query to the requesting user.
- Session persistence is handled by the `supabase_flutter` SDK's built-in secure local session storage (not SharedPreferences) so the user stays logged in across app restarts.
- **Windows-specific note:** Google OAuth on Flutter Desktop requires a redirect handling mechanism (typically a loopback HTTP listener or custom URI scheme) since there's no app-store-style deep link handling as on Android. This needs explicit setup in the Supabase Auth redirect configuration and is a distinct implementation task from the Android OAuth flow — flagged here so it isn't assumed to "just work" identically on both platforms.

### 5.2 Database Schema

All tables include `user_id uuid references auth.users(id)` for RLS scoping unless noted otherwise.

```sql
-- COLLECTIONS
create table collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ITEMS
create type item_type as enum ('link', 'note', 'pdf', 'docx', 'image');

create table items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  collection_id uuid references collections(id) on delete set null,
  type item_type not null,
  title text,
  description text,
  body text,                      -- note content
  source_url text,                -- for links
  file_path text,                 -- storage object path for pdf/docx/image
  thumbnail_url text,
  metadata jsonb,                 -- link preview / sub-type metadata
  is_offline_available boolean not null default false,
  status text not null default 'active',   -- 'active' | 'trashed'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_items_user on items(user_id);
create index idx_items_collection on items(collection_id);
create index idx_items_type on items(type);
create index idx_items_status on items(status);

-- TAGS
create table tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

-- ITEM_TAGS (junction)
create table item_tags (
  item_id uuid not null references items(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  primary key (item_id, tag_id)
);

-- FAVORITES
create table favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references items(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, item_id)
);

-- REMINDERS
create type reminder_status as enum ('pending', 'completed', 'snoozed');

create table reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references items(id) on delete cascade,
  trigger_at timestamptz not null,
  status reminder_status not null default 'pending',
  snoozed_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_reminders_user_status on reminders(user_id, status);

-- TRASH_ITEMS
create table trash_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null unique references items(id) on delete cascade,
  deleted_at timestamptz not null default now(),
  permanently_delete_at timestamptz not null default (now() + interval '30 days')
);

create index idx_trash_purge on trash_items(permanently_delete_at);
```

> `users` table: Supabase's built-in `auth.users` covers core auth fields. A `public.profiles` table (id references `auth.users.id`, plus `name`, `avatar_url`) should be added for app-specific profile fields not stored by Auth itself — this is effectively the "users" table referenced in the original module list.

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### 5.3 Relationships Summary

- `profiles.id` → `auth.users.id` (1:1)
- `collections.user_id` → `auth.users.id` (many collections per user)
- `items.user_id` → `auth.users.id`, `items.collection_id` → `collections.id` (many items per collection; nullable = unsorted)
- `tags.user_id` → `auth.users.id`
- `item_tags` resolves many-to-many between `items` and `tags`
- `favorites` resolves many-to-many between `auth.users` and `items` (practically one row per favorited item per user)
- `reminders.item_id` → `items.id` (one active reminder per item enforced at application layer in v1; not a DB constraint, to keep schema flexible for future multi-reminder support)
- `trash_items.item_id` → `items.id` (1:1, unique constraint)

### 5.4 Row Level Security

RLS must be enabled on every table. Standard pattern applied uniformly:

```sql
alter table items enable row level security;

create policy "Users can view own items"
  on items for select
  using (auth.uid() = user_id);

create policy "Users can insert own items"
  on items for insert
  with check (auth.uid() = user_id);

create policy "Users can update own items"
  on items for update
  using (auth.uid() = user_id);

create policy "Users can delete own items"
  on items for delete
  using (auth.uid() = user_id);
```

The same four-policy pattern (select/insert/update/delete, all checking `auth.uid() = user_id`) is applied to `collections`, `tags`, `reminders`, `trash_items`, and `profiles` (using `auth.uid() = id` for profiles). For `item_tags` and `favorites` (junction tables without their own `user_id`), policies should join through `items.user_id` or check `auth.uid() = user_id` directly where the column exists (favorites has `user_id` natively; `item_tags` policies should check via the parent `tags.user_id` or `items.user_id`).

### 5.5 Storage Buckets

| Bucket | Purpose | Path Convention |
|---|---|---|
| `documents` | PDF and DOCX uploads | `{user_id}/{item_id}/{filename}` |
| `images` | Image item uploads + generated thumbnails | `{user_id}/{item_id}/{filename}` |
| `user_uploads` | Profile pictures and any general, non-item-type upload | `{user_id}/{filename}` |

All buckets are **private** (not public). Access is controlled via Storage RLS policies mirroring the database pattern:

```sql
create policy "Users can access own files"
  on storage.objects for select
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);
```

Equivalent insert/update/delete policies are required per bucket. Files are served to the client via short-lived signed URLs generated on demand, not permanent public URLs.

### 5.6 Realtime Subscriptions

Each Realtime-backed provider (§4.3) subscribes to Postgres Changes on its corresponding table, filtered server-side by `user_id = auth.uid()` via RLS (Realtime respects RLS policies). On `INSERT`/`UPDATE`/`DELETE` events, the local provider state updates immediately, which is what drives the cross-device sync experience without polling.

### 5.7 Scheduled Jobs / Edge Functions

| Job | Mechanism | Purpose |
|---|---|---|
| Trash auto-purge | `pg_cron` scheduled SQL (daily) | Deletes rows from `trash_items` (cascades to `items`) where `permanently_delete_at < now()` |
| Link metadata fetch | Supabase Edge Function | Server-side fetch of link preview / GitHub / YouTube metadata, keeping any third-party API keys off the client and avoiding CORS issues |

---

## 6. Data Flow & Sync Strategy

1. **Write path:** Client action (save/edit/delete) → local DB write (per §4.5 recommendation) for instant UI feedback → queued Supabase mutation → on success, Realtime event echoes back (no-op for the originating client, applied on other devices).
2. **Read path (online):** Realtime subscription keeps local cache continuously up to date; UI reads from local cache, never blocking on a network round trip for already-synced data.
3. **Read path (offline):** UI reads exclusively from local cache; no network calls attempted until connectivity returns (detected via `connectivityProvider`).
4. **Conflict handling:** `updated_at` timestamp comparison; last-write-wins at the database level. Given Supabase's single-row update model, a stricter optimistic-concurrency check (comparing client's last-known `updated_at` before applying an update) can be added at the repository layer if stronger guarantees are needed later — not required for v1 per PRD §17.

---

## 7. Item Type Handling Matrix

| Type | Storage | Key Fields Used | Notes |
|---|---|---|---|
| Link | `items` row only (no file) | `source_url`, `metadata` (jsonb for preview/sub-type data) | Sub-type detection (GitHub/YouTube/Instagram) — see Alignment Notes §16 |
| Note | `items` row only | `body` | No storage bucket involved |
| PDF | `items` row + `documents` bucket | `file_path`, `title` | |
| DOCX | `items` row + `documents` bucket | `file_path`, `title` | |
| Image | `items` row + `images` bucket | `file_path`, `thumbnail_url` | Thumbnail may be the image itself for small files, or a generated resize for large ones |

---

## 8. Performance Engineering Plan

| Goal | Target | Implementation Approach |
|---|---|---|
| App Startup | < 2s | Defer non-critical provider initialization past first frame; restore auth session asynchronously while splash renders; avoid blocking startup on a full data fetch — let Realtime/local-DB hydration happen in the background. |
| Search | < 1s | Query the local embedded DB (§4.5) with proper indexes (title, tags, collection name) rather than Supabase directly; debounce input (~300ms) before triggering search computation. |
| Sync | < 5s | Realtime channel push (not polling) for all sync-relevant tables; small payload deltas rather than full-table refetches. |

---

## 9. Security Architecture

- **RLS everywhere:** every table enforces `auth.uid() = user_id` (or equivalent join) for all CRUD operations — no table should be left without RLS enabled.
- **JWT-based auth:** all Supabase client calls automatically attach the session JWT; no manual token handling required in feature code beyond the initial Supabase client setup.
- **Storage isolation:** bucket policies enforce per-user folder scoping; signed URLs are time-limited rather than permanent.
- **Secrets:** Supabase URL and anon key are environment-configured (not hardcoded) and loaded via `core/config/`; no service-role key is ever used client-side.
- **Account deletion:** must remove `auth.users` row (cascades through all `user_id`-referencing tables via `on delete cascade`) and clean up associated Storage objects, which requires an Edge Function (since Storage object deletion isn't automatically cascaded by Postgres foreign keys).

---

## 10. Feature Module Breakdown

| Module | Responsibilities | Key Providers | Screens Owned |
|---|---|---|---|
| onboarding | First-launch experience, onboarding-seen flag (SharedPreferences) | `onboardingCompleteProvider` | Splash (initial routing logic) |
| auth | Login, signup, password reset, session handling | `authStateProvider`, `authControllerProvider` | Login, Signup |
| home | Aggregated dashboard data (recent, collections preview, favorites preview, reminders preview) | derived providers reading from `userItemsProvider`, `collectionsProvider`, `remindersProvider` | Home Dashboard |
| search | Query + filter state, result computation | `searchQueryProvider`, `searchFiltersProvider`, `searchResultsProvider` | Search |
| collections | Collection CRUD, item-collection assignment | `collectionsProvider`, `collectionControllerProvider` | Collections, Collection Details |
| items (shared) | Core item CRUD, file upload, type detection/metadata fetch trigger | `userItemsProvider`, `itemControllerProvider` | Add New, Item Details (logic only — screens may be owned by other modules that consume this) |
| favorites | Favorite toggling, favorites view | `favoritesProvider` | Favorites |
| reminders | Reminder CRUD, local notification scheduling | `remindersProvider`, `reminderControllerProvider` | Reminders |
| profile | Profile view/edit, vault stats | `profileProvider` | Profile |
| settings | Theme, notifications, sync prefs, offline storage management, account actions | `themeModeProvider`, `syncSettingsProvider` | Settings |
| trash | Trash listing, restore, permanent delete, empty trash | `trashProvider` | Trash |

---

## 11. Third-Party Package Dependencies (Indicative)

| Package | Purpose |
|---|---|
| `supabase_flutter` | Supabase client (Auth, DB, Storage, Realtime) |
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `shared_preferences` | Lightweight key-value local storage |
| `drift` or `sqflite` | Embedded local DB for offline item cache (see §4.5 recommendation) |
| `file_picker` | Picking PDF/DOCX from device |
| `image_picker` | Picking/capturing images |
| `cached_network_image` | Thumbnail/preview image caching |
| `connectivity_plus` | Online/offline detection |
| `flutter_local_notifications` | Reminder notifications |
| `url_launcher` | Opening links/files externally |
| `flutter_dotenv` (or equivalent) | Environment variable loading for Supabase keys |

---

## 12. Environment & Configuration Management

- Supabase project URL and anon (public) key are stored in an environment file excluded from version control, loaded at app start via `core/config/`.
- Separate Supabase projects (or at minimum separate schemas/policies) should be used for development vs. production to avoid test data mixing with real user data — to be confirmed against project budget/constraints, since Supabase free-tier project limits may make a single shared dev/prod project a practical v1 compromise.

---

## 13. Error Handling & Logging Strategy

- All repository methods return a typed result (success/failure) rather than letting raw Supabase exceptions propagate to the UI layer, allowing consistent error messaging across features.
- Network/connectivity errors are distinguished from auth errors (expired/invalid token) and from validation errors (e.g., unsupported file type), so the UI can react appropriately (retry silently, force re-login, or show a validation message respectively).
- Sync failures are retried with backoff and reflected in `syncStatusProvider` rather than surfaced as blocking error dialogs, consistent with PRD's offline-first requirement.

---

## 14. Testing Strategy

| Layer | Approach |
|---|---|
| Repositories / data layer | Unit tests against a mocked Supabase client |
| Providers / business logic | Unit tests using Riverpod's `ProviderContainer` test utilities |
| Sync logic | Integration tests simulating offline queue + reconnect |
| Widget/UI | Out of scope for this TRD (frontend supplied separately) |

---

## 15. Alignment Notes vs. PRD (To Be Resolved)

1. **Item type scope mismatch:** the PRD specifies item types as Link, PDF, DOCX, PPT, Image, Note, plus auto-detected link sub-types (GitHub Repository, YouTube Video, Instagram Reel). This TRD's `item_type` enum (per the originally supplied table list) only covers Link, Note, PDF, DOCX, Image — **PPT is missing**, and the GitHub/YouTube/Instagram sub-types aren't represented as distinct enum values (they'd need to live in the `metadata` jsonb field with a sub-type tag instead, which is workable but should be a deliberate decision, not an oversight). Recommend either adding `ppt` to the `item_type` enum now, or explicitly confirming PPT support is deferred post-v1.
2. **Offline storage mechanism:** as detailed in §4.5, SharedPreferences alone cannot satisfy the PRD's offline search and offline browsing requirements at the stated performance target. A local embedded database is recommended as an addition, not a replacement, to the original stack list.
3. **Windows OAuth flow:** Google OAuth via Supabase Auth needs distinct redirect-handling work for the Windows desktop client versus Android; this isn't a blocker but should be scheduled explicitly rather than assumed to be a drop-in identical implementation.
4. **Single active reminder per item:** the schema does not hard-constrain this at the database level (no unique constraint on `reminders.item_id`), so it must be enforced in the `items` feature's controller logic for v1, per PRD's stated assumption.

---

## 16. Open Technical Questions

1. Confirm: Drift vs. sqflite for the local offline cache — Drift gives compile-time-safe queries and is generally a stronger fit for the filtering/search complexity described in the PRD, but has a steeper setup (code generation); sqflite is simpler but raw-SQL-based.
2. Confirm: should dev and production use separate Supabase projects, or a single project with environment-prefixed conventions for v1?
3. Confirm: PPT support and GitHub/YouTube/Instagram sub-typing — in scope for v1 schema now, or deferred (see §15.1)?
4. Confirm: is a service-role Edge Function needed for account deletion's Storage cleanup, or is manual/periodic cleanup acceptable for v1?

---

*End of Document*