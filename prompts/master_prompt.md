# DROP VAULT — MASTER BUILD PROMPT

> This is a consolidated, execution-ready prompt synthesizing the PRD, TRD, and User Workflow documents already produced for Drop Vault, plus the original design brief. It's written so it can be pasted directly into a coding-focused AI session (e.g., Claude Code) to drive implementation. A few gaps and conflicts are flagged inline rather than silently resolved — see §13 before running this.

---

## 0. Role & Objective

You are a senior Flutter architect and product engineer. Build **Drop Vault**, a production-ready Android application — a personal digital vault where users save links, notes, PDFs, DOCX files, images, GitHub repositories, YouTube videos, and other useful resources, organized into collections and tags, searchable instantly, and synced in real time across devices.

Do not generate placeholder code. Do not generate mock functionality. Every feature below must be implemented end-to-end against real Supabase services — no fake/static data standing in for a real query.

---

## 1. Tech Stack (Non-Negotiable)

| Layer | Choice |
|---|---|
| Framework | Flutter 3.32+ |
| Language | Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Settings/Local KV Storage | SharedPreferences |
| Offline Item Cache | Drift (or sqflite) — required in addition to SharedPreferences; see §13.1 |
| Backend | Supabase (Auth, PostgreSQL, Storage, Realtime) |
| Target Platform | Android first |
| Design System | Material 3 |

---

## 2. Architecture Rules

- **Feature-First** organization — each feature owns its own `data/`, `domain/`, and `presentation/` layers. Do not centralize all screens into one global folder.
- Clean Architecture boundaries: `presentation/` never talks to Supabase directly; it goes through `domain/` models and `data/` repositories.
- Riverpod providers are scoped to the feature that owns them, except cross-feature state (auth, connectivity, sync status, theme), which lives in a top-level `providers/` directory.
- No business logic in widgets. Widgets read state and dispatch actions to controllers/notifiers only.

### Required Folder Structure

```
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── shared/
│   ├── models/
│   ├── widgets/
│   └── extensions/
├── features/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── search/
│   ├── collections/
│   ├── items/          # shared item CRUD/domain used by home, search, collections, favorites
│   ├── favorites/
│   ├── reminders/
│   ├── profile/
│   ├── settings/
│   └── trash/
├── providers/
│   ├── connectivity_provider.dart
│   ├── sync_status_provider.dart
│   └── theme_provider.dart
└── main.dart
```

---

## 3. Design System — Reuse Exactly, Do Not Reinvent

> Maintain the existing Drop Vault design system, gradients, spacing, typography, and onboarding screens. The tokens below are the locked palette from the original design brief. If a frontend code package/design-token file already exists separately, that file is the source of truth and these values must match it exactly — flag any discrepancy rather than silently picking one.

**Color Palette**
| Token | Hex |
|---|---|
| Primary Dark Purple | `#210440` |
| Soft Peach | `#FDB095` |
| Muted Rose | `#E5958E` |
| Accent Yellow | `#FFBA00` |

**Gradients (use extensively, not sparingly)**
- `#210440 → #E5958E`
- `#210440 → #FDB095`
- `#E5958E → #FFBA00`
- `#FDB095 → #FFBA00`

**Surface & Shape**
- Corner radius: 20–28px on cards, sheets, and primary containers
- Elevation via soft shadows, not hard drop-shadows
- Glass-inspired (frosted/translucent) surfaces where appropriate (e.g., bottom sheets, modals)
- Generous spacing — avoid dense, cramped layouts; this is a "calm vault," not a data-dense dashboard

**Modes**
- Full Light Mode and Dark Mode required, theme-aware gradients (not just inverted backgrounds — gradients should remain premium-looking in both modes)
- Theme preference persisted via `themeModeProvider` (SharedPreferences-backed)

**Explicitly avoid:** complex analytics visuals, dense charts, corporate/enterprise styling, cluttered dashboards, technical-looking interfaces. This should feel closer to Linear / Arc Browser / Notion / MyMind / Pinterest than to an admin panel.

---

## 4. Information Architecture & Navigation

**Bottom Navigation (3 tabs):**
1. **Home**
2. **Search + Collections**
3. **Profile**

> This is a deliberate consolidation from the original 13-screen flat list. Below is the explicit mapping so no screen gets lost — confirm this mapping before building (see §13.2).

| Original Screen | Lives Under |
|---|---|
| Home Dashboard | Home tab |
| Search | Search + Collections tab (default sub-view) |
| Collections / Collection Details | Search + Collections tab (toggle/segmented view) |
| Add New | Global floating "+" action, available from Home and the Search+Collections tab — not a separate nav destination |
| Item Details | Pushed route, reachable from any list |
| Favorites | Accessible from Home (preview card → "see all") and/or Profile menu |
| Reminders | Accessible from Home (preview card → "see all") and/or Profile menu |
| Profile | Profile tab |
| Settings | Profile tab → menu item |
| Trash | Profile tab → menu item |
| Onboarding (Splash Screens 1–3) | Pre-auth, first-launch-only carousel; not part of bottom nav |
| Login / Signup | Pre-auth stack; not part of bottom nav |

**GoRouter route table:**
```
/splash
/onboarding
/login
/signup
/home
/explore                 (Search + Collections tab — query param or sub-route toggles mode)
/explore/collection/:id
/add                      (modal/sheet route, not full page where possible)
/item/:id
/favorites
/reminders
/profile
/profile/settings
/profile/trash
```

---

## 5. Database Schema (Authoritative — Match Exactly)

```sql
-- PROFILES (app-level user data; auth.users covers core auth)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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
  body text,
  source_url text,
  file_path text,
  thumbnail_url text,
  metadata jsonb,
  is_offline_available boolean not null default false,
  status text not null default 'active',
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

-- ITEM_TAGS
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

**Row Level Security:** enable on every table; standard policy pattern (`auth.uid() = user_id` for select/insert/update/delete) applies to `collections`, `items`, `tags`, `reminders`, `trash_items`, `favorites` (native `user_id`), and `profiles` (`auth.uid() = id`). `item_tags` policies join through `items.user_id`.

**Storage buckets:** `documents` (PDF/DOCX), `images` (image uploads + thumbnails), `user_uploads` (profile pictures). All private, path convention `{user_id}/{item_id}/{filename}`, accessed via signed URLs only.

---

## 6. Feature Implementation Requirements

### 6.1 Authentication
- Email/password signup and login via Supabase Auth.
- Google OAuth sign-in.
- Forgot password (email reset link).
- Session persistence across app restarts via the Supabase SDK's session storage.
- Real validation: email format, password ≥8 chars + 1 number, duplicate-email handling on signup.
- Real error states for network failure, invalid credentials, expired session.

### 6.2 Quick Save ("Add New")
- Four capture types: Link, Note, File (PDF/DOCX), Image.
- Link: auto-fetch metadata (title, thumbnail, description) and auto-detect sub-type (GitHub repo / YouTube video) where the URL matches known patterns; store sub-type detail in `metadata` jsonb. Fall back to generic link with zero metadata if fetch fails — never block the save.
- Note: title optional, auto-derived from first line of body if blank.
- File: real file picker, real upload to `documents` bucket, reject unsupported types before upload with a clear message.
- Image: real camera/gallery picker, real upload to `images` bucket.
- Collection and Tag assignment at save time are **optional** — save must succeed with zero additional fields beyond the captured content (see §13.3 — this is currently an open decision, build against "optional" unless told otherwise).
- Reminder assignment at save time is optional.
- Save writes to local cache instantly, then queues a real Supabase mutation — no simulated/fake "saving..." delay.

### 6.3 Collections
- Full CRUD: create, rename, delete.
- Deleting a non-empty collection must prompt: move items to Unsorted, or send items to Trash with the collection — implement both paths for real, not just the prompt UI.
- Items can be moved between collections.
- Item count per collection computed from real data, not cached/stale counts.

### 6.4 Tags
- Create, rename (propagates to all tagged items), delete (removes tag associations only, never deletes items).
- Multi-tag per item.
- Autocomplete suggestions from the user's existing tag set.

### 6.5 Search
- Incremental search as the user types, debounced (~300ms).
- Matches title, note body, tags, collection name, link metadata/description.
- Filters: content type, collection, tag, favorite status, date range — combinable.
- Must work fully offline against the local cache (Drift/sqflite), not just online via Supabase.
- Real "no results" empty state.

### 6.6 Favorites
- Single-tap toggle on any item.
- Dedicated Favorites view, synced across devices.

### 6.7 Reminders
- Date/time picker; reject past date/time with a real validation message.
- Real local notification scheduling (`flutter_local_notifications`) on Android.
- Reminders list sorted chronologically.
- Mark done / snooze, with state synced so other devices don't re-fire a completed reminder.

### 6.8 Offline Access
- All previously synced items browsable and searchable with no network connection — backed by the local Drift/sqflite cache, not SharedPreferences (see §13.1).
- Explicit "available offline" toggle per file-based item, triggering a real download into local storage.
- Offline storage usage viewable/clearable in Settings.

### 6.9 Trash
- Delete = soft delete (move to `trash_items`), never immediate hard delete from the UI delete action.
- Countdown display of days remaining before auto-purge (default 30 days).
- Restore returns the item to its original collection if it still exists, otherwise Unsorted.
- Manual permanent delete and "Empty Trash" (with confirmation) both implemented for real against Supabase.
- Auto-purge handled server-side (pg_cron), not client-side polling.

### 6.10 Real-Time Sync
- Supabase Realtime subscriptions on `items`, `collections`, `tags`, `reminders`, `trash_items`, filtered by RLS.
- Target: changes visible cross-device within 5 seconds under normal connectivity.
- Visible sync status indicator (synced / syncing / offline-pending / error) backed by real connectivity + queue state, not a static icon.
- Conflict handling: last-write-wins on `updated_at`; do not silently drop the losing edit without at least logging/retaining it.

---

## 7. Engineering Constraints (Non-Negotiable)

- No `TODO`, no stubbed return values, no hardcoded sample data standing in for a real Supabase call.
- Every async operation has explicit loading, error, and empty states — not just a happy-path render.
- All Supabase repository methods return typed success/failure results; raw exceptions do not reach the UI layer unhandled.
- All form inputs are validated before submission, with real inline error messages.
- All file/image uploads handle size-limit and unsupported-type rejection before attempting upload.
- Dark/Light mode must both be fully implemented, not just one with the other left default/unstyled.

---

## 8. Expected Deliverables Per Build Pass

When executing this prompt, output should include, per feature as it's built:
1. Domain models (with `fromJson`/`toJson` or equivalent mapping to/from Supabase rows)
2. Repository (data layer) implementation against real Supabase calls
3. Riverpod providers/notifiers
4. GoRouter route wiring
5. SQL migration additions if the feature touches schema not already covered in §5
6. Validation logic
7. Error handling paths

---

## 9. Recommended Execution Order

This is too large to generate correctly in a single pass — attempting the whole app at once tends to produce exactly the placeholder/mock code this prompt is trying to rule out, because nothing gets enough attention. Recommended phased order:

1. **Foundation:** project scaffold, folder structure, Supabase client setup, theme (light/dark + design tokens), core error/result types.
2. **Auth:** signup, login, Google OAuth, session handling, route guarding.
3. **Items core:** schema migrations, `items` repository/providers, Quick Save flow for Link + Note only (simplest two types first).
4. **Files & Images:** extend Quick Save with File/Image upload to Storage.
5. **Collections & Tags:** CRUD + assignment flows.
6. **Search:** local cache (Drift) + search/filter logic.
7. **Favorites & Reminders:** including local notifications.
8. **Offline & Sync:** Realtime subscriptions, offline queue, conflict handling, sync status indicator.
9. **Trash:** soft delete, restore, auto-purge job.
10. **Polish pass:** empty states, error states, dark/light parity check, gradient/shadow consistency pass against the design tokens in §3.

---

## 10. What This Prompt Deliberately Does Not Specify

Per your earlier direction, this prompt does not dictate screen layouts, pixel-level component styling, or widget-tree implementation details for individual screens — that's being supplied as separate frontend code. Everything above is the data/logic/architecture contract that frontend code needs to plug into (provider names, model shapes, route names, table/column names) so the two stay compatible.

---

## 11. Open Inputs Needed Before Full Execution

These aren't blockers to starting, but they will cause rework if left unresolved:

1. **Design tokens beyond color:** typography (font family/scale) and a concrete spacing scale aren't specified anywhere yet. If a frontend design-token file already exists, it should be the source of truth — point the build at it explicitly rather than letting each generated screen invent its own values.
2. **Bottom nav consolidation (§4):** the Favorites/Reminders/Settings/Trash placement mapping above is my proposed resolution of going from 13 screens to a 3-tab structure. Confirm this matches your intent before routes are wired.
3. **Collection-optional-at-save decision:** still open from the Workflow doc (Alignment Note #2 there) — this prompt builds it as optional per the PRD. Confirm if you actually want it mandatory.
4. **Content type scope:** this prompt's brief mentions GitHub repos and YouTube videos as content but the formal `item_type` enum doesn't have dedicated PPT or Instagram-reel handling (carried over from the TRD's flagged discrepancy). Decide now or explicitly defer.
5. **Offline cache library:** Drift vs. sqflite — TRD flagged this as open; pick one before the Search/Offline phases (§9, steps 6 and 8) begin.

---

*End of Document*
