# Drop Vault 🚀

Drop Vault is a secure, local-first, premium digital sanctuary built with Flutter. It is designed to save and organize links, notes, files, and images locally using a high-fidelity glassmorphism user interface.

---

## 🌟 Key Features

- **Multi-Category Vault**: Save, view, and organize Links, Notes, Files, and Images.
- **Dynamic Collections**: Create custom collections to isolate and group related credentials or research.
- **Reminders System**: Schedule native notifications for important vault items.
- **Secure Sandbox Storage**: Local-first sandboxed file storage isolated by user email.
- **Backup & Restore**: Export account data to JSON, CSV, or PDF, and restore from JSON backups.
- **Desktop Optimization**: Windows features including permanent left sidebar, resizable note editor, hotkeys, context menus, and window coordinate memory.
- **Privacy-First Telemetry**: Opt-in diagnostic tracking.

---

## 📁 Repository Structure

```
drop_vault/
├── android/                   # Android native code, permissions, and icons
├── assets/                    # Static image, logo, and onboarding assets
│   ├── images/                # Downscaled WebP splash and developer assets
│   └── logo/                  # High-resolution transparent logo
├── lib/                       # Flutter Application source code
│   ├── core/                  # Shared providers, models, widgets, and services
│   │   ├── constants/         # Color tokens, styles, and versioning info
│   │   ├── providers/         # Riverpod global state models and notifiers
│   │   ├── services/          # Storage, Supabase, and Window managers
│   │   └── widgets/           # Global visual elements (glass cards, sidebars)
│   └── features/              # Feature-driven functional modules
│       ├── auth/              # Standalone and Supabase login modules
│       ├── backup/            # Data serialization and file export engine
│       ├── dashboard/         # Stat boards and recent files display
│       ├── reminder/          # Clock settings and local notification logic
│       ├── settings/          # Desktop preferences and layouts
│       └── vault/             # Note, Link, File explorer and Collections screens
├── web/                       # Web PWA config and icons
├── windows/                   # Windows Desktop project files and metadata
├── pubspec.yaml               # Dart package configuration
└── README.md                  # Project overview
```

---

## 🛠️ Getting Started & Setup

### Prerequisites
- **Flutter SDK**: `^3.0.0`
- **Dart SDK**: `>=3.0.0 <4.0.0`

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/drop_vault.git
   cd drop_vault
   ```

2. **Configure Environment Variables**:
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anonymous-key
   ```
   *Note: Leaving this blank activates standalone offline mode.*

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   - Run on any connected emulator or desktop target:
     ```bash
     flutter run
     ```
   - For Android debug builds bypassing dependency checks:
     ```bash
     flutter run --debug --android-skip-build-dependency-validation
     ```

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action | Scope |
|---|---|---|
| `Ctrl + N` | Navigate to Add Item screen | Global |
| `Ctrl + F` | Navigate to Search screen | Global |
| `Ctrl + Shift + E` | Backup & Restore page / Export Collection | Global / Contextual |
| `Ctrl + R` | Refresh vault data & clear search | Global |
| `Ctrl + Z` | Undo last delete/trash sequence | Global |
| `Ctrl + S` | Save changes | Note Editor / Dialogs |
| `Arrow Up / Down` | Select item in lists | Collection List |
| `Enter` | Open selected item | Collection List |
| `Delete` | Trash selected item | Collection List |

---

## 📄 License & Attribution

This project is licensed under the MIT License - see [LICENSE.md](file:///c:/VS%20Code/Drop%20Vault/LICENSE.md) for details.
All third-party assets are attributed within [FINAL_AUDIT.md](file:///c:/VS%20Code/Drop%20Vault/FINAL_AUDIT.md).
