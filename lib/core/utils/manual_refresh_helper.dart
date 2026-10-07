import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/connection_helper.dart';

/// Triggers manual sync with visual feedback (SnackBar loading & status updates).
Future<void> performManualRefresh(BuildContext context, WidgetRef ref) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.clearSnackBars();

  // 1. Show "Refreshing..." with a loading indicator
  scaffoldMessenger.showSnackBar(
    const SnackBar(
      duration: Duration(days: 365), // Keep open during sync
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Refreshing...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      backgroundColor: Color(0xFF212121),
    ),
  );

  try {
    // Perform manual sync
    await ref.read(syncServiceProvider).syncNow();

    ref.read(isOfflineProvider.notifier).state = false;

    if (!context.mounted) return;
    scaffoldMessenger.clearSnackBars();

    // 2. Show "Refresh Complete" on success
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text(
              'Refresh Complete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Color(0xFF212121),
      ),
    );
  } catch (e) {
    // Check internet connection to update state
    bool isOffline = false;
    try {
      isOffline = !await checkInternetConnection();
    } catch (_) {
      isOffline = true;
    }
    ref.read(isOfflineProvider.notifier).state = isOffline;

    if (!context.mounted) return;
    scaffoldMessenger.clearSnackBars();

    // 3. Show non-blocking error message on failure
    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Refresh failed: ${e.toString().replaceAll('Exception: ', '')}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[900],
      ),
    );
  }
}
