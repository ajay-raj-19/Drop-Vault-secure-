import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'core/services/window_settings_manager.dart';
import 'core/services/system_tray_manager.dart';
import 'core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/services/telemetry_service.dart';
import 'core/providers/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/reminder_notification_overlay.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/domain/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLinks(); // Capture protocol launches before initialization awaits.

  // Load environment variables
  bool envLoaded = false;
  String? initErrorMsg;
  try {
    await dotenv.load(fileName: '.env');
    envLoaded = true;
  } catch (e) {
    initErrorMsg = 'Error loading .env file: $e';
    debugPrint(initErrorMsg);
  }

  // Initialize Supabase Service
  bool initSuccess = false;
  try {
    if (envLoaded) {
      await SupabaseService.instance.initialize();
      initSuccess = true;
    } else {
      throw Exception('Environment variables not loaded.');
    }
  } catch (e) {
    initSuccess = false;
    initErrorMsg = e.toString();
    debugPrint('Supabase initialization error caught: $e');
  }

  // Extract Project Reference
  final String rawUrl = envLoaded ? (dotenv.env['SUPABASE_URL'] ?? 'Not Found') : 'Not Found';
  final uri = Uri.tryParse(rawUrl);
  final String projId = uri != null && uri.host.endsWith('.supabase.co')
      ? uri.host.split('.').first
      : 'Unknown';
  final String currentPlatform = kIsWeb ? 'Web' : Platform.operatingSystem;
  final String activeAuth = !initSuccess
      ? 'None'
      : (kReleaseMode ? 'SupabaseAuthRepository' : 'SupabaseAuthRepository / MockAuthService (Fallback)');

  // Verify critical environment variables
  final googleClientId = envLoaded ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null;
  if (googleClientId == null || googleClientId.isEmpty) {
    debugPrint('⚠️ CRITICAL: GOOGLE_WEB_CLIENT_ID is null or empty! Google Sign-In will fail.');
  }

  // Print startup diagnostics
  debugPrint('=== STARTUP DIAGNOSTICS ===');
  debugPrint('Environment Loaded: $envLoaded');
  debugPrint('GOOGLE_WEB_CLIENT_ID: $googleClientId');
  debugPrint('SUPABASE_URL: $rawUrl');
  debugPrint('Supabase URL: $rawUrl');
  debugPrint('Project ID: $projId');
  debugPrint('Supabase Client Initialized: $initSuccess');
  debugPrint('Active Authentication Service: $activeAuth');
  debugPrint('Active Repository: ${initSuccess ? "Supabase" : "Local (Offline Mode)"}');
  debugPrint('Current Platform: $currentPlatform');
  debugPrint('===========================');

  // Hardening: If in release mode and initialization failed, block execution with error screen
  if (kReleaseMode && !initSuccess) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to initialize the secure cloud backend.\nError: $initErrorMsg',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please contact support or verify that the .env configuration file is present and correct.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Windows Desktop setup
  if (!kIsWeb && Platform.isWindows) {
    try {
      await WindowSettingsManager.instance.initialize();
      await SystemTrayManager.instance.initialize();
      await _registerWindowsProtocol();
      
      launchAtStartup.setup(
        appName: 'Drop Vault',
        appPath: Platform.resolvedExecutable,
      );
    } catch (e) {
      debugPrint('Windows initialization error: $e');
    }
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  await TelemetryService.instance.initialize(sharedPreferences);
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const DropVaultApp(),
    ),
  );
}

Future<void> _registerWindowsProtocol() async {
  if (kIsWeb || !Platform.isWindows) return;
  try {
    final execPath = Platform.resolvedExecutable;
    await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\dropvault',
      '/t',
      'REG_SZ',
      '/d',
      'URL:Drop Vault Protocol',
      '/f',
    ]);
    await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\dropvault',
      '/v',
      'URL Protocol',
      '/t',
      'REG_SZ',
      '/d',
      '',
      '/f',
    ]);
    await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\dropvault\\shell\\open\\command',
      '/t',
      'REG_SZ',
      '/d',
      '"$execPath" "%1"',
      '/f',
    ]);
    debugPrint('[Windows Protocol] Registered dropvault scheme successfully.');
  } catch (e) {
    debugPrint('[Windows Protocol] Failed to register dropvault scheme: $e');
  }
}

class DropVaultApp extends ConsumerStatefulWidget {
  const DropVaultApp({super.key});

  @override
  ConsumerState<DropVaultApp> createState() => _DropVaultAppState();
}

class _DropVaultAppState extends ConsumerState<DropVaultApp> with WidgetsBindingObserver {
  StreamSubscription<Uri>? _linkSubscription;
  final Set<String> _handledAuthLinks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize SyncService provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final syncService = ref.read(syncServiceProvider);
        final authState = ref.read(authStateProvider);
        syncService.setUser(authState.user?.email);
      }
    });

    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen(_handleIncomingDeepLink,
        onError: (Object error) => debugPrint('[DeepLink] Unable to read app link.'));
    try {
      final uri = await appLinks.getInitialLink();
      if (mounted && uri != null) await _handleIncomingDeepLink(uri);
    } catch (_) {
      debugPrint('[DeepLink] Unable to read initial app link.');
    }
  }

  Future<void> _handleIncomingDeepLink(Uri uri) async {
    if (!mounted || uri.scheme != 'dropvault' ||
        !{'reset-password', 'google-callback', 'login-callback'}.contains(uri.host)) {
      return;
    }
    if (!_handledAuthLinks.add(uri.toString())) return;
    // Keep callback credentials out of logs and process each code only once.
    try {
      final fragment = Uri.splitQueryString(uri.fragment);
      if (uri.queryParameters.containsKey('error') || fragment.containsKey('error')) {
        throw const AuthException('Authentication was cancelled or the link expired. Please try again.');
      }
      final code = uri.queryParameters['code'];
      if (code != null) {
        await ref.read(authStateProvider.notifier).exchangeCodeForSession(code);
      } else if (fragment.containsKey('access_token')) {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } else {
        return;
      }
      if (!mounted) return;
      if (uri.host == 'reset-password' || fragment['type'] == 'recovery') {
        ref.read(routerProvider).go('/reset-password');
      }
    } catch (_) {
      if (!mounted) return;
      final context = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text('Could not complete sign-in. The link may have expired. Please try again.'),
        ));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatic refresh on app resume has been disabled.
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state transitions (login / logout)
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      final oldEmail = previous?.user?.email;
      final newEmail = next.user?.email;
      if (oldEmail != newEmail) {
        ref.read(syncServiceProvider).setUser(newEmail);
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Drop Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return ReminderNotificationOverlay(child: child!);
      },
    );
  }
}

