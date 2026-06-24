import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/user_avatar.dart';

class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage> {
  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get surfaceContainer => context.appColors.secondaryBackground;
  Color get surfaceContainerLow => context.appColors.secondaryBackground;
  Color get outlineVariant => context.appColors.border;

  IconData _getCollectionIcon(String name) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return Icons.school;
      case 'project phoenix':
      case 'programming':
        return Icons.terminal;
      case 'financial documents':
      case 'fitness':
        return Icons.fitness_center;
      case 'inspiration box':
      case 'travel':
        return Icons.explore;
      default:
        return Icons.folder;
    }
  }

  IconData _getCollectionWatermark(String name) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return Icons.menu_book;
      case 'project phoenix':
      case 'programming':
        return Icons.code;
      case 'financial documents':
      case 'fitness':
        return Icons.directions_run;
      case 'inspiration box':
      case 'travel':
        return Icons.public;
      default:
        return Icons.folder_open;
    }
  }

  List<Color> _getCollectionColors(String name, bool isDark) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return isDark
            ? [const Color(0xFF1E1E1E), const Color(0xFF27153B)]
            : [const Color(0xFFF8F2F7), const Color(0xFFEEDBFF)];
      case 'project phoenix':
      case 'programming':
        return isDark
            ? [const Color(0xFF1E1E1E), const Color(0xFF2E1C3F)]
            : [const Color(0xFFE7E0E6), const Color(0xFFD9B9FD)];
      case 'financial documents':
      case 'fitness':
        return isDark
            ? [const Color(0xFF3C1F16), const Color(0xFF2B140E)]
            : [const Color(0xFFFEB196), const Color(0xFFFFDBCF)];
      case 'inspiration box':
      case 'travel':
        return isDark
            ? [const Color(0xFF1E1E1E), const Color(0xFF3B1C1A)]
            : [const Color(0xFFF3ECF2), const Color(0xFFFFDAD6)];
      default:
        return isDark
            ? [const Color(0xFF1E1E1E), const Color(0xFF242424)]
            : [const Color(0xFFFFFFFF), const Color(0xFFEDE6EC)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;
    final collections = ref.watch(collectionProvider);
    final vaultItems = ref.watch(vaultProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: background,
      body: Row(
        children: [
          // Desktop Navigation Rail
          if (isDesktop) _buildNavRail(),
          
          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
                ref.read(collectionProvider.notifier).reloadCollections();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                _buildAppBar(isDesktop),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(collections.length),
                            const SizedBox(height: 32),
                            _buildCollectionsGrid(isDesktop, collections, vaultItems),
                            const SizedBox(height: 48),
                            Text(
                              'Security Overview',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                            ),
                            const SizedBox(height: 120), // Padding for bottom nav scrolling
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
      bottomNavigationBar: null, // Now managed by MainLayoutShell
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return SliverAppBar(
      floating: true,
      backgroundColor: background,
      elevation: 0,
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const UserAvatar(
            size: 40,
            borderRadius: 20,
          ),
          const SizedBox(width: 12),
          Text('Drop Vault', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: onSurface),
          onPressed: () => context.go('/main/profile/settings'),
          style: IconButton.styleFrom(
            backgroundColor: onSurfaceVariant.withOpacity(0.05),
          ),
        ),
        SizedBox(width: isDesktop ? 32 : 16),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Collections', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface, height: 1.2)),
              const SizedBox(height: 4),
              Text('$count active vaults organized for your peace of mind', style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8A4F39), Color(0xFF6D528E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6D528E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () => context.go('/main/add'),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsGrid(bool isDesktop, List<Collection> collections, List<VaultItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 140,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: collections.length + 1, // Include "Create New Vault" card at the end
      itemBuilder: (context, index) {
        if (index == collections.length) {
          return _buildEmptyStateCard();
        }

        final col = collections[index];
        final colItemsCount = items.where((item) => item.collectionName == col.name).length;

        return _buildCard(
          title: col.name,
          items: '$colItemsCount Items',
          icon: _getCollectionIcon(col.name),
          onTap: () => context.push('/collection/${Uri.encodeComponent(col.name)}'),
          onLongPress: () => _showCollectionLongPressBottomSheet(context, ref, col),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String items,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(color: outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: primary, size: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              items,
              style: TextStyle(
                fontSize: 12,
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return InkWell(
      onTap: () => _showCreateCollectionDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineVariant.withOpacity(0.5), width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 36, color: onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('Create New Vault', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRail() {
    return Container(
      width: 80,
      color: surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.admin_panel_settings, color: primary, size: 32),
          const SizedBox(height: 48),
          _buildRailIcon(0, Icons.home),
          const SizedBox(height: 16),
          _buildRailIcon(3, Icons.folder_copy),
          const SizedBox(height: 16),
          _buildRailIcon(4, Icons.person),
          const Spacer(),
          _buildRailIcon(4, Icons.settings),
          const SizedBox(height: 16),
          UserAvatar(
            size: 40,
            borderRadius: 20,
            border: Border.all(color: primary.withOpacity(0.2), width: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildRailIcon(int branchIndex, IconData icon) {
    return InkWell(
      onTap: () => context.go(branchIndex == 0 ? '/main/dashboard' : (branchIndex == 3 ? '/main/vault' : '/main/profile')),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onSurfaceVariant),
      ),
    );
  }

  void _showCreateCollectionDialog(BuildContext context) {
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
              _showEditCollectionDialog(context, collection);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _showDeleteCollectionConfirmationDialog(context, collection);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditCollectionDialog(BuildContext context, Collection collection) {
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

  void _showDeleteCollectionConfirmationDialog(BuildContext context, Collection collection) {
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
}
