# Project Structure

The codebase is organized into standard Flutter folders, following a modular feature-first architecture.

```
lib/
├── core/
│   ├── constants/             # Global tokens, assets (app_assets.dart, design_tokens.dart)
│   ├── models/                # Separated models (VaultItem, Collection, Reminder, UserSettings)
│   ├── providers/             # Riverpod providers barrel and split files
│   ├── routing/               # GoRouter configuration (app_router.dart)
│   ├── theme/                 # Styling, theme declarations, and color definitions
│   └── widgets/               # Standardized reusable widgets (GlassCard, GlassAppBar, UserAvatar)
│
└── features/
    ├── auth/                  # Authentication pages, repository, and providers
    ├── backup/                # Local data exports (JSON, CSV, PDF) and import restore routine
    ├── dashboard/             # Main Home screen showing status, stats, and quick actions
    ├── help/                  # Help and support screen with dynamic email intent launcher
    ├── onboarding/            # Introduction walkthrough cards and splash screens
    ├── profile/               # Account, password edit, developer bio, and profile settings
    ├── reminder/              # Notification reminders management list
    ├── search/                # Search bar, recent queries, and search result list
    ├── settings/              # Settings switches (notifications, theme mode, privacy policy, terms)
    ├── trash/                 # Soft-delete items list for retrieval or permanent deletion
    └── vault/                 # Add Item, Collection Details, Note Viewer, and category lists
```

## Key Files
- `lib/main.dart`: Root entrypoint, wraps the app with `ProviderScope` and overrides `sharedPreferencesProvider`.
- `lib/core/routing/app_router.dart`: State-aware router that handles authentication flow and nested navigation shells.
- `lib/core/providers/providers.dart`: Barrel file exporting all core providers and models.
- `lib/features/backup/data/backup_service.dart`: High-level data export and restore parser.
