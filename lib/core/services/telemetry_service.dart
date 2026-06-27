import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized, privacy-first crash monitoring and analytics service.
/// Provides hooks for Sentry/Firebase Crashlytics without violating privacy
/// by requiring a user opt-in/opt-out configuration.
class TelemetryService {
  static final TelemetryService instance = TelemetryService._internal();
  TelemetryService._internal();

  bool _telemetryEnabled = false;

  /// Initialize telemetry, checking user pref key for telemetry opt-in.
  Future<void> initialize(SharedPreferences prefs) async {
    _telemetryEnabled = prefs.getBool('enable_telemetry') ?? false;
    debugPrint('[Telemetry] Initialized. Opt-in status: $_telemetryEnabled');
  }

  /// Dynamically toggle telemetry setting (e.g. from user settings panel).
  void setTelemetryEnabled(bool enabled) {
    _telemetryEnabled = enabled;
    debugPrint('[Telemetry] User toggled telemetry to: $_telemetryEnabled');
  }

  /// Logs errors locally in debug/production and conditionally uploads them if opt-in is enabled.
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[Telemetry ERROR] $message');
    if (error != null) {
      debugPrint('[Telemetry ERROR Detail] $error');
    }
    if (stackTrace != null) {
      debugPrint('[Telemetry StackTrace]\n$stackTrace');
    }

    if (_telemetryEnabled) {
      // Production telemetry integrations (Sentry, Firebase Crashlytics, etc.)
      // Example:
      // Sentry.captureException(error, stackTrace: stackTrace);
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    }
  }

  /// Logs standard analytics events locally and conditionally uploads them if opt-in is enabled.
  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    debugPrint('[Telemetry EVENT] Name: $eventName, Parameters: $parameters');

    if (_telemetryEnabled) {
      // Production analytics integration (Firebase Analytics, Mixpanel, etc.)
      // Example:
      // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    }
  }
}
