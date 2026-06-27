# Drop Vault Supabase Setup & Architecture Documentation

This document describes the offline-first Supabase integration and repository architecture implemented in Phase 2.1.

---

## 1. Installed Packages

The following stable packages have been added to `pubspec.yaml` to enable environment variable management, Supabase integration, and Google Sign-In:

*   **`supabase_flutter`**: Official Flutter client for Supabase services (auth, database, storage, realtime).
*   **`flutter_dotenv`**: Utility to load variables from a `.env` file at runtime.
*   **`google_sign_in`**: Provides Google authentication services.
*   **`uuid`**: Standard uuid generator for primary key generation.

---

## 2. Environment Setup

All sensitive secrets are externalized from the code. Create a `.env` file in the root directory of the project (this is automatically ignored by Git):

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key

# Google OAuth Configuration
GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
```

An example file, `.env.example`, is committed to the repository as a template.

---

## 3. Folder Structure

The project conforms to a modular feature-first directory layout:

```
lib/
├── core/
│   ├── services/
│   │   └── supabase_service.dart      # Centralized client singleton
│   ├── providers/
│   │   ├── providers.dart             # Core providers and repository registries
│   │   └── ...
│   └── ...
└── features/
    ├── auth/
    │   ├── domain/auth_repository.dart
    │   └── data/mock_auth_service.dart
    ├── vault/
    │   ├── domain/collection_repository.dart
    │   ├── domain/item_repository.dart
    │   └── data/
    │       ├── local_collection_repository.dart
    │       ├── supabase_collection_repository.dart
    │       ├── local_item_repository.dart
    │       └── supabase_item_repository.dart
    ├── reminder/
    │   ├── domain/reminder_repository.dart
    │   └── data/
    │       ├── local_reminder_repository.dart
    │       └── supabase_reminder_repository.dart
    ├── settings/
    │   ├── domain/settings_repository.dart
    │   └── data/
    │       ├── local_settings_repository.dart
    │       └── supabase_settings_repository.dart
    └── profile/
        ├── domain/profile_repository.dart
        └── data/
            ├── local_profile_repository.dart
            └── supabase_profile_repository.dart
```

---

## 4. Initialization Flow

Upon launching the application, the following startup sequence is executed in `main.dart`:

1.  **Flutter Binding Initialization**: `WidgetsFlutterBinding.ensureInitialized()` is executed.
2.  **Load Environment Variables**: `.env` is loaded via `dotenv.load()`. If the file is missing, the failure is caught gracefully.
3.  **Initialize Supabase Service**: `SupabaseService.instance.initialize()` reads variables from `.env` and initializes the Supabase client.
    *   **Graceful Fallback**: If the anon key is invalid, the URL is malformed, or the device is offline during startup, the initialization exception is caught. The app proceeds to launch.
4.  **Local Storage Initialization**: SharedPreferences local storage is loaded.
5.  **Launch App**: The application renders the root widget tree, defaulting to offline-first local mode.

---

## 5. Repository Architecture

We introduce a formal Repository Layer between our state management notifiers (Riverpod) and data sources (local storage/cloud database):

*   **Abstract Contracts**: Defined in `domain/` directories (e.g. `ItemRepository`).
*   **Dual Implementations**:
    *   `Local...Repository`: Interacts with `SharedPreferences` to manage local JSON databases scoped by the active user's email.
    *   `Supabase...Repository`: Stub implementations representing database operations for Phase 2.2.
*   **Provider Switcher**: A StateProvider, `useCloudProvider`, acts as a feature flag. If `useCloudProvider` is `false` (default), all repository providers return their `Local` implementations. When changed to `true`, providers automatically switch to `Supabase` implementations.

---

## 6. Security Notes

*   **No Hardcoded Secrets**: URLs, client IDs, and keys are strictly stored in `.env`.
*   **Git Ignore Enforcement**: `.env`, `.env.*`, keys (`*.jks`, `*.keystore`), and credential property files are listed in `.gitignore` to prevent leaks.
*   **Encryption & Hashing**: Password hashing on signup/signin uses SHA-256 locally. Database scoping is partitioned by email prefix identifiers to isolate multi-tenant user storage.

---

## 7. Database Migration SQL (Phase 2.2)

To support automatic profile creation and security rules in Supabase, execute the following SQL script in your Supabase SQL Editor:

```sql
-- 1. Create a public profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  email text not null,
  join_date timestamp with time zone default timezone('utc'::text, now()) not null,
  avatar_url text,
  settings jsonb default '{"notificationsEnabled": true, "remindersEnabled": false, "autoSyncEnabled": true}'::jsonb not null
);

-- 2. Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- 3. Define RLS Policies
create policy "Public profiles are viewable by everyone." on public.profiles
  for select using (true);

create policy "Users can insert their own profile." on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users can update their own profile." on public.profiles
  for update using (auth.uid() = id);

-- 4. Create trigger to automatically insert a profile record when a user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'display_name', 'User'),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```
