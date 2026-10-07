# Login repair and additional checks — 6 October 2026

## Implemented

- Android: added INTERNET permission to the main manifest so installed release builds can reach authentication and cloud services.
- Android: disabled Flutter default deep-link routing because app_links handles authentication callbacks.
- Windows: forward protocol launches to the existing Drop Vault window using app_links instead of opening an independent login session.
- Deep links: one callback owner, duplicate suppression, accepted callback validation, visible callback failure feedback, and no token/code logging.
- Session state: initialize the notifier from the existing repository state, publish authenticated state before optional profile work, and reject late profile results after logout or another session change.
- Login: remove the unauthenticated profiles-table account-existence check and use a single Google sign-in flow. Preserve passwords exactly as entered.
- Signup: require a real session before authenticating, show email confirmation instructions when necessary, validate the repeated password, and guard duplicate requests.
- Password recovery: preserve password whitespace and avoid updating a disposed screen after completion.
- Lifecycle: dispose repository/router listeners and move sync-service cleanup to its provider.
- Startup: avoid reading an unloaded environment configuration during diagnostics.
- Login footer: wrap its links when horizontal space is insufficient.
- Android build: disable Kotlin incremental compilation after the build exposed cross-drive C:/D: cache path failures. This may make Kotlin compilation slower.

## Validation performed

- Live read-only authentication settings request returned HTTP 200; email and Google providers are enabled. Email confirmation is currently disabled on this backend.
- After the user authorized the retest, flutter test --no-pub passed all 9 tests: six authentication regression tests, two login-screen tests, and the existing app smoke test.
- flutter analyze --no-pub reported no issues on the latest changes.
- Both login-screen tests pass after the footer overflow fix, covering exact password preservation and Google sign-in without an account-existence lookup.
- Windows build could not start: suitable Visual Studio C++ toolchain is missing.
- Android debug build passed after disabling Kotlin incremental compilation. The APK is build/app/outputs/flutter-apk/app-debug.apk (164,674,789 bytes). APK signature verification passed, and the packaged manifest includes INTERNET permission. The build supports arm64-v8a, armeabi-v7a, and x86_64, with minimum Android API 24.
- No real user account was used, created, deleted, or changed. Native Google consent/callback completion and actual password login still require device verification.

## Additional unresolved findings

- Account deletion currently deletes the profile row and local cache, but does not delete the Supabase Auth user. It also swallows errors. Complete deletion needs a properly authenticated server-side operation; do not expose an administrative service key in the app.
- Pending profile-image uploads use a global preference key rather than a per-user queue. Account switching during a failed upload should be reviewed before claiming full multi-account data isolation.
- Android release builds currently use the debug signing configuration. This is not a production signing setup.
- Supabase redirect allow-list entries and Android Google package/signing fingerprints were not accessible in this session. Verify dropvault://google-callback, dropvault://login-callback, and dropvault://reset-password for the deployed project.

## Remaining verification

Build Windows after installing the Windows C++ build prerequisites. Install the verified Android debug APK on a phone. On both platforms check password login, invalid password retry, restored login after restart, Google login and cancellation, and password recovery. Check that logout remains effective when profile loading is slow. Automated tests, analysis, and the Android debug build have passed; Windows build and real-account login remain unverified.

## Reference checked

Supabase signup session behavior: https://supabase.com/docs/reference/dart/auth-signup
Windows callback integration was checked against the installed app_links 6.4.1 example and exported API.

## Data restoration follow-up

The connected phone had no local vault-item or collection keys, while the same signed-in cloud account retained 16 active items and 5 collections. A read-only cloud snapshot and the existing phone/PC preferences were backed up under build/recovery before changes. All three file/image records reference cloud URLs.

The app now performs a read-only cloud restore on login/startup, merges newer remote data without discarding local-only records or newer local edits, respects pending deletion queues, and ignores results after account changes. Manual sync no longer interprets a UUID missing from cloud results as proof of deletion. Explicit remote deletion tracking remains a future requirement for removing stale copies on other devices.

Verification: all 15 tests passed and flutter analyze reported no issues. A rebuilt Android debug APK was installed with adb install -r, preserving app data. After launching the update, the phone preferences contained 16 vault items and 5 collections. Windows release build and installer packaging subsequently succeeded; installation completed, but application launch is blocked by the Windows signing policy as described below.

## Windows installer result

- Installed Visual Studio Build Tools 2022 with C++ tools/Windows SDK and Inno Setup 6 to build this project.
- Preserved the stale C:-drive CMake cache under build/windows/x64-before-rebuild-* and rebuilt from the current D: workspace.
- flutter build windows --release --no-pub succeeded.
- Built build/installer/DropVault_Setup.exe (13,201,671 bytes), bundling x64 C++ runtime DLLs. The reproducible packaging command is installer/build_installer.ps1.
- Installer completed with exit code 0. The app is installed at C:/Users/singh/AppData/Local/Programs/Drop Vault/drop_vault.exe. Desktop and Start Menu shortcuts and the uninstall entry were verified.
- Application launch did NOT succeed. Windows Application Control blocked drop_vault.exe. Code Integrity events 3077 and 3033 at 22:24:36 on 6 October 2026 report failure to meet Enterprise signing requirements, policy ID {0283ac0f-fff1-49ae-ada1-8a933130cad6}. Authenticode status is NotSigned. No app process was running. The shell's earlier 'App running: True' text was caused by a null process variable after Start-Process failed and is not valid evidence of launch.
- No application-control policy, signing trust store, or security setting was changed. Windows runtime testing requires a build signed by a publisher trusted by the active policy or policy-administrator review.

Microsoft reference: https://learn.microsoft.com/windows/apps/develop/smart-app-control/overview

## 7 October 2026 - Windows Google OAuth redirect fix

- Confirmed Supabase URL Configuration had zero allowed redirect URLs. Site URL was the Supabase API root, which returns requested path is invalid.
- Added exact app callbacks in the project dashboard: dropvault://google-callback, dropvault://login-callback, dropvault://reset-password.
- Retested each callback with a fresh OAuth state and simulated provider cancellation (no account credentials or tokens used). All three now redirect to the requested app callback instead of the API root.
- Screenshot: build/redirect-settings-fixed.jpg.
- No application rebuild needed. Successful real Google login and Windows app handoff still require user retest from a fresh login attempt.
