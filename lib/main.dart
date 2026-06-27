import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'core/services/window_settings_manager.dart';
import 'core/services/system_tray_manager.dart';
import 'core/services/supabase_service.dart';
import 'core/services/telemetry_service.dart';
import 'core/providers/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/reminder_notification_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Initialize Supabase Service
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error caught: $e');
  }

  // Windows Desktop setup
  if (!kIsWeb && Platform.isWindows) {
    try {
      await WindowSettingsManager.instance.initialize();
      await SystemTrayManager.instance.initialize();
      
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

class DropVaultApp extends ConsumerWidget {
  const DropVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
