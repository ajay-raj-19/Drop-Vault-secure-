import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/premium_empty_state.dart';

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get surfaceContainerLow => context.appColors.secondaryBackground;
  Color get surfaceContainerHighest => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.elevatedCardBackground
      : const Color(0xFFE7E0E6);
  Color get outline => context.appColors.mutedText;
  Color get outlineVariant => context.appColors.border;
  
  Color get error => Theme.of(context).colorScheme.error;
  Color get errorContainer => Theme.of(context).colorScheme.errorContainer;
  Color get onErrorContainer => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF93000A);
  
  Color get secondary => context.colorScheme.secondary;
  Color get secondaryContainer => AppColors.secondaryContainer;
  Color get secondaryFixed => context.appColors.secondaryFixed;
  Color get onSecondaryFixedVariant => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF6D3824);
  
  Color get primaryContainer => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.secondaryBackground
      : const Color(0xFF270B46);
  Color get onPrimaryContainer => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.primaryText
      : const Color(0xFF9477B6);
  
  Color get tertiaryFixed => context.appColors.tertiaryFixed;
  Color get onTertiaryFixedVariant => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF703531);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _getDaysLeft(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt).inDays;
    final left = 30 - difference;
    return left.clamp(0, 30);
  }

  IconData _getIconData(VaultItem item) {
    if (item.type.toLowerCase() == 'collection') return Icons.folder;
    return item.getIconData();
  }

  Color _getIconBgColor(VaultItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (item.type.toLowerCase()) {
      case 'collection':
        return isDark ? const Color(0xFF2A1845) : const Color(0xFFEEDBFF);
      case 'link':
        return isDark ? const Color(0xFF3D2518) : const Color(0xFFFEB196);
      case 'note':
        return isDark ? const Color(0xFF2A1845) : const Color(0xFFEEDBFF);
      case 'file':
        return isDark ? const Color(0xFF1A2538) : const Color(0xFFD6E8FF);
      case 'image':
        return isDark ? const Color(0xFF3A1816) : const Color(0xFFFFDAD6);
      default:
        return isDark ? const Color(0xFF242424) : const Color(0xFFEDE6EC);
    }
  }

  Color _getIconColor(VaultItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (item.type.toLowerCase()) {
      case 'collection':
        return isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
      case 'link':
        return isDark ? const Color(0xFFFEB196) : const Color(0xFF79422D);
      case 'note':
        return isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
      case 'file':
        return isDark ? const Color(0xFF8CB4E8) : const Color(0xFF1B4A7D);
      case 'image':
        return isDark ? const Color(0xFFFFB4AB) : const Color(0xFF390B09);
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }

  Future<void> _restoreItem(VaultItem item) async {
    try {
      if (item.type.toLowerCase() == 'collection') {
        final Map<String, dynamic> colMap = jsonDecode(item.content);
        final col = Collection.fromJson(colMap);
        await ref.read(collectionProvider.notifier).addCollection(col);
      } else {
        final collections = ref.read(collectionProvider);
        final collectionExists = collections.any((c) => c.name.toLowerCase() == item.collectionName.toLowerCase());
        if (!collectionExists && item.collectionName != 'Personal Research') {
          await ref.read(collectionProvider.notifier).createCollection(item.collectionName);
        }
        await ref.read(vaultProvider.notifier).addItem(item);
      }
      
      await ref.read(trashProvider.notifier).deleteItem(item.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored "${item.title}" successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePermanently(VaultItem item) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Delete Permanently?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete "${item.title}"? This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(trashProvider.notifier).deleteItem(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted permanently'), backgroundColor: Colors.red),
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

  void _showEmptyTrashDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Empty Trash?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete all items in the trash? This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final items = ref.read(trashProvider);
              for (final item in items) {
                await ref.read(trashProvider.notifier).deleteItem(item.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trash emptied successfully'), backgroundColor: Colors.green),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashItems = ref.watch(trashProvider);
    final filteredTrashItems = trashItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(trashItems.isNotEmpty),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768), // max-w-3xl
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWarningCard(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildTrashList(filteredTrashItems),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: null, // Managed by MainLayoutShell
    );
  }

  PreferredSizeWidget _buildAppBar(bool showEmptyButton) {
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
                        icon: Icon(Icons.arrow_back, color: primary),
                        onPressed: () => context.pop(),
                        style: IconButton.styleFrom(
                          hoverColor: surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trash',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: showEmptyButton ? () => _showEmptyTrashDialog(context) : null,
                    style: TextButton.styleFrom(
                      foregroundColor: error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'Empty Trash',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: secondaryFixed.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: secondaryContainer.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-deletion enabled',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSecondaryFixedVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Items in the trash will be permanently deleted after 30 days. Restored items will return to their original vaults.',
                  style: TextStyle(fontSize: 16, color: onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search deleted items...',
          hintStyle: TextStyle(color: outlineVariant, fontSize: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(Icons.search, color: outline),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.primaryFixedDim
                  : AppColors.secondary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildTrashList(List<VaultItem> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: PremiumEmptyState(
          icon: Icons.delete_outline,
          title: _searchQuery.isNotEmpty ? 'No Search Results' : 'Trash is Empty',
          subtitle: _searchQuery.isNotEmpty
              ? 'No items match your query. Try a different search term.'
              : 'Items you delete will appear here and be kept for 30 days before permanent deletion.',
          buttonText: '',
          onTapButton: () {},
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final daysLeft = _getDaysLeft(item.createdAt);
        final isUrgent = daysLeft <= 3;
        final badgeColor = isUrgent ? errorContainer : tertiaryFixed;
        final badgeTextColor = isUrgent ? onErrorContainer : onTertiaryFixedVariant;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildTrashItem(
            item: item,
            title: item.title,
            deletedText: 'Deleted ${_formatDate(item.createdAt)}',
            daysLeft: '$daysLeft days left',
            badgeColor: badgeColor,
            badgeTextColor: badgeTextColor,
            isUrgent: isUrgent,
          ),
        );
      },
    );
  }

  Widget _buildTrashItem({
    required VaultItem item,
    required String title,
    required String deletedText,
    required String daysLeft,
    required Color badgeColor,
    required Color badgeTextColor,
    bool isUrgent = false,
  }) {
    final isImage = item.type.toLowerCase() == 'image';
    final isLocalFile = isImage && !item.content.startsWith('http');

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 500;
          
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon / Image
              if (isImage && isLocalFile && item.content.isNotEmpty)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
                    image: DecorationImage(
                      image: FileImage(File(item.content)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (isImage && item.content.isNotEmpty)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
                    image: DecorationImage(
                      image: NetworkImage(item.content),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getIconBgColor(item),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getIconColor(item).withValues(alpha: 0.2)),
                  ),
                  child: Icon(_getIconData(item), color: _getIconColor(item), size: 28),
                ),
              const SizedBox(width: 16),
              
              // Title & Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(deletedText, style: TextStyle(fontSize: 14, color: outline)),
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: outlineVariant, shape: BoxShape.circle)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isUrgent ? Icons.warning : Icons.timer, size: 14, color: badgeTextColor),
                              const SizedBox(width: 4),
                              Text(daysLeft, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => _restoreItem(item),
                icon: Icon(Icons.settings_backup_restore, size: 20, color: onSurfaceVariant),
                label: Text('Restore', style: TextStyle(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deletePermanently(item),
                icon: Icon(Icons.delete_forever, size: 24, color: outline),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  hoverColor: errorContainer.withValues(alpha: 0.5),
                  foregroundColor: error,
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                content,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: content),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}
