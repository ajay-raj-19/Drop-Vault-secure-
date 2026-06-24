import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../vault/presentation/collection_items_screen.dart';

import '../../../core/widgets/user_avatar.dart';

final dashboardLoadingProvider = StateProvider<bool>((ref) => true);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final displayName = authState.user?.displayName ?? 'Ajay';

    final isLoading = ref.watch(dashboardLoadingProvider);
    if (isLoading) {
      Future.microtask(() {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (context.mounted) {
            ref.read(dashboardLoadingProvider.notifier).state = false;
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true, // Allows content to scroll behind the transparent bottom nav
      appBar: _buildAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
          await ref.read(authRepositoryProvider).reloadSession();
          ref.read(vaultProvider.notifier).reloadItems();
          ref.read(collectionProvider.notifier).reloadCollections();
          ref.read(reminderProvider.notifier).reloadReminders();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingAndSearch(context, displayName),
                  const SizedBox(height: 40),
                  _buildStatsAndActions(context, ref, isLoading),
                  const SizedBox(height: 40),
                  _buildRecentCollections(context, ref, isLoading),
                  const SizedBox(height: 40),
                  _buildMainContentSplit(context, ref, isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
      // bottomNavigationBar removed (now managed by MainLayoutShell)
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final displayName = user?.displayName;
    final email = user?.email;
    final String nameToShow = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email != null && email.isNotEmpty ? email : 'Account');

    final avatarImage = UserAvatar(
      size: 40.0,
      borderRadius: 20.0,
      border: Border.all(color: context.appColors.primaryFixedDim, width: 2),
    );

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      title: GestureDetector(
        onTap: () => context.go('/main/profile'),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatarImage,
            const SizedBox(width: 12),
            Text(
              nameToShow,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary.withOpacity(0.87)),
          onPressed: () => context.go('/main/profile/settings'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildGreetingAndSearch(BuildContext context, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning, $name',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Your digital sanctuary is secure.',
          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search your vault...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? context.appColors.secondaryBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppColors.secondary
                    : AppColors.primaryFixedDim,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard({required double width, required double height, double borderRadius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildStatsAndActions(BuildContext context, WidgetRef ref, bool isLoading) {
    bool isDesktop = MediaQuery.of(context).size.width >= 768;

    final vaultItems = ref.watch(vaultProvider);
    final collections = ref.watch(collectionProvider);

    Widget statsCards;
    if (isLoading) {
      statsCards = Row(
        children: [
          Expanded(child: _buildSkeletonCard(width: double.infinity, height: 160, borderRadius: 24)),
          const SizedBox(width: 16),
          Expanded(child: _buildSkeletonCard(width: double.infinity, height: 160, borderRadius: 24)),
        ],
      );
    } else {
      statsCards = Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/items/all'),
              child: _buildStatCard(
                context, 'Total Items', '${vaultItems.length}', null, null,
                cardColor: const Color(0xFF1D1B1F),
                titleColor: Colors.white70,
                valueColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/main/vault'),
              child: _buildStatCard(
                context, 'Collections', '${collections.length}', null, null,
                showAvatars: false,
                cardColor: const Color(0xFFFEB196),
                titleColor: const Color(0xFF79422D),
                valueColor: const Color(0xFF3D1E10),
              ),
            ),
          ),
        ],
      );
    }

    Widget quickActions = _buildQuickActionsRow(context);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: statsCards),
          const SizedBox(width: 16),
          Expanded(flex: 8, child: quickActions),
        ],
      );
    } else {
      return Column(
        children: [
          statsCards,
          const SizedBox(height: 16),
          quickActions,
        ],
      );
    }
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.link,
            label: 'Link',
            bgColor: isDark ? const Color(0xFF3D2518) : const Color(0xFFFEB196),
            iconColor: isDark ? const Color(0xFFFEB196) : const Color(0xFF79422D),
            shadowColor: const Color(0xFFFEB196),
            onTap: () => context.go('/items/link'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.edit_note,
            label: 'Note',
            bgColor: isDark ? const Color(0xFF2A1845) : const Color(0xFFEEDBFF),
            iconColor: isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46),
            shadowColor: const Color(0xFFD9B9FD),
            onTap: () => context.go('/items/note'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.upload_file,
            label: 'File',
            bgColor: isDark ? const Color(0xFF1A2538) : const Color(0xFFD6E8FF),
            iconColor: isDark ? const Color(0xFF8CB4E8) : const Color(0xFF1B4A7D),
            shadowColor: const Color(0xFF8CB4E8),
            onTap: () => context.go('/items/file'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.image,
            label: 'Image',
            bgColor: isDark ? const Color(0xFF3A1816) : const Color(0xFFFFDAD6),
            iconColor: isDark ? const Color(0xFFFFB4AB) : const Color(0xFF390B09),
            shadowColor: const Color(0xFFFFB4AB),
            onTap: () => context.go('/items/image'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String? subtitle, Color? subtitleColor, {
    bool showAvatars = false,
    Color? cardColor,
    Color? titleColor,
    Color? valueColor,
  }) {
    return GlassCard(
      height: 160,
      padding: const EdgeInsets.all(24),
      boxShadow: DesignTokens.shadowLight,
      baseColor: cardColor ?? Colors.white,
      opacity: cardColor != null ? 1.0 : 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: titleColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, color: valueColor),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor),
                ),
              if (showAvatars)
                Row(
                  children: [
                    _buildMiniAvatar(context.appColors.primaryFixed),
                    Transform.translate(offset: const Offset(-8, 0), child: _buildMiniAvatar(AppColors.secondaryContainer)),
                    Transform.translate(offset: const Offset(-16, 0), child: _buildMiniAvatar(context.appColors.tertiaryFixed)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildRecentCollections(BuildContext context, WidgetRef ref, bool isLoading) {
    final collections = ref.watch(collectionProvider).toList();

    // Sort: Newest created collection first
    collections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Limit: Max 5 collections
    final recentCollections = collections.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Recent Collections', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => context.go('/main/vault'),
              child: Text('VIEW ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildSkeletonCard(width: 256, height: 220, borderRadius: 24),
              ),
            ),
          )
        else if (collections.isEmpty)
          PremiumEmptyState(
            icon: Icons.folder_open,
            title: 'No Collections Yet',
            subtitle: 'Create your first collection to organize links, notes, files and images.',
            buttonText: 'Create Collection',
            onTapButton: () => _showCreateCollectionDialog(context, ref),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: recentCollections.length,
              itemBuilder: (context, index) {
                final col = recentCollections[index];
                final itemsCount = ref.watch(vaultProvider).where((item) => item.collectionName == col.name).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => context.push('/collection/${Uri.encodeComponent(col.name)}'),
                    onLongPress: () => _showCollectionLongPressBottomSheet(context, ref, col),
                    child: _buildCollectionCard(context, col.name, '$itemsCount Items'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionCard(BuildContext context, String title, String subtitle) {
    return GlassCard(
      width: 160,
      height: 120,
      padding: const EdgeInsets.all(16),
      boxShadow: DesignTokens.shadowLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.folder, color: Theme.of(context).colorScheme.primary, size: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentSplit(BuildContext context, WidgetRef ref, bool isLoading) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    final vaultItems = ref.watch(vaultProvider).toList();
    vaultItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentItemsList = vaultItems.take(5).toList();

    Widget recentItems;
    if (isLoading) {
      recentItems = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSkeletonCard(width: double.infinity, height: 80, borderRadius: 16),
          const SizedBox(height: 12),
          _buildSkeletonCard(width: double.infinity, height: 80, borderRadius: 16),
          const SizedBox(height: 12),
          _buildSkeletonCard(width: double.infinity, height: 80, borderRadius: 16),
        ],
      );
    } else if (vaultItems.isEmpty) {
      recentItems = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          PremiumEmptyState(
            icon: Icons.folder,
            title: 'No Items Yet',
            subtitle: 'Save your first link, note, file or image to start building your vault.',
            buttonText: 'Add Item',
            onTapButton: () => context.go('/main/add'),
          ),
        ],
      );
    } else {
      recentItems = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentItemsList.length,
            itemBuilder: (context, index) {
              final item = recentItemsList[index];
              
              IconData icon = item.getIconData();
              Color iconColor = Colors.white;
              Color bgColor = Colors.blue;
              
              if (item.type.toLowerCase() == 'link') {
                iconColor = const Color(0xFF79422D);
                bgColor = const Color(0xFFFEB196);
              } else if (item.type.toLowerCase() == 'note') {
                iconColor = const Color(0xFF270B46);
                bgColor = const Color(0xFFEEDBFF);
              } else if (item.type.toLowerCase() == 'file') {
                iconColor = const Color(0xFF1B4A7D);
                bgColor = const Color(0xFFD6E8FF);
              } else if (item.type.toLowerCase() == 'image') {
                iconColor = const Color(0xFF390B09);
                bgColor = const Color(0xFFFFDAD6);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => CollectionItemsScreen.openItemDirectly(context, ref, item),
                  onLongPress: () => CollectionItemsScreen.showItemLongPressBottomSheet(context, ref, item),
                  child: _buildRecentListItem(
                    context,
                    item.title,
                    '${item.collectionName} • ${item.type.toUpperCase()}',
                    icon,
                    iconColor,
                    bgColor,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    final reminders = ref.watch(reminderProvider).where((r) {
      if (r.isCompleted) return false;
      if (r.itemId != null) {
        return vaultItems.any((item) => item.id == r.itemId);
      }
      return true;
    }).toList();
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final upcomingReminders = reminders.take(3).toList();

    Widget remindersWidget;
    if (isLoading) {
      remindersWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSkeletonCard(width: double.infinity, height: 120, borderRadius: 16),
        ],
      );
    } else if (reminders.isEmpty) {
      remindersWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => context.go('/main/profile/reminder'),
                child: Text('VIEW ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PremiumEmptyState(
            icon: Icons.calendar_month,
            title: 'No Reminders Scheduled',
            subtitle: 'Add reminders to important items so you never miss them.',
            buttonText: 'Create Reminder',
            onTapButton: () => _showCreateReminderDialog(context, ref),
          ),
        ],
      );
    } else {
      remindersWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => context.go('/main/profile/reminder'),
                child: Text('VIEW ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D528E).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.03 : 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
              border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingReminders.length,
              itemBuilder: (context, index) {
                final rem = upcomingReminders[index];
                final dateStr = '${rem.dateTime.month.toString().padLeft(2, '0')}/${rem.dateTime.day.toString().padLeft(2, '0')} • ${rem.dateTime.hour.toString().padLeft(2, '0')}:${rem.dateTime.minute.toString().padLeft(2, '0')}';
                
                return Padding(
                  padding: EdgeInsets.only(bottom: index == upcomingReminders.length - 1 ? 0 : 16.0),
                  child: GestureDetector(
                    onTap: () => _showReminderDetailsDialog(context, ref, rem),
                    child: _buildReminderItem(dateStr, rem.title, index == 0),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: recentItems),
          const SizedBox(width: 40),
          Expanded(flex: 1, child: remindersWidget),
        ],
      );
    } else {
      return Column(
        children: [
          recentItems,
          const SizedBox(height: 40),
          remindersWidget,
        ],
      );
    }
  }



  void _showReminderDetailsDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Reminder Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Collection: ${reminder.collectionName}'),
            const SizedBox(height: 8),
            Text('Time: ${reminder.dateTime.toLocal().toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(reminderProvider.notifier).toggleReminder(reminder.id);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }



  void _showCollectionLongPressBottomSheet(BuildContext context, WidgetRef ref, Collection collection) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/collection/${Uri.encodeComponent(collection.name)}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              _showEditCollectionDialog(context, ref, collection);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _showDeleteCollectionConfirmationDialog(context, ref, collection);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditCollectionDialog(BuildContext context, WidgetRef ref, Collection collection) {
    final nameController = TextEditingController(text: collection.name);
    final descController = TextEditingController(text: collection.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Edit Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Collection Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newDesc = descController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                final updatedCol = Collection(
                  id: collection.id,
                  name: newName,
                  description: newDesc,
                  createdAt: collection.createdAt,
                );
                await ref.read(collectionProvider.notifier).updateCollection(updatedCol);
                await ref.read(vaultProvider.notifier).renameCollectionInItems(collection.name, newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCollectionConfirmationDialog(BuildContext context, WidgetRef ref, Collection collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Delete Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the collection "${collection.name}"? This will also delete all items inside it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(collectionProvider.notifier).trashCollection(
                collection,
                ref.read(vaultProvider),
                ref.read(trashProvider.notifier),
                ref.read(vaultProvider.notifier),
                ref.read(reminderProvider.notifier),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Collection moved to trash'), backgroundColor: Colors.orange),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }



  void _showCreateCollectionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Create Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter collection name...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(collectionProvider.notifier).createCollection(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateReminderDialog(BuildContext context, WidgetRef ref) {
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

  Widget _buildRecentListItem(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Color bgColor) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      boxShadow: DesignTokens.shadowLight,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String time, String title, bool isHighlighted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2,
          height: 40,
          color: isHighlighted ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(isHighlighted ? 0.7 : 0.5))),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600, color: Colors.white.withOpacity(isHighlighted ? 1.0 : 0.7))),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withOpacity(_isPressed ? 0.3 : 0.15),
                blurRadius: _isPressed ? 24 : 16,
                offset: Offset(0, _isPressed ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: widget.iconColor,
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.iconColor,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
