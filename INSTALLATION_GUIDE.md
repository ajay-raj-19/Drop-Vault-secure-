# Drop Vault – Installation Guide

This document describes how to compile, configure, and install Drop Vault on Android and Windows platforms.

---

## 1. Development Prerequisites

To compile the application from source code, ensure you have:
- **Flutter SDK**: `^3.0.0` (Dart SDK `>=3.0.0 <4.0.0`).
- **Android SDK**: Build tools and command-line tools installed (required for Android compilation).
- **Visual Studio**: "Desktop development with C++" workload installed (required for Windows compilation).
- **Supabase Account** (Optional): A project set up with the schema defined in [DATABASE_SCHEMA.md](file:///c:/VS%20Code/Drop%20Vault/DATABASE_SCHEMA.md).

---

## 2. Configuration (`.env`)

Duplicate the `.env.example` file and rename it to `.env` in the project root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```
*Note: If these fields are omitted or left blank, the app defaults to secure Local-First Standalone offline execution.*

---

## 3. Platform Compilation

### Android (APK & App Bundle)
To build a debug package:
```bash
flutter build apk --debug
```
To build a universal release APK:
```bash
flutter build apk --release
```
To build a Google Play App Bundle (AAB):
```bash
flutter build appbundle --release
```
*Outputs are generated in `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/release/`.*

### Windows Desktop (EXE)
To compile the release executable:
```bash
flutter build windows --release
```
*Outputs are generated in `build/windows/runner/Release/`.*

---

## 4. End-User Installation

### Android APK
1. Enable **Install from Unknown Sources** in your Android device Settings.
2. Transfer the `app-release.apk` to your phone.
3. Open the APK via your file manager and tap **Install**.

### Windows Portable
1. Navigate to the compilation output folder `build/windows/runner/Release/`.
2. Extract or copy the entire folder containing `drop_vault.exe` and its adjacent DLLs to your target system directory.
3. Run `drop_vault.exe` to launch the application.
