# User Workflow Specification
## Drop Vault — Detailed Flow Document

| Field | Detail |
|---|---|
| Product Name | Drop Vault |
| Document Type | User Workflow Specification |
| Version | 1.0 |
| Date | June 2026 |
| Companion Documents | Drop Vault PRD v1.0, Drop Vault TRD v1.0 |
| Prepared By | Ajay Singh |

> Scope note: This document specifies *behavior* — what happens at each step, what branches exist, what can fail — not visual design. References to PRD (FR-IDs) and TRD (providers/tables) are included so this stays traceable to the other two documents.

---

## 1. Purpose

The flow you provided maps the primary "happy path" through the app. This document expands that into a full behavioral specification: every step's preconditions, system actions, branch points, and failure handling — and flags a few places where the literal flow as drawn conflicts with requirements already locked in the PRD/TRD, so those can be resolved before build.

---

## 2. High-Level Flow (as provided, annotated)

```
App Launch
  │
  ▼
Technical Splash (session check)         ← see Alignment Note #1
  │
  ├── First-ever launch? ──► Onboarding Carousel (Screens 1–3)
  │                              │
  │                              ▼
  └── Returning user? ──────► (skip onboarding)
                                 │
                                 ▼
                    Has valid session?
                       │              │
                      Yes             No
                       │              │
                       ▼              ▼
                  Home Dashboard   Login / Signup
                                       │
                                       ▼
                                 Home Dashboard
```

```
Home Dashboard
  │
  ▼
User taps "+" (Quick Add)
  │
  ▼
Choose type: Link | Note | File | Image
  │
  ▼
Capture content (paste URL / type note / pick file / pick image)
  │
  ▼
[OPTIONAL] Assign Collection (existing or new)      ← see Alignment Note #2
  │
  ▼
[OPTIONAL] Add Tags
  │
  ▼
[OPTIONAL] Set Reminder
  │
  ▼
Save
  │
  ▼
Item written locally + queued for sync
  │
  ▼
Item visible in: Home (Recent) · its Collection (if assigned) · Search index · Favorites (only if favorited)
  │
  ▼
User can: Search · Edit · Favorite · Delete (→Trash) · Restore (from Trash)
  │
  ▼
Realtime sync propagates change to other signed-in devices
```

---

## 3. Detailed Step-by-Step Specification

### 3.1 App Launch → Technical Splash

| Aspect | Detail |
|---|---|
| Trigger | App process starts |
| System action | Initialize Supabase client; attempt to restore session from secure local session storage (per TRD §5.1) |
| Duration target | < 2 seconds total (PRD §4, TRD §8) |
| Branch | Session valid → proceed to Home Dashboard. Session missing/expired → proceed to Login. First-ever launch (no `onboarding_complete` flag in SharedPreferences) → proceed to Onboarding Carousel first, regardless of session state. |
| Failure case | Supabase unreachable at launch → app should still open into a degraded/offline mode using locally cached data (per PRD §8.9), not block on a network call. |

### 3.2 Onboarding Carousel (Screens 1–3)

| Aspect | Detail |
|---|---|
| Trigger | `onboarding_complete` flag is false/absent |
| Purpose | Introduce the app's value proposition before requiring account creation — this is the "Premium onboarding experience" referenced in the original design brief, distinct from the technical splash above |
| User action | Swipe/advance through 3 screens, or skip |
| System action on completion/skip | Set `onboarding_complete = true` in SharedPreferences so this never shows again on this device |
| Note | Onboarding is a one-time, per-device, pre-auth experience. It should not reappear after login on the same device, and a second device for the same account does not need to repeat it unless product wants per-device first-impressions (decision: keep per-device, simplest to implement) |

### 3.3 Login / Signup

| Aspect | Detail |
|---|---|
| Entry point | From splash (no session) or explicit logout |
| Required fields | Login: email + password, or Google sign-in tap. Signup: name + email + password, or Google sign-up tap |
| System action | Calls Supabase Auth; on success, session stored; on first-ever signup, a `profiles` row is created (TRD §5.2) |
| Success | Navigate to Home Dashboard |
| Failure cases | Invalid credentials → generic error message (PRD FR-AUTH security note); network failure → retry option, no silent hang; email already registered during signup → prompt to log in instead (FR-AUTH-7) |
| New user state | Home Dashboard renders with zero items, zero collections — empty states must be handled gracefully, not as an error |

### 3.4 Home Dashboard

| Aspect | Detail |
|---|---|
| Data shown | Recent saves, Collections preview, Favorites preview, upcoming Reminders preview (PRD §9, screen inventory) |
| Data source | Realtime-backed providers (`userItemsProvider`, `collectionsProvider`, `remindersProvider` — TRD §4.3), read from local cache first |
| Primary action | Tap "+" → Quick Add |
| Secondary actions | Tap into Search, a Collection, Favorites, or Reminders |

### 3.5 Quick Add — Type Selection

| Aspect | Detail |
|---|---|
| Options | Add Link, Add Note, Upload File, Add Image |
| System action | Routes to the appropriate capture input for the chosen type |
| Note | This in-app "+" flow is **one of two entry points** for saving content — see Alignment Note #3 for the second (Android share-intent) entry point, which bypasses this screen entirely |

### 3.6 Content Capture (per type)

| Type | Capture mechanism | Auto-behavior |
|---|---|---|
| Link | Paste/type URL | Metadata fetch attempted (title, thumbnail, sub-type detection — PRD FR-SAVE-8, FR-TYPE-1) |
| Note | Free-text title + body | Title auto-derived from first line if left blank (FR-SAVE-7) |
| File | Device file picker (PDF/DOCX, and per TRD scope clarification, PPT pending decision) | Filename used as default title; uploads to `documents` bucket (TRD §5.5) |
| Image | Camera or gallery picker | Uploads to `images` bucket; thumbnail generated/used directly |

**Failure handling at this step:** unreachable/malformed URL still saves successfully with raw URL only (FR-SAVE behavior); unsupported file type is rejected with a clear reason before upload begins, not after.

### 3.7 Collection Assignment

| Aspect | Detail |
|---|---|
| As drawn in your flow | Presented as a required step between capture and save |
| Per PRD (FR-SAVE-6, FR-SAVE-9) | This must be **optional**, not a gate before saving — see Alignment Note #2, this is the most important conflict to resolve before build |
| Options when used | Select an existing collection, or create a new one inline without leaving the save flow |
| If skipped | Item saves with `collection_id = null` (PRD's "Unsorted"/"All Items" bucket, FR-COL-8) |

### 3.8 Tags (Optional)

| Aspect | Detail |
|---|---|
| Behavior | Multi-select from existing tags (autocomplete, FR-TAG-6) or create new ones inline |
| If skipped | Item saves with zero tags; tags can be added later from Item Details |

### 3.9 Reminder (Optional)

| Aspect | Detail |
|---|---|
| Behavior | Pick a date/time |
| Validation | Past date/time should be rejected or corrected per PRD Open Question #3 — needs a decision before this step can be fully specified |
| If skipped | No reminder created; can be added later from Item Details |

### 3.10 Save

| Aspect | Detail |
|---|---|
| System action | Write to local cache (instant) → queue Supabase mutation (TRD §6) |
| Target latency | ≤2 seconds for link/note, ≤5 seconds for file/image (PRD §4) |
| Confirmation | Non-blocking toast/snackbar; user is not forced to wait on a screen (FR-SAVE-10) |
| Offline behavior | Save succeeds locally regardless of connectivity; queued for sync once online (FR-SAVE-11) |

### 3.11 Content Appears Across the App

| Surface | Condition for appearing |
|---|---|
| Home (Recent) | Always, immediately after save |
| Collection | Only if a collection was assigned in step 3.7 |
| Search index | Always — searchable immediately, including offline (FR-SRCH-7) |
| Favorites | Only after the user explicitly favorites the item — it does **not** appear here automatically on save (clarifying the flow's wording) |

### 3.12 Post-Save Actions

| Action | Behavior |
|---|---|
| Search | Instant, incremental, filterable (PRD §8.7) |
| Edit | Opens Item Details; any field editable (title, description, collection, tags, reminder — FR-ITEM-2) |
| Favorite | Single toggle, syncs across devices (FR-FAV-1/3) |
| Delete | Moves to Trash, not permanent (FR-TRASH-1) |
| Restore | From Trash back to original or new collection (FR-TRASH-4) |

### 3.13 Real-Time Sync

| Aspect | Detail |
|---|---|
| Mechanism | Supabase Realtime channel push to all signed-in devices (TRD §5.6) |
| Target latency | ≤5 seconds (PRD §4, FR-SYNC-2) |
| Conflict case | If the same item was edited offline on two devices, last-write-wins applies on reconnect (FR-SYNC-3 / TRD §6.4) |

---

## 4. Branch Flows Not Shown in the Original Diagram

These are real paths through the app that the linear flow doesn't capture, but which the PRD/TRD already commit to supporting. Listing them here so they're not missed during build planning.

### 4.1 Android Share-Intent Save (bypasses Quick Add screen)
```
User is in another app (browser, YouTube, Instagram, etc.)
  → taps native Share
  → selects Drop Vault
  → Link/content auto-captured, type auto-detected
  → (same optional Collection/Tags/Reminder/Save steps as 3.7–3.10)
```
This is the path most likely to actually hit the "≤2 seconds" save target, since it skips the in-app navigation entirely (FR-SAVE-2).

### 4.2 Offline Save → Delayed Sync
```
User saves while offline (any type)
  → Item appears locally immediately, full functionality
  → Sync status shows "pending"
  → Connectivity restored
  → Queued mutation sent → Realtime confirms → status updates to "synced"
```

### 4.3 Search → No Results
```
User searches
  → No matches against title/body/tags/collection/metadata
  → "No results" state shown with a suggestion to adjust filters/spelling (FR-SRCH-8)
```

### 4.4 Reminder Fires
```
Trigger time reached
  → Notification fires on eligible device(s)
  → User taps notification → Item Details opens directly
  → User marks done or snoozes
  → Status syncs to suppress duplicate firing on other devices (FR-REM-8)
```

### 4.5 Trash Retention Expiry
```
Item sits in Trash for 30 days untouched
  → pg_cron job purges it permanently (TRD §5.7)
  → No further user action possible — this happens automatically
```

### 4.6 Collection Deletion With Items Inside
```
User deletes a Collection that still contains items
  → Prompt: move items to Unsorted, or send items to Trash with the collection
  → User choice required before deletion completes (FR-COL-4)
```

---

## 5. Decision Points Summary

| Decision Point | Options | Governing Requirement |
|---|---|---|
| First launch? | Show onboarding vs. skip | §3.2 |
| Session valid? | Home vs. Login | §3.1 |
| Save entry point | In-app "+" vs. OS share intent | §3.5 vs §4.1 |
| Collection at save time | Assign now vs. skip (must default to skip-friendly) | §3.7, Alignment Note #2 |
| Connectivity at save time | Online (immediate sync) vs. offline (queued) | §3.10, §4.2 |
| Collection deletion with contents | Move to Unsorted vs. Trash with collection | §4.6 |

---

## 6. Alignment Notes (Flagged for Resolution)

1. **"Splash Screen 1/2/3" is almost certainly the onboarding carousel, not three sequential loading screens.** The PRD describes a single technical Splash Screen (session check) plus a separately-mentioned "premium onboarding experience." I've modeled it as: one technical splash → conditionally, a 3-screen onboarding carousel on first launch only. If you actually intended three *sequential loading/splash* screens shown on every launch (not just first launch), that would directly conflict with the <2-second startup target in both the PRD and TRD — worth confirming which one you meant.

2. **The flow as drawn makes Collection assignment a required step before Save — this contradicts FR-SAVE-6 and FR-SAVE-9 in the PRD**, which explicitly require that saving works with zero mandatory fields so a link/note can be captured in ≤2 seconds. If Collection selection is genuinely meant to be mandatory now, that's a legitimate product decision to make — but it should be a deliberate change to the PRD's quick-save goal, not an inconsistency sitting between two documents. I've specified it as optional in §3.7 to match the PRD; flag if you actually want it required.

3. **The diagram only shows the in-app "+" entry point.** The PRD commits to a second entry point — OS-level share intent on Android (FR-SAVE-2) — which is arguably the more important one for hitting the speed target, since it avoids opening/navigating the app at all. I've added it as §4.1; it should be treated as a first-class path, not an edge case.

4. **"Content Appears: Home, Collection, Search, Favorites" reads as if all four happen automatically on save.** Favorites only applies once the user explicitly favorites the item, and Collection only applies if one was assigned. Clarified in §3.11.

5. **No failure/offline paths were in the original diagram.** Added §4.2–§4.6 since these are required behaviors per the PRD (offline save, no-results state, reminder firing/suppression, trash auto-purge, collection-deletion-with-contents prompt) and are exactly the kind of paths that get missed if only the happy path is documented.

---

## 7. Open Questions

1. Confirm intent behind "Splash Screen 1/2/3" — first-launch onboarding carousel (as modeled here), or something else.
2. Confirm whether Collection assignment should remain optional at save time (per PRD) or become a required step (per the literal flow you provided) — these can't both be true.
3. Does onboarding need to be account-tied (shown once per account, synced) or device-tied (shown once per device, default assumption used here)?

---

*End of Document*