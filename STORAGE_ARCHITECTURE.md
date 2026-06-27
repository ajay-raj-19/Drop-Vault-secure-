# Supabase Storage Architecture & File Management

This document defines the storage structures, Row Level Security (RLS) policies, local caching mechanisms, and offline synchronization queue designed for Drop Vault.

---

## 1. Storage Bucket Structure

Drop Vault utilizes three distinct storage buckets in Supabase:

*   **`profile-images`**: Publicly readable. Stores user avatar images.
*   **`vault-images`**: Private. Stores images uploaded as vault items.
*   **`vault-files`**: Private. Stores files (PDF, DOCX, etc.) uploaded as vault items.

Files within all buckets are partitioned under a folder named after the user's UUID (`auth.uid()`) to ensure complete multi-tenant isolation:

```
[bucket-name]/
  └── [user-uuid]/
        ├── avatar.png
        ├── document.pdf
        └── image.jpg
```

---

## 2. Supabase Storage SQL Migration (DDL & RLS)

Execute the following SQL commands in your Supabase SQL Editor to initialize the buckets and configure storage RLS rules:

```sql
-- 1. Create Buckets
insert into storage.buckets (id, name, public)
values 
  ('profile-images', 'profile-images', true),
  ('vault-images', 'vault-images', false),
  ('vault-files', 'vault-files', false)
on conflict (id) do nothing;

-- Enable Row Level Security on storage.objects
alter table storage.objects enable row level security;

-- 2. RLS Policies for profile-images (Public select, owner write/delete)
create policy "Allow public read access to profile images"
  on storage.objects for select
  using (bucket_id = 'profile-images');

create policy "Allow owner to insert profile images"
  on storage.objects for insert
  with check (bucket_id = 'profile-images' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Allow owner to update profile images"
  on storage.objects for update
  using (bucket_id = 'profile-images' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Allow owner to delete profile images"
  on storage.objects for delete
  using (bucket_id = 'profile-images' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3. RLS Policies for vault-images (Owner only)
create policy "Allow owner all access to vault-images"
  on storage.objects for all
  using (bucket_id = 'vault-images' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'vault-images' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4. RLS Policies for vault-files (Owner only)
create policy "Allow owner all access to vault-files"
  on storage.objects for all
  using (bucket_id = 'vault-files' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'vault-files' and auth.role() = 'authenticated' and (storage.foldername(name))[1] = auth.uid()::text);
```

---

## 3. Upload & Download Flows with Progress Monitoring

### Upload Flow (Chunked PUT stream)
To enable accurate progress updates during file uploads without third-party libraries, the repository performs a chunked HTTP PUT request targeting the Supabase Storage REST endpoint:
1. Construct URL: `https://[project-id].supabase.co/storage/v1/object/[bucket]/[user-uuid]/[filename]`
2. Add Headers:
    *   `Authorization: Bearer [user-session-jwt]`
    *   `apikey: [supabase-anon-key]`
    *   `Content-Type: [mime-type]`
3. Write to the `HttpClientRequest` stream chunk-by-chunk, updating the `transferProvider` progress ratio.

### Download Flow (Chunked GET stream)
Downloads retrieve the binary payload directly from Supabase Storage and stream it to a temporary local cache:
1. Construct URL or retrieve from the storage object.
2. Read bytes using a chunked `HttpClient` stream, reporting download progress back to the UI.
3. Save the result file to the local cache directory.

---

## 4. Cache Strategy (LRU Eviction)

To preserve device storage, cached files and preview thumbnails are stored in the application's temporary directory (`getTemporaryDirectory()` under `drop_vault_cache/`).
*   **Limit**: 50 MB.
*   **Trigger**: Checked every time a new file is cached.
*   **Eviction Policy**: If the cache size exceeds 50 MB, the cache manager sorts files by their last accessed time (oldest first) and deletes them until the total cache size falls below 30 MB.

---

## 5. Offline Queue Synchronization

When the device is offline:
1. Upload operations are registered in a local SharedPreferences JSON queue (`pending_uploads`).
2. The item metadata is saved to local storage with a reference to the local path.
3. When the network becomes available (or on repository CRUD operations), the sync process is triggered:
    *   Iterate through `pending_uploads`.
    *   Upload binaries to Supabase Storage.
    *   Update item URLs in local and Supabase tables.
    *   Remove completed transfers from the queue.
