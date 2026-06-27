# Drop Vault – Windows Desktop Port

This document details the specifications, design decisions, and architectural implementation of the Windows Desktop port of Drop Vault, converting the Android-first Flutter app into a native-feeling Windows application while maintaining a single shared codebase.

---

## 1. Specifications & Layout Adaptation

- **Minimum Resolutions Supported**: 1280×720, 1366×768, 1600×900, 1920×1080.
- **Main Layout Shell**:
  - On Windows desktop, the bottom navigation bar is completely hidden.
  - A permanent visual left sidebar navigation (`DesktopSidebar`) is rendered, keeping navigation quick and accessible.
  - Layout automatically transitions to grid layouts on wider viewports to avoid stretched list rows.

---

## 2. Window Settings & State Persistence

- **File**: `lib/core/services/window_settings_manager.dart`
- **Behavior**:
  - Intercepts window resize, move, maximize, and restore events.
  - Automatically persists the size and position coordinates to local storage (`SharedPreferences`) on a debounced timer.
  - If the "Remember Window Size & Position" preference is toggled off in settings, defaults are loaded and position changes are not written to disk.

---

## 3. Desktop Settings Group

- **File**: `lib/features/settings/presentation/settings_screen.dart`
- **Features**:
  - **Launch on Startup**: Toggles startup behavior using the native Windows registry (`launch_at_startup`).
  - **Default Download Folder**: Uses native Directory Picker (`file_picker`) to select a custom file download directory.
  - **Open Links in Default Browser**: Toggles whether external URLs open in default web browser using `url_launcher` LaunchMode configuration.
  - **Remember Window Size & Position**: Toggles whether window coordinates are saved locally.

---

## 4. System Tray & Background Synchronization

- **File**: `lib/core/services/system_tray_manager.dart`
- **Behavior**:
  - Skeletal manager that registers as a `WindowListener` to the `window_manager` framework.
  - Prepares architecture for minimizing to tray on close, custom tray menu items, and background vault sync tasks.

---

## 5. Keyboard Navigation & Shortcuts

- **Global Hotkeys**:
  - `Ctrl + N`: Go to Add Item screen.
  - `Ctrl + F`: Go to Search screen.
  - `Ctrl + Shift + E`: Go to Backup & Restore screen (from global pages) or trigger format-specific collection exports (JSON, CSV, PDF) on collection pages.
  - `Ctrl + R`: Clear search queries and refresh vault and category providers with visual feedback.
  - `Ctrl + Z`: Undo the last item/reminders trashing action and restore all states.
- **Local Hotkeys**:
  - `Ctrl + S`: Save note details in `AddItemScreen` and `ResizableDialog` editing screens.
- **List Keyboard Navigation**:
  - `Arrow Up / Down`: Sequentially select/focus items inside collections. Focus is highlighted with a premium primary outline border.
  - `Enter`: Open the selected/focused item directly.
  - `Delete`: Move the focused item to the trash bin (opens confirmation).

---

## 6. Shell & File Explorer Integrations

- **Context Menu Actions**:
  - Right-clicking items on desktop opens a custom context menu at the cursor coordinates.
  - **Reveal in Explorer**: Opens Windows Explorer with the specific downloaded/local file selected.
  - **Open Containing Folder**: Opens the directory where the file resides.
  - **Save Copy As...**: Opens a native Save File dialog letting users extract/save a copy of the vault file.

---

## 7. Custom Resizable Dialogs

- **File**: `lib/core/widgets/resizable_dialog.dart`
- **Behavior**:
  - Serves as the base dialog for Windows Note Editing and configurations.
  - Renders a dragging corner anchor in the bottom-right corner, letting users resize the dialog boundaries freely between predefined minimum/maximum size parameters.
