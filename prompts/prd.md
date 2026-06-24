# Product Requirements Document (PRD)
## Drop Vault — Personal Knowledge & Resource Vault

| Field | Detail |
|---|---|
| Product Name | Drop Vault |
| Document Type | Product Requirements Document (PRD) |
| Version | 1.0 |
| Date | June 2026 |
| Platforms | Android (Mobile), Windows (Desktop) |
| Prepared By | Ajay  |
| Status | Draft for Development |

> Note: This PRD intentionally excludes UI/UX visual design specifications, layouts, color systems, and component styling. Frontend implementation (screens, components, styling) will be provided separately. This document defines **what the product must do**, not how it should look.

---

## 1. Executive Summary

Drop Vault is a cross-platform personal knowledge and resource management application that allows users to save, organize, search, and retrieve digital content from a single unified vault. Unlike a traditional bookmark manager, Drop Vault is designed as a universal capture tool — supporting links, documents (PDF, DOCX, PPT), images, notes, GitHub repositories, YouTube videos, Instagram reels, and other web resources — with fast retrieval through search, tags, and collections.

The core promise of the product is: **"Save anything. Find it instantly. Access it everywhere."**

---

## 2. Problem Statement

Users today scatter important content across multiple disconnected tools — browser bookmarks, notes apps, chat messages to themselves, screenshots, downloaded files, and social media "saved" tabs. This fragmentation causes:

1. Loss of valuable content over time (broken links, deleted chats, lost screenshots).
2. High friction in saving something in the moment (multi-step save flows).
3. Difficulty retrieving saved content later due to lack of structured organization.
4. No single place that supports mixed content types (a link, a PDF, and a note together).
5. No reliable cross-device continuity between mobile and desktop usage.

Drop Vault solves this by providing one frictionless capture surface and one structured retrieval system across devices.

---

## 3. Product Vision

Drop Vault should function as a **personal second brain for resources** — a single, trustworthy place where anything worth keeping can be saved in under 2 seconds, and found again in under 5 seconds, regardless of which device the user is on.

### Vision Pillars
- **Universal Capture** — any content type, one save action.
- **Instant Retrieval** — search-first, not folder-first.
- **Cross-Device Continuity** — Android and Windows stay in sync in near real-time.
- **Trust & Permanence** — nothing is permanently lost without explicit user action (Recycle Bin safety net).
- **Low Cognitive Load** — minimal mandatory steps; organization is optional, not required, at save time.

---

## 4. Goals and Success Metrics

| Goal | Metric | Target |
|---|---|---|
| Reduce save friction | Time from "share/open add screen" to "item saved" | ≤ 2 seconds for link/note; ≤ 5 seconds for file/image |
| Fast retrieval | Time from opening search to displaying relevant result | ≤ 1 second for indexed local search |
| Cross-device reliability | Sync completion time after save (online) | ≤ 5 seconds |
| Data safety | Accidental permanent data loss incidents | 0 (all deletions reversible within retention window) |
| Retention | 7-day and 30-day active usage retention | Defined post-launch via analytics |
| Organization adoption | % of saved items assigned to a collection or tag within 24 hrs | Tracked, not enforced |

---

## 5. Target Users & Personas

### Persona 1 — The Student Researcher
Collects study material, PDFs of notes, YouTube lecture links, and reference articles for exams and projects. Needs fast tagging by subject and quick retrieval before exams.

### Persona 2 — The Developer
Saves GitHub repositories, technical documentation links, Stack Overflow threads, and code snippets/notes. Needs search by tag/category (e.g., "React", "DSA") and quick access on desktop while coding.

### Persona 3 — The Content Consumer
Saves Instagram reels, YouTube videos, and articles encountered while browsing/scrolling, intending to revisit later. Needs a "Watch Later"-style experience that doesn't get lost.

### Persona 4 — The Working Professional
Saves documents (DOCX, PPT, PDF), meeting links, and reference notes. Needs reminders to follow up and a Favorites system for frequently accessed material.

### Persona 5 — The General Productivity User
Wants a single replacement for browser bookmarks + notes app + downloaded files folder, organized into personal collections like "Travel," "Personal," "Fitness."

---

## 6. Platform Scope

| Platform | Role |
|---|---|
| Android Mobile App | Primary capture device — used for quick saving on the go (via share intent, in-app add) and browsing/searching saved content. |
| Windows Desktop App | Primary organization & deep-work device — used for managing collections, bulk organization, and consuming saved long-form content (PDFs, docs). |

Both platforms must support full CRUD on all entities; neither platform is "read-only." Real-time sync keeps both in parity.

---

## 7. Scope Definition

### 7.1 In Scope (Version 1.0)
- User authentication (Email + Google)
- Save: Links, PDFs, DOCX, PPT, Images, Notes
- Auto-recognition of special link types: GitHub repositories, YouTube videos, Instagram reels
- Collections (custom, user-created, unlimited)
- Tags (multi-tag per item)
- Favorites
- Search with filters (type, collection, tag, favorite status, date)
- Reminders (date/time-based, per item)
- Offline access (previously synced/cached content available without internet)
- Recycle Bin (soft delete with retention period and restore)
- Real-time sync between Android and Windows
- Profile management
- Settings (theme preference, notifications, sync, offline storage management)

### 7.2 Out of Scope (Version 1.0)
- Collaboration / multi-user shared collections
- Public sharing of collections or items
- Browser extension (Chrome/Edge capture extension)
- AI-based auto-summarization or auto-tagging
- Web app / iOS app
- Advanced analytics or usage dashboards
- Team/enterprise accounts or billing tiers
- Third-party integrations beyond GitHub/YouTube/Instagram link parsing (e.g., no native Notion/Drive import in v1)

These are candidates for future roadmap phases (see Section 19).

---

## 8. Core Functional Requirements

Each feature below is specified with: description, functional requirements (FR), and acceptance criteria. FR IDs are sequential per feature for traceability.

### 8.1 Authentication

**Description:** Users must create an account and log in to sync and access their vault. Supports Email/Password and Google Sign-In.

| ID | Requirement |
|---|---|
| FR-AUTH-1 | System shall allow account creation via email + password. |
| FR-AUTH-2 | System shall allow account creation/login via Google OAuth. |
| FR-AUTH-3 | System shall enforce password rules (min 8 characters, at least 1 number). |
| FR-AUTH-4 | System shall support "Forgot Password" via email reset link. |
| FR-AUTH-5 | System shall persist login session until explicit logout (no forced re-login unless token expired/revoked). |
| FR-AUTH-6 | System shall support logout from a single device without affecting sessions on other devices. |
| FR-AUTH-7 | System shall block account creation with an email already registered, prompting login instead. |

**Acceptance Criteria:**
- A new user can register and immediately access an empty vault.
- A returning user logging in on a second device sees their existing vault content (post-sync).
- Invalid credentials return a clear, non-revealing error (no "email not found" vs "wrong password" distinction, for security).

---

### 8.2 Universal Quick Save ("Add New")

**Description:** The single most critical feature — a fast, low-friction capture mechanism supporting all content types from both platforms.

| ID | Requirement |
|---|---|
| FR-SAVE-1 | System shall support saving a Link (URL) via manual paste/type entry. |
| FR-SAVE-2 | System shall support saving a Link via OS-level Share intent (Android) — e.g., sharing a link from Chrome/Instagram/YouTube directly into Drop Vault. |
| FR-SAVE-3 | System shall support saving a Note (free text, title + body). |
| FR-SAVE-4 | System shall support uploading a file (PDF, DOCX, PPT) from device storage. |
| FR-SAVE-5 | System shall support saving an Image (camera capture or gallery/file picker). |
| FR-SAVE-6 | System shall allow a save action to complete with zero mandatory fields beyond the content itself (title, collection, tags are optional at save time and can be added later). |
| FR-SAVE-7 | System shall auto-generate a title from content where possible (e.g., webpage title via metadata fetch, file name for documents) if user does not provide one. |
| FR-SAVE-8 | System shall auto-fetch link preview metadata (title, thumbnail, description, favicon/source) for saved links where reachable. |
| FR-SAVE-9 | System shall allow assigning a Collection and Tags at save time as an optional secondary step, not blocking the save action itself. |
| FR-SAVE-10 | System shall confirm successful save with a lightweight, non-blocking confirmation (e.g., toast/snackbar), allowing the user to immediately continue their previous activity. |
| FR-SAVE-11 | System shall queue saves made while offline and sync them automatically once connectivity is restored. |

**Acceptance Criteria:**
- A user can save a shared link from another app to Drop Vault in 2 taps or fewer.
- A note can be created and saved with just a body of text (title optional).
- Saving while offline does not produce an error; the item appears in the vault immediately (locally) and syncs later.

---

### 8.3 Content Type Auto-Recognition

**Description:** Drop Vault should intelligently classify certain links into specialized sub-types for better organization and display logic (without requiring the user to manually tag the type).

| ID | Requirement |
|---|---|
| FR-TYPE-1 | System shall detect and classify a saved URL as one of: Generic Link, GitHub Repository, YouTube Video, Instagram Reel/Post. |
| FR-TYPE-2 | System shall extract relevant metadata per type: GitHub → repo name, description, star count (if available via public API); YouTube → video title, channel, thumbnail, duration; Instagram → thumbnail/caption where publicly accessible. |
| FR-TYPE-3 | System shall fall back gracefully to "Generic Link" type with basic metadata (or no metadata) if specialized parsing fails or the API/source is unreachable. |
| FR-TYPE-4 | System shall allow the auto-detected type to be used as a filter category in Search. |

**Acceptance Criteria:**
- Pasting a YouTube URL results in an item showing video thumbnail + title without manual entry.
- Pasting a GitHub repo URL results in an item tagged as "GitHub Repository" type automatically.
- A failed metadata fetch never blocks the save — item is still saved with the raw URL.

---

### 8.4 Collections

**Description:** User-defined containers for organizing saved items (e.g., "Study," "Programming," "Travel").

| ID | Requirement |
|---|---|
| FR-COL-1 | System shall allow users to create unlimited custom collections. |
| FR-COL-2 | System shall allow renaming an existing collection. |
| FR-COL-3 | System shall allow deleting a collection. |
| FR-COL-4 | On collection deletion, system shall prompt user to choose: (a) move contained items to "Unsorted," or (b) move contained items to Recycle Bin along with the collection. |
| FR-COL-5 | System shall allow moving an item from one collection to another. |
| FR-COL-6 | System shall allow an item to belong to only one Collection at a time (single-parent model), while still supporting multiple Tags (many-to-many) for cross-cutting organization. |
| FR-COL-7 | System shall display item count per collection. |
| FR-COL-8 | System shall provide a default "Unsorted" or "All Items" pseudo-collection for items not yet assigned. |
| FR-COL-9 | System shall prevent duplicate collection names for the same user (case-insensitive check), or allow with a disambiguation suffix — decision to be confirmed (see Open Questions). |

**Acceptance Criteria:**
- Creating, renaming, and deleting a collection all reflect instantly across both platforms after sync.
- Deleting a collection never silently deletes its items without explicit user choice.

---

### 8.5 Tags

**Description:** Lightweight, cross-cutting labels independent of collections.

| ID | Requirement |
|---|---|
| FR-TAG-1 | System shall allow users to create free-form tags. |
| FR-TAG-2 | System shall allow assigning multiple tags to a single item. |
| FR-TAG-3 | System shall allow removing a tag from an item. |
| FR-TAG-4 | System shall allow renaming a tag globally (renaming updates it across all tagged items). |
| FR-TAG-5 | System shall allow deleting a tag globally (removes tag from all items; does not delete the items). |
| FR-TAG-6 | System shall suggest previously used tags during tag entry (autocomplete from user's existing tag list). |
| FR-TAG-7 | System shall support filtering/search by tag. |

**Acceptance Criteria:**
- A single item can carry 0 to N tags.
- Deleting a tag never deletes the underlying item.

---

### 8.6 Favorites

| ID | Requirement |
|---|---|
| FR-FAV-1 | System shall allow marking/unmarking any item as Favorite via a single toggle action. |
| FR-FAV-2 | System shall maintain a dedicated Favorites view showing all favorited items regardless of their collection. |
| FR-FAV-3 | Favorite status shall sync across devices. |

---

### 8.7 Search

**Description:** The primary retrieval mechanism; must be fast and forgiving.

| ID | Requirement |
|---|---|
| FR-SRCH-1 | System shall provide a search bar accessible from the main dashboard. |
| FR-SRCH-2 | System shall return results as the user types (instant/incremental search), with a debounce of ≤300ms. |
| FR-SRCH-3 | Search shall match against: item title, note body text, tags, collection name, and (where available) extracted link metadata/description. |
| FR-SRCH-4 | System shall support filtering search results by content type: Links, Notes, Files, Images (and sub-types: GitHub, YouTube, Instagram). |
| FR-SRCH-5 | System shall support filtering by Collection, Tag, Favorite status, and Date Saved range. |
| FR-SRCH-6 | System shall support combining multiple filters simultaneously (AND logic). |
| FR-SRCH-7 | Search shall function fully offline against locally cached/synced data. |
| FR-SRCH-8 | System shall show "No results" state with a suggestion to adjust filters/spelling when no matches are found. |
| FR-SRCH-9 | System shall maintain a short recent-searches list for quick re-access (local, per-device, clearable by user). |

**Acceptance Criteria:**
- Searching "react" returns items tagged "react," items in a "React" collection, and notes containing the word "react," ranked by relevance/recency.
- Search works with no internet connection for already-synced content.

---

### 8.8 Reminders

**Description:** Time-based nudges tied to specific saved items (e.g., "remind me to read this PDF Friday").

| ID | Requirement |
|---|---|
| FR-REM-1 | System shall allow setting a reminder (date + time) on any saved item. |
| FR-REM-2 | System shall allow editing or removing a reminder. |
| FR-REM-3 | System shall trigger a push/local notification at the reminder time on Android. |
| FR-REM-4 | System shall trigger a desktop notification at the reminder time on Windows, if the app is running/in background. |
| FR-REM-5 | System shall provide a dedicated Reminders view listing all upcoming reminders, sorted chronologically. |
| FR-REM-6 | System shall mark a reminder as completed/dismissed once acknowledged, removing it from the active upcoming list (but not deleting the underlying item). |
| FR-REM-7 | System shall support snoozing a reminder by a user-selected duration. |
| FR-REM-8 | Reminder state and schedule shall sync across devices to avoid duplicate notifications firing independently per device (single source of truth + per-device delivery suppression once acknowledged). |

**Acceptance Criteria:**
- Setting a reminder on mobile and acknowledging it from desktop removes the pending state from both.
- A reminder fires even if the specific item's collection was later deleted (as long as item itself still exists).

---

### 8.9 Offline Access

**Description:** Core browsing/search functionality must not depend on live connectivity.

| ID | Requirement |
|---|---|
| FR-OFF-1 | System shall cache all item metadata locally on each device after first sync. |
| FR-OFF-2 | System shall allow user to mark specific files (PDF/DOCX/PPT/Images) for "available offline," downloading the full file content locally. |
| FR-OFF-3 | System shall clearly indicate offline-availability status per item (available vs. metadata-only/requires connection). |
| FR-OFF-4 | System shall allow new saves, edits, deletes, tagging, and collection changes while offline, queuing them for sync. |
| FR-OFF-5 | System shall allow users to manage local storage usage (view/clear offline-cached files) via Settings. |
| FR-OFF-6 | System shall set a configurable storage cap/warning for offline file caching (default value to be defined by engineering based on device constraints). |

**Acceptance Criteria:**
- Items marked "available offline" open and display correctly with airplane mode on.
- Storage used by offline files is visible and manageable in Settings.

---

### 8.10 Recycle Bin (Trash)

**Description:** Safety-net for deletions; nothing is destroyed immediately.

| ID | Requirement |
|---|---|
| FR-TRASH-1 | Deleting an item (or a collection per FR-COL-4) shall move it to Trash rather than permanently delete it. |
| FR-TRASH-2 | System shall retain trashed items for a defined retention period (default: 30 days) before automatic permanent deletion. |
| FR-TRASH-3 | System shall display remaining days before permanent auto-deletion per trashed item. |
| FR-TRASH-4 | System shall allow restoring an item from Trash to its original (or a new) Collection. |
| FR-TRASH-5 | System shall allow permanently deleting an item from Trash immediately (manual override of the retention period). |
| FR-TRASH-6 | System shall allow "Empty Trash" (permanently delete all trashed items at once), with a confirmation prompt. |
| FR-TRASH-7 | Trash state and contents shall sync across devices. |

**Acceptance Criteria:**
- A deleted item can be fully recovered (including tags and collection assignment) within the retention window.
- After the retention period expires, the item is automatically and permanently removed without further user action.

---

### 8.11 Real-Time Sync (Android ⇄ Windows)

**Description:** Keeps both platforms consistent with minimal lag.

| ID | Requirement |
|---|---|
| FR-SYNC-1 | System shall sync all entities (items, collections, tags, favorites, reminders, trash state) across devices when online. |
| FR-SYNC-2 | System shall sync changes within ≤5 seconds under normal connectivity conditions. |
| FR-SYNC-3 | System shall resolve conflicting edits (same item edited on two devices while offline) using a last-write-wins strategy by default, with the losing version preserved in a recoverable change log for a limited time. |
| FR-SYNC-4 | System shall show a sync status indicator (e.g., synced / syncing / offline-pending). |
| FR-SYNC-5 | System shall queue and retry failed sync operations automatically without user intervention. |
| FR-SYNC-6 | System shall support manual "force sync" trigger from Settings. |

**Acceptance Criteria:**
- A save on Android appears on Windows within 5 seconds when both are online.
- Conflicting offline edits do not silently destroy data — the non-winning edit remains retrievable for a defined window.

---

### 8.12 Item Details

**Description:** The detailed view/record for any single saved item, regardless of type.

| ID | Requirement |
|---|---|
| FR-ITEM-1 | System shall display, per item: content preview (type-dependent), title, description/notes, assigned Collection, assigned Tags, Date Saved, Reminder (if any), Favorite status, Offline availability status. |
| FR-ITEM-2 | System shall allow editing title, description, Collection, Tags, and Reminder directly from the Item Details view. |
| FR-ITEM-3 | System shall allow opening the original source (e.g., launching the link in browser, opening the file in default/native viewer). |
| FR-ITEM-4 | System shall allow deleting (to Trash) directly from Item Details. |
| FR-ITEM-5 | System shall record and display "Date Saved" (immutable, system-generated) and "Date Modified" (updated on edits). |

---

### 8.13 Settings

| ID | Requirement |
|---|---|
| FR-SET-1 | System shall allow toggling Light Mode / Dark Mode preference (or following system theme). |
| FR-SET-2 | System shall allow enabling/disabling notification categories (Reminders, Sync alerts, etc.) independently. |
| FR-SET-3 | System shall allow configuring sync behavior (e.g., Wi-Fi only vs. any network for large file sync). |
| FR-SET-4 | System shall allow managing offline storage (view usage, clear cached files) per FR-OFF-5. |
| FR-SET-5 | System shall allow account management actions: change password, log out, delete account. |
| FR-SET-6 | Account deletion shall permanently remove all user data after a confirmation step, independent of the standard Trash retention logic. |

---

### 8.14 Profile

| ID | Requirement |
|---|---|
| FR-PROF-1 | System shall display basic user profile info: name, email, profile picture (if set via Google or manually uploaded). |
| FR-PROF-2 | System shall allow editing display name and profile picture. |
| FR-PROF-3 | System shall display basic vault stats (e.g., total items saved, total collections) — informational only, not analytics dashboards. |

---

## 9. Screen Inventory (Functional Scope Only)

This section defines what each required screen must accomplish functionally — **not** its layout or visual design, since frontend will be supplied separately. Each entry lists purpose, required data, and required actions.

### 9.1 Mobile Screens

| Screen | Purpose | Data Required | Actions Required |
|---|---|---|---|
| Splash | App initialization, session check | N/A | Auto-route to Login or Home based on session validity |
| Login | Authenticate existing user | Email, password fields | Submit login, Google sign-in, navigate to Signup, navigate to Forgot Password |
| Signup | Create new account | Name, email, password fields | Submit registration, Google sign-up, navigate to Login |
| Home Dashboard | Central hub | Recent saves, Collections summary, Favorites summary, upcoming reminders summary | Trigger Quick Add, navigate to Search, navigate to any Collection, navigate to Favorites/Reminders |
| Search | Find saved content | Search query, filter state, result list | Enter query, apply/remove filters, open an item, clear recent search |
| Collections | Browse all collections | List of collections with item counts | Create collection, open a collection, rename/delete via item-level action |
| Collection Details | View items within one collection | List of items in the collection | Open item, move item out, delete item, add item directly to this collection |
| Add New | Universal capture | Input fields per type (URL, note text, file picker, image picker) | Save link/note/file/image, optionally assign collection/tags before confirming |
| Item Details | View/manage one item | All item fields (see FR-ITEM-1) | Edit fields, toggle favorite, set/edit reminder, delete (to trash), open source |
| Favorites | View favorited items | List of favorited items across all collections | Open item, unfavorite |
| Reminders | View active reminders | List of items with upcoming/active reminders, sorted by time | Open item, snooze, mark done, edit/remove reminder |
| Profile | View/edit account info | Name, email, picture, vault stats | Edit name/picture, navigate to Settings |
| Settings | Configure app behavior | Theme, notification toggles, sync prefs, offline storage usage | Toggle settings, trigger force sync, manage offline storage, logout/delete account |
| Trash | Manage deleted items | List of trashed items with days-remaining indicator | Restore item, permanently delete item, empty trash |

### 9.2 Desktop Screens (Windows)

Functional structure (not visual layout): a persistent navigation surface, a primary content surface, and a contextual detail surface, mapped as follows:

| Functional Region | Purpose | Maps To (Mobile Equivalent) |
|---|---|---|
| Navigation surface | Persistent access to Home, Collections, Favorites, Reminders, Search, Trash, Settings, Profile | Bottom nav / drawer equivalent on mobile |
| Primary content surface | Displays whichever section is active (Dashboard, Collection contents, Search results, Trash contents) | Main screen body on mobile |
| Contextual detail surface | Displays Item Details / metadata / quick actions for a selected item without leaving the current list context | Item Details screen on mobile (here, shown alongside the list rather than as a full navigation) |

All functional requirements from Section 8 apply equally to desktop; no feature is mobile-only or desktop-only except OS-level mobile share-intent capture (FR-SAVE-2), which is mobile-specific by nature, and bulk file drag-and-drop import, which is desktop-appropriate but not required for v1 unless specified by engineering.

---

## 10. User Flows (Functional Description)

### 10.1 Onboarding Flow
1. App launch → Splash → session check.
2. No session → Login screen.
3. New user → Signup → account created → land on empty Home Dashboard.
4. Returning user → Login → sync triggers → Home Dashboard populated with existing vault.

### 10.2 Quick Save Flow (Target: ≤2 seconds for link/note)
1. Trigger save (in-app "Add New" action, or Android Share Intent from another app).
2. Content type auto-detected (link/note/file/image).
3. Metadata auto-fetched if applicable (FR-SAVE-7/8, FR-TYPE-1–3).
4. Item saved immediately to local store; confirmation shown.
5. (Optional, non-blocking) user may assign Collection/Tags either immediately or later from Item Details.
6. Background sync pushes item to other devices.

### 10.3 Search Flow
1. User opens Search.
2. User types query → incremental results appear.
3. User optionally applies filters (type/collection/tag/favorite/date).
4. User selects a result → Item Details opens.

### 10.4 Collection Management Flow
1. User creates a Collection (name only required).
2. User assigns items to the Collection (from Add New, Item Details, or via "move" action from Collection Details/Search results).
3. User may rename or delete the Collection at any time; deletion triggers the item-handling choice (FR-COL-4).

### 10.5 Reminder Flow
1. From Item Details, user sets a date/time reminder.
2. Reminder appears in Reminders screen, sorted chronologically.
3. At trigger time, notification fires on whichever device(s) are eligible per FR-REM-3/4.
4. User acknowledges (mark done) or snoozes; state syncs to suppress duplicate firing on other devices.

### 10.6 Delete & Restore Flow
1. User deletes an item → moves to Trash (not permanently deleted).
2. Item remains in Trash for retention period (default 30 days), visible with countdown.
3. User may restore (returns to prior or new Collection) or permanently delete manually.
4. If untouched, item is auto-purged after retention period expires.

### 10.7 Sync Flow (Cross-Device)
1. Any create/update/delete action is written to local storage immediately (optimistic local-first write).
2. Action is queued for sync.
3. When online, sync engine pushes changes to backend and pulls remote changes.
4. Conflicting edits resolved per FR-SYNC-3.
5. Both devices converge to the same state within target sync latency (FR-SYNC-2).

---

## 11. Data Model

### 11.1 Entities and Key Fields

**User**
- user_id (unique)
- name
- email
- auth_provider (email | google)
- profile_picture_url
- created_at

**Item**
- item_id (unique)
- user_id (owner)
- type (link | pdf | docx | ppt | image | note | github_repo | youtube_video | instagram_reel)
- title
- description/body (for notes; or fetched description for links)
- source_url (for links/sub-types)
- file_reference (for uploaded files/images — storage pointer, not raw blob in this model)
- thumbnail_url
- collection_id (nullable → "Unsorted" if null)
- tag_ids (many-to-many)
- is_favorite (boolean)
- offline_available (boolean)
- reminder_id (nullable, one-to-one or one-to-many if multiple reminders are allowed per item — default: one active reminder per item for v1)
- date_saved (immutable)
- date_modified
- deleted_at (nullable — null = active, non-null = in Trash)
- permanently_delete_at (calculated: deleted_at + retention period)

**Collection**
- collection_id (unique)
- user_id (owner)
- name
- created_at
- item_count (derived/aggregated, not stored redundantly if avoidable)

**Tag**
- tag_id (unique)
- user_id (owner)
- name

**Reminder**
- reminder_id (unique)
- item_id (foreign key)
- trigger_datetime
- status (pending | completed | snoozed)
- snoozed_until (nullable)

**TrashLog / DeletedItem** (can be modeled as a state on Item via `deleted_at`, or as a separate ledger if audit history is required)
- references item_id
- deleted_at
- scheduled_purge_at

**SyncDevice** (for multi-device awareness, optional but recommended for conflict handling and reminder de-duplication)
- device_id
- user_id
- platform (android | windows)
- last_synced_at

### 11.2 Relationships
- A User has many Items, Collections, and Tags.
- An Item belongs to exactly one Collection (or none → Unsorted) and may have many Tags.
- An Item may have at most one active Reminder in v1.
- A Tag may be associated with many Items, and an Item may have many Tags (many-to-many).
- Deleting a Collection does not cascade-delete Items by default; behavior is governed by FR-COL-4.

---

## 12. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Local search results return in ≤1 second for vaults up to at least 10,000 items. |
| Performance | Save action completes its local write (not full cloud sync) in ≤2 seconds regardless of network state. |
| Offline-First | All read operations (browsing, search, viewing previously synced items) must function fully without connectivity. |
| Reliability | No user action shall result in irreversible data loss without explicit confirmation (Trash safety net, Section 8.10). |
| Security | All data in transit must be encrypted (TLS). All authentication tokens must be securely stored on-device (platform keystore/secure storage), not in plain text. |
| Security | Passwords must never be stored or logged in plaintext; must be hashed using an industry-standard algorithm server-side. |
| Privacy | User content (notes, files) must not be accessible to other users; no cross-user data leakage. |
| Scalability | Backend data model must support a single user scaling to tens of thousands of items without degrading search/sync performance. |
| Availability | Sync backend should target high availability; client must degrade gracefully (offline mode) during backend downtime rather than blocking core functionality. |
| Accessibility | Functional flows must not assume sight-only or touch-only interaction patterns where reasonably avoidable (e.g., support standard OS accessibility services); detailed accessibility implementation is a frontend concern but is noted here as a product requirement. |
| Localization | v1 ships in English only; data model should not hard-block future localization (no hard-coded user-facing strings in business logic layers). |

---

## 13. Technical Considerations (Platform-Agnostic)

> These are product-level technical requirements to guide architecture decisions. They do not prescribe frontend implementation.

- **Backend/API:** A central backend service must expose authenticated APIs for all entity CRUD operations (Items, Collections, Tags, Reminders, Trash) and must be the single source of truth for sync resolution.
- **File Storage:** Uploaded files (PDF/DOCX/PPT/Images) require cloud object storage with per-user access scoping; the Item record stores a reference/pointer, not the raw file, in the primary database.
- **Metadata Fetching:** Link preview and special-type metadata fetching (YouTube/GitHub/Instagram) should occur server-side or via a dedicated service to avoid exposing API keys client-side and to allow caching of metadata across requests.
- **Authentication:** Must support standard email/password auth plus Google OAuth2; backend must issue and validate session tokens (e.g., JWT or equivalent) with refresh capability.
- **Push Notifications:** Reminder delivery requires a push notification service for Android (e.g., FCM-equivalent) and a local/background notification mechanism for Windows.
- **Sync Engine:** Requires a delta-sync or event-log-based mechanism so devices only transfer changes, not full vault snapshots, on each sync cycle, to keep sync latency low (FR-SYNC-2).
- **Data Retention Jobs:** Backend requires a scheduled job/process to handle automatic permanent deletion of Trash items past their retention period (FR-TRASH-2).

---

## 14. Notification & Reminder Logic Detail

- Reminder notifications are item-scoped, one active reminder per item in v1.
- A reminder's `status` transitions: `pending → completed` (user acknowledges) or `pending → snoozed → pending` (with updated `snoozed_until`/`trigger_datetime`).
- Once `completed`, no further notification fires for that reminder instance; user must create a new reminder if desired again.
- Cross-device suppression: once any device marks a reminder `completed`, the change must sync before other devices' scheduled local notifications fire; if a device fires a notification for an already-completed reminder due to sync lag, this is an acceptable, low-frequency edge case rather than a blocking requirement for v1.

---

## 15. Search & Filter Logic Specification

**Indexed fields:** item title, note body, tags (by name), collection name, link metadata description (where fetched), content type.

**Filter dimensions (combinable via AND):**
- Content Type: Link, Note, File (PDF/DOCX/PPT), Image, GitHub Repo, YouTube Video, Instagram Reel
- Collection
- Tag (one or more)
- Favorite status (Yes/No)
- Date Saved (range: e.g., last 7 days, last 30 days, custom range)

**Ranking (suggested default, refinable during implementation):**
1. Exact title match
2. Tag/collection name match
3. Body/description text match
4. Recency (date_saved, descending) as tiebreaker

---

## 16. Recycle Bin Logic Detail

- Default retention: 30 days from `deleted_at`.
- Countdown displayed as whole days remaining.
- Manual permanent delete available at any time during retention window.
- "Empty Trash" requires explicit confirmation (cannot be undone).
- Auto-purge job runs on a recurring schedule (e.g., daily) to remove items past `permanently_delete_at`.
- Restoring an item clears `deleted_at` and `permanently_delete_at`, and re-attaches it to its prior Collection if that Collection still exists; otherwise routes to Unsorted.

---

## 17. Sync & Conflict Resolution Detail

- All writes are local-first (optimistic), then queued for sync.
- Default conflict strategy: **last-write-wins** based on `date_modified` timestamp.
- The losing edit in a conflict is not silently discarded — it is retained in a short-lived change log (e.g., 7 days) accessible via a "recently overwritten changes" mechanism, to prevent silent data loss. (Exact surfacing of this in UI is a frontend decision; the requirement here is that the data is not immediately and irrecoverably destroyed.)
- Sync status must be observable by the client at all times (synced / syncing / pending-offline-changes / error).

---

## 18. Error Handling & Edge Cases

| Scenario | Required Behavior |
|---|---|
| Saving a malformed/unreachable URL | Save succeeds with raw URL; metadata fields remain empty; no blocking error. |
| Uploading an unsupported file type | Reject upload with a clear reason; supported types are explicitly PDF, DOCX, PPT, and standard image formats (JPG/PNG/WEBP) for v1. |
| File exceeds size limit | Reject upload with size limit clearly communicated (exact limit to be set by engineering based on storage cost constraints). |
| Duplicate link saved twice | Allowed; system does not block duplicates in v1, but may optionally surface "similar item already saved" as a soft warning (non-blocking) — candidate for v1.1 if feasible. |
| Offline save followed by failed sync (e.g., auth expired) | Item remains safely stored locally; sync retries automatically; user is not blocked from continuing to use the app. |
| Reminder set for a past date/time | System should reject or auto-correct to "now," with a clear message — exact handling to be confirmed (see Open Questions). |
| Deleting a Collection that is currently filtered/viewed | Gracefully redirect view to "All Items" or "Unsorted" rather than erroring. |
| Account deleted while items are mid-sync on another device | Other device should receive an auth invalidation and prompt re-login; local cached data on that device should not be assumed safe to retain indefinitely. |

---

## 19. Assumptions & Constraints

- Users have at least intermittent internet access; the product is offline-tolerant, not offline-only/local-only by design (sync is a core value proposition).
- GitHub/YouTube/Instagram metadata fetching depends on availability and rate limits of public/official APIs or scraping fallback; reliability of sub-type metadata is best-effort, not guaranteed.
- Android and Windows are the only supported platforms for v1; no iOS, no web client.
- Single-user vaults only in v1 — no shared/collaborative collections.
- Frontend implementation, visual design, and component-level UX are handled outside this PRD per project owner's direction.

---

## 20. Future Roadmap (Post-v1 Candidates)

These are explicitly **out of scope** for v1 but recorded for future planning:

- Browser extension for one-click web capture.
- AI-assisted auto-tagging or content summarization.
- Shared/collaborative collections with multiple users.
- Public collection sharing (read-only public links).
- iOS and Web client support.
- Duplicate-detection with merge suggestions.
- Full-text extraction and search within PDF/DOCX content (beyond filename/title-level indexing).
- Import tools from existing sources (browser bookmarks, Notion, Pocket, etc.).

---

## 21. Open Questions (To Be Resolved Before/During Development)

1. Should duplicate collection names be blocked outright, or allowed with auto-disambiguation (e.g., "Travel (2)")?
2. What is the exact maximum file size per upload, and is it tier-dependent (free vs. potential future paid tier)?
3. Should reminders support recurrence (daily/weekly) in v1, or strictly one-time in v1 with recurrence deferred to roadmap?
4. What exact default offline-storage cap should trigger a warning to the user?
5. Should duplicate link detection (soft warning) be included in v1 or deferred to v1.1?
6. Is multi-reminder support per item needed in v1, or is single-active-reminder-per-item sufficient?

---

## 22. Glossary

- **Item:** Any single saved piece of content (link, file, image, or note) in the vault.
- **Collection:** A user-created folder-like container for organizing Items (single-parent per Item).
- **Tag:** A free-form, many-to-many label usable across Collections for cross-cutting organization.
- **Vault:** The complete set of a user's saved Items, Collections, Tags, and related data.
- **Soft Delete:** Moving an Item to Trash rather than immediately and permanently deleting it.
- **Sync:** The process of reconciling data state between the Android and Windows clients via the backend.

---

*End of Document*