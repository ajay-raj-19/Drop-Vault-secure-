import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/premium_empty_state.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> with SingleTickerProviderStateMixin {
  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get outlineVariant => context.appColors.border;
  
  Color get primaryContainer => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.secondaryBackground
      : const Color(0xFF270B46);
  Color get onPrimaryContainer => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.primaryText
      : const Color(0xFF9477B6);
  Color get surfaceContainerLow => context.appColors.secondaryBackground;
  Color get surfaceContainerHigh => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.elevatedCardBackground
      : const Color(0xFFEDE6EC);
  Color get surfaceContainerHighest => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.elevatedCardBackground
      : const Color(0xFFE7E0E6);
  
  Color get secondaryFixed => context.appColors.secondaryFixed;
  Color get onSecondaryFixed => context.appColors.onSecondaryFixed;
  Color get tertiaryFixed => context.appColors.tertiaryFixed;
  Color get onTertiaryFixed => context.appColors.onTertiaryFixed;
  
  Color get error => Theme.of(context).colorScheme.error;
  Color get errorContainer => Theme.of(context).colorScheme.errorContainer;

  bool _isUpcomingTab = true;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: background,
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            Color(0x33E5958E),
            Colors.transparent,
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.5,
            colors: [
              isDark ? const Color(0x11FFFFFF) : const Color(0x11210440),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 800));
              ref.read(reminderProvider.notifier).reloadReminders();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                  child: Column(
                    children: [
                      _buildTabs(),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isUpcomingTab ? _buildUpcomingList() : _buildCompletedState(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: null, // Managed by MainLayoutShell on tab, or hidden for sub-routes
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: background.withValues(alpha: 0.8),
              border: Border(bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.2))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: onSurface),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reminders',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: onSurface),
                    onPressed: () => context.go('/main/profile/settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Upcoming', true),
          ),
          Expanded(
            child: _buildTabButton('Completed', false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isUpcoming) {
    final isActive = _isUpcomingTab == isUpcoming;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isUpcomingTab = isUpcoming;
          });
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? onPrimaryContainer : onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingList() {
    final vaultItems = ref.watch(vaultProvider);
    final reminders = ref.watch(reminderProvider).where((r) {
      if (r.isCompleted) return false;
      if (r.itemId != null) {
        return vaultItems.any((item) => item.id == r.itemId);
      }
      return true;
    }).toList();
    
    // Sort reminders: Nearest upcoming reminder first
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (reminders.isEmpty) {
      return Center(
        key: const ValueKey('upcoming_empty'),
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: PremiumEmptyState(
            icon: Icons.calendar_month,
            title: 'No Reminders Scheduled',
            subtitle: 'Add reminders to important items so you never miss them.',
            buttonText: 'Create Reminder',
            onTapButton: () => _showCreateReminderDialog(context),
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey('upcoming'),
      children: reminders.map((reminder) {
        final dateStr = '${reminder.dateTime.year}-${reminder.dateTime.month.toString().padLeft(2, '0')}-${reminder.dateTime.day.toString().padLeft(2, '0')} • ${reminder.dateTime.hour.toString().padLeft(2, '0')}:${reminder.dateTime.minute.toString().padLeft(2, '0')}';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildReminderCard(
            id: reminder.id,
            tagLabel: reminder.collectionName,
            tagBg: secondaryFixed,
            tagText: onSecondaryFixed,
            title: reminder.title,
            date: dateStr,
            icon: Icons.calendar_today,
          ),
        );
      }).toList(),
    );
  }  Widget _buildReminderCard({
    required String id,
    required String tagLabel,
    required Color tagBg,
    required Color tagText,
    required String title,
    required String date,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(16)),
                      child: Text(tagLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tagText)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: Icon(Icons.more_vert, color: onSurfaceVariant), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, size: 18, color: onSurfaceVariant),
              const SizedBox(width: 8),
              Text(date, style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {},
                    style: IconButton.styleFrom(foregroundColor: onSurfaceVariant, hoverColor: surfaceContainerHighest),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => ref.read(reminderProvider.notifier).deleteReminder(id),
                    style: IconButton.styleFrom(foregroundColor: error, hoverColor: errorContainer.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => ref.read(reminderProvider.notifier).toggleReminder(id),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Complete'),
                style: TextButton.styleFrom(
                  foregroundColor: onSurface,
                  backgroundColor: surfaceContainerHigh,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) return primaryContainer;
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) return onPrimaryContainer;
                    return onSurface;
                  }),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showCreateReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final collections = ref.read(collectionProvider);
    String? selectedCollection = collections.isNotEmpty ? collections.first.name : 'Personal Research';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Text('Create Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: 'Enter reminder title...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Select Collection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCollection,
                items: collections.isNotEmpty
                    ? collections.map((col) => DropdownMenuItem(value: col.name, child: Text(col.name))).toList()
                    : [const DropdownMenuItem(value: 'Personal Research', child: Text('Personal Research'))],
                onChanged: (val) {
                  setState(() {
                    selectedCollection = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date & Time:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text('${selectedDate.month}/${selectedDate.day} ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(ctx);
                  final newReminder = Reminder(
                    id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    collectionName: selectedCollection ?? 'Personal Research',
                    dateTime: selectedDate,
                  );
                  await ref.read(reminderProvider.notifier).addReminder(newReminder);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    final vaultItems = ref.watch(vaultProvider);
    final completedReminders = ref.watch(reminderProvider).where((r) {
      if (!r.isCompleted) return false;
      if (r.itemId != null) {
        return vaultItems.any((item) => item.id == r.itemId);
      }
      return true;
    }).toList();
    if (completedReminders.isNotEmpty) {
      return Column(
        key: const ValueKey('completed'),
        children: completedReminders.map((reminder) {
          final dateStr = '${reminder.dateTime.year}-${reminder.dateTime.month.toString().padLeft(2, '0')}-${reminder.dateTime.day.toString().padLeft(2, '0')} • ${reminder.dateTime.hour.toString().padLeft(2, '0')}:${reminder.dateTime.minute.toString().padLeft(2, '0')}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildReminderCard(
              id: reminder.id,
              tagLabel: reminder.collectionName,
              tagBg: tertiaryFixed,
              tagText: onSecondaryFixed,
              title: reminder.title,
              date: dateStr,
              icon: Icons.check_circle,
            ),
          );
        }).toList(),
      );
    }

    return Column(
      key: const ValueKey('completed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          width: 192,
          height: 192,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: surfaceContainerHigh.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Icon(Icons.alarm, size: 192, color: primary.withValues(alpha: 0.2)),
                ),
              ),
              RotationTransition(
                turns: _spinController,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: outlineVariant.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Everything\'s Cleared', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No completed reminders yet. Tasks you finish will appear here for your records.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isUpcomingTab = true;
            });
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Upcoming', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
      ],
    );
  }
}
