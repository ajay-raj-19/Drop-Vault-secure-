# Release Notes – Drop Vault v1.0.0

Welcome to the initial public release of **Drop Vault**, your premium, secure, local-first digital sanctuary designed to store links, notes, images, and files in a beautiful glassmorphic visual environment.

---

## What's New in v1.0.0

### Key Features
- **Local-First Sandboxed Storage**: Saves all files, images, links, and notes in an isolated directory structure keyed to the logged-in email.
- **Dynamic Collections**: Group and manage entries in folders with custom backgrounds and icons.
- **Reminders System**: Schedule native notifications to review vault files at target dates and times.
- **Google Sign-In & Supabase**: Integration with Cloud Auth services and dynamic database backups.
- **Privacy-First Design**: Graceful fallback to offline local-only storage (MockAuthService) if the remote database is unreachable.
- **Backup & Recovery**: Export whole accounts or specific collections to JSON, CSV, or PDF, and restore from local JSON files.

### Windows Desktop Customizations
- **Adaptive Layout**: Permanent left-hand sidebar navigation replacing the bottom navigation bar on desktop viewports.
- **Window Geometry Persistence**: Tracks and restores previous window coordinates and maximize states.
- **System Tray Integration**: Minimize-to-tray architecture.
- **Keyboard Navigation**: Arrows, Enter, Delete, and global shortcuts (Ctrl+N, Ctrl+F, Ctrl+Shift+E, Ctrl+R, Ctrl+Z, Ctrl+S) for rapid navigation.
- **Shell Integrations**: Right-click actions for "Reveal in Explorer," "Open Containing Folder," and "Save Copy As...".
- **Draggable Note Editor**: Draggable resizable note views.

---

## System Requirements

### Android
- Android 10.0 (API level 29) or higher.
- Compatible with legacy (transparent) and modern adaptive launcher formats.

### Windows
- Windows 10 (Build 19041) or Windows 11.
- Minimum Resolution: 1280×720 (Optimal: 1920×1080).
