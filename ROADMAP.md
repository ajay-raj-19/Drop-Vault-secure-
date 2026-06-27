# Drop Vault – Project Roadmap

This roadmap details the planned feature enhancements and semantic version releases for Drop Vault.

---

## Current Release: v1.0.0 – Public Launch 🚀
- Premium glassmorphism design with Light/Dark themes.
- Local-first architecture with fallback SharedPreferences database.
- Multi-category vault: Links, Notes, Files, and Images.
- Desktop optimizations (Permanent sidebar, Resizable dialogs, Hotkeys, Context menus).
- Dynamic database backup and restore (JSON/CSV/PDF formats).
- Privacy-first telemetry skeleton interface.

---

## v1.1.0 – Sync & Sharing Enhancements 🔄
- **Full Bidirectional Cloud Sync**: Seamless real-time sync conflict resolution using Supabase db triggers.
- **Mobile Share Extension**: Share links, text, and files directly to Drop Vault from other apps on Android/iOS.
- **Search Filtering Engine**: Advanced searches by tags, date ranges, and categories.

---

## v1.2.0 – Security & Hardening 🔒
- **Local SQLite Integration**: Move local SharedPreferences relational database to SQLite for high-performance offline storage.
- **Biometric Locking**: Support for Windows Hello and Android Fingerprint/Face ID unlocking.
- **Local File Encryption**: AES-256 local storage encryption for all saved files and images.

---

## v2.0.0 – Shared Vaults & Collaboration 👥
- **Shared Workspaces**: Create workspaces and invite members to view/edit collections.
- **Role-Based Access Control (RBAC)**: Define admin, editor, and viewer roles for shared vaults.
- **Activity Log Audit**: Tracks who opened, modified, or exported vault items.
- **Browser Extensions**: Quick-save bookmarks directly from Chrome, Edge, and Firefox.
