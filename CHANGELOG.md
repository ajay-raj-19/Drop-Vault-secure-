# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-06-27

### Added
- **Windows Desktop Port**: Adapted layouts to larger viewports, permanent left sidebar shell, and custom resizable note editing dialogs.
- **Desktop Shortcuts**: Integrated shortcuts (`Ctrl+N`, `Ctrl+F`, `Ctrl+Shift+E`, `Ctrl+R`, `Ctrl+Z`, `Ctrl+S`) and arrow-key focus list navigation.
- **Explorer Shell Hooks**: Windows context menu options for "Reveal in Explorer", "Open Containing Folder", and "Save Copy As...".
- **System Tray Support**: Minimize-to-tray skeletal manager.
- **Privacy Telemetry**: Opt-in crash monitoring and analytics pipeline (`TelemetryService`).
- **Android Storage Permissions**: Target SDK compatibility adjustments for Android 10-15.

### Changed
- **Branding Assets**: Renamed and generated custom transparent app launcher icons for Android, Windows executable (`app_icon.ico`), and Web via `flutter_launcher_icons`.
- **Centralized Versioning**: Integrated `AppVersionInfo` static settings across the dashboard and help screens.

### Refactored
- **State Management**: Split monolithic provider structure into modular notifier files under `lib/core/providers/` and domain models under `lib/core/models/`.
- **Linter & Warnings Cleanup**: Resolved all warnings and deprecated members (e.g. `withOpacity`, `background`, `onPopInvoked`) to ensure a 100% clean `flutter analyze` build.

### Optimized
- **Assets Downscaling**: Converted developer graphics to WebP, saving 99.5% memory footprint.
- **Dependency Reductions**: Cleared unused dependencies (`vector_math`, `package_info_plus` import) from project configuration.
