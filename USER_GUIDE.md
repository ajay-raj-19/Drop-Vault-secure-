# Drop Vault – User Guide

This guide describes how to operate Drop Vault to securely save and organize your digital life.

---

## 1. Getting Started

### Standalone (Offline Mode)
If your application is not connected to a remote server, Drop Vault functions as a local-first sandbox.
- When you register or log in, credentials are encrypted and stored in your device's secure local space.
- All files, notes, and collections remain private and local.

### Account Sync Mode
If connected to Supabase:
- Logging in syncs your collections, metadata, and reminders across multiple devices.
- Files and images are securely cached locally and synced to remote cloud storage.

---

## 2. Managing Collections

Collections act as isolated folders for your credentials or research.
- **Create**: Tap the **Collections** folder in the sidebar or bottom bar, click **+**, and provide a name and color.
- **Organize**: In item context menus, click **Edit** to move entries to a different collection.
- **Context Menus**: Right-click (or long press) any item in a collection to open contextual settings.

---

## 3. Saving & Reviewing Vault Items

- **Links**: Save bookmarks. Tapping a link opens it in your default web browser (configured in settings).
- **Notes**: Write rich text entries. Double-tap to view, or right-click and edit.
- **Images**: Drag and drop or upload images. Tapping an image opens the zoomable, swipe-to-dismiss image viewer.
- **Files**: Upload documents. Tapping a remote file downloads it locally with a visual progress bar and launches it via the default system handler.

---

## 4. Reminders & Trash

- **Setting Reminders**: Tap the clock icon on any item to schedule a notification review reminder.
- **Trash Bin**: Deleting items moves them to the **Trash**. They can be permanently deleted or restored.
- **Undo**: If you delete an item by accident, press `Ctrl + Z` globally on Windows to undo the trashing sequence instantly.

---

## 5. Exporting & Backup

To back up your data:
1. Navigate to **Backup & Restore** (or press `Ctrl + Shift + E`).
2. Choose **JSON** (full backup), **CSV** (spreadsheet list), or **PDF** (formatted document).
3. On Windows, files are saved to your configured downloads folder. On Android, files are exported to `Downloads/DropVault`.
