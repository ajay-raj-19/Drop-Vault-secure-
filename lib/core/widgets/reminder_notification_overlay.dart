import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../features/vault/presentation/collection_items_screen.dart';

class ReminderNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const ReminderNotificationOverlay({super.key, required this.child});

  @override
  ConsumerState<ReminderNotificationOverlay> createState() => _ReminderNotificationOverlayState();
}

class _ReminderNotificationOverlayState extends ConsumerState<ReminderNotificationOverlay> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Reminder? _activeReminder;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<double>(begin: -150.0, end: 20.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // Check reminders periodically
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkReminders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _checkReminders() {
    if (_activeReminder != null) return;

    final reminders = ref.read(reminderProvider);
    final vaultItems = ref.read(vaultProvider);
    final now = DateTime.now();

    for (final r in reminders) {
      if (!r.isCompleted && r.dateTime.isBefore(now)) {
        if (r.itemId != null) {
          final exists = vaultItems.any((item) => item.id == r.itemId);
          if (!exists) continue; // Skip reminders for deleted/trashed items
        }

        setState(() {
          _activeReminder = r;
        });

        // Mark it as completed immediately in the provider so it doesn't trigger again
        ref.read(reminderProvider.notifier).toggleReminder(r.id);

        // Slide down the banner
        _animController.forward();

        // Auto-dismiss after 6 seconds
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted && _activeReminder == r) {
            _dismissBanner();
          }
        });
        break;
      }
    }
  }

  void _dismissBanner() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeReminder = null;
        });
      }
    });
  }

  void _handleTapReminder() {
    if (_activeReminder == null) return;
    final r = _activeReminder!;
    _dismissBanner();

    if (r.itemId != null) {
      final vaultItems = ref.read(vaultProvider);
      final matches = vaultItems.where((i) => i.id == r.itemId).toList();
      if (matches.isNotEmpty) {
        CollectionItemsScreen.openItemDirectly(context, ref, matches.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        widget.child,
        if (_activeReminder != null)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) => Positioned(
              top: _slideAnimation.value,
              left: 16,
              right: 16,
              child: child!,
            ),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: InkWell(
                          onTap: _handleTapReminder,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEB196),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.alarm, color: Color(0xFF79422D), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Reminder Triggered',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _activeReminder!.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _dismissBanner,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white54,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text('Dismiss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
