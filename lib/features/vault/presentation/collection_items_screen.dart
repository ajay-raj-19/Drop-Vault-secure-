import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/user_avatar.dart';

class CollectionItemsScreen extends ConsumerWidget {
  final String collectionName;

  const CollectionItemsScreen({super.key, required this.collectionName});

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

  Color _getCollectionBgColor(String name, bool isDark) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return isDark ? const Color(0xFF27153B) : const Color(0xFFEEDBFF);
      case 'project phoenix':
      case 'programming':
        return isDark ? const Color(0xFF2E1C3F) : const Color(0xFFD9B9FD);
      case 'financial documents':
      case 'fitness':
        return isDark ? const Color(0xFF3C1F16) : const Color(0xFFFEB196);
      case 'inspiration box':
      case 'travel':
        return isDark ? const Color(0xFF3B1C1A) : const Color(0xFFFFDAD6);
      default:
        return isDark ? const Color(0xFF242424) : const Color(0xFFEDE6EC);
    }
  }

  Color _getCollectionIconColor(String name, bool isDark) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
      case 'project phoenix':
      case 'programming':
        return isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
      case 'financial documents':
      case 'fitness':
        return isDark ? const Color(0xFFFEB196) : const Color(0xFF79422D);
      case 'inspiration box':
      case 'travel':
        return isDark ? const Color(0xFFFFB4AB) : const Color(0xFF390B09);
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _getCollectionBgColor(collectionName, isDark);
    final iconColor = _getCollectionIconColor(collectionName, isDark);
    final iconData = _getCollectionIcon(collectionName);
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final primary = Theme.of(context).colorScheme.primary;

    // Get user-added items of this collection
    final vaultItems = ref.watch(vaultProvider)
        .where((item) => item.collectionName.toLowerCase() == collectionName.toLowerCase())
        .toList();

    final totalItems = vaultItems.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/main/vault');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            // --- Collapsing App Bar with category header ---
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: onSurface, size: 20),
                ),
                onPressed: () => context.go('/main/vault'),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => context.go('/main/profile'),
                    child: const Center(
                      child: UserAvatar(size: 32, borderRadius: 16),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Collection icon badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: bgColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(iconData, size: 32, color: iconColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collectionName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalItems items',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Item count + sort bar ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COLLECTION ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 16, color: onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Recent',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- User-added vault items (if any) ---
            if (vaultItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = vaultItems[index];
                      
                      IconData tileIcon = item.getIconData();
                      Color tileBgColor = Colors.grey;
                      Color tileIconColor = Colors.white;

                      if (item.type.toLowerCase() == 'link') {
                        tileIconColor = isDark ? const Color(0xFFFEB196) : const Color(0xFF79422D);
                        tileBgColor = isDark ? const Color(0xFF3D2518) : const Color(0xFFFEB196);
                      } else if (item.type.toLowerCase() == 'note') {
                        tileIconColor = isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
                        tileBgColor = isDark ? const Color(0xFF2A1845) : const Color(0xFFEEDBFF);
                      } else if (item.type.toLowerCase() == 'file') {
                        tileIconColor = isDark ? const Color(0xFF8CB4E8) : const Color(0xFF1B4A7D);
                        tileBgColor = isDark ? const Color(0xFF1A2538) : const Color(0xFFD6E8FF);
                      } else if (item.type.toLowerCase() == 'image') {
                        tileIconColor = isDark ? const Color(0xFFFFB4AB) : const Color(0xFF390B09);
                        tileBgColor = isDark ? const Color(0xFF3A1816) : const Color(0xFFFFDAD6);
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == vaultItems.length - 1 ? 120 : 12,
                        ),
                        child: GestureDetector(
                          onTap: () => openItemDirectly(context, ref, item),
                          onLongPress: () => showItemLongPressBottomSheet(context, ref, item),
                          child: _buildItemTile(
                            context,
                            title: item.title,
                            subtitle: item.content,
                            icon: tileIcon,
                            bgColor: tileBgColor,
                            iconColor: tileIconColor,
                          ),
                        ),
                      );
                    },
                    childCount: vaultItems.length,
                  ),
                ),
              ),

            if (vaultItems.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: PremiumEmptyState(
                    icon: Icons.folder_open,
                    title: 'No Items In Collection',
                    subtitle: 'Save a new item under this collection to see it here.',
                    buttonText: 'Add Item',
                    onTapButton: () => context.go('/main/add'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      boxShadow: DesignTokens.shadowLight,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: onSurfaceVariant, size: 20),
        ],
      ),
    );
  }

  // --- Core Open Logic (Single Tap) ---
  static Future<void> openItemDirectly(BuildContext context, WidgetRef ref, VaultItem item) async {
    final type = item.type.toLowerCase();
    if (type == 'image') {
      showFullImagePreview(context, item);
    } else if (type == 'link') {
      await launchURL(context, item.content);
    } else if (type == 'note') {
      context.push('/viewer/note', extra: item);
    } else if (type == 'file') {
      await openFileDirectly(context, item.content);
    }
  }

  static Future<void> launchURL(BuildContext context, String urlString) async {
    final cleanUrl = urlString.trim();
    if (cleanUrl.isEmpty) return;
    
    // Add schema if not present
    var finalUrl = cleanUrl;
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      finalUrl = 'https://$cleanUrl';
    }

    try {
      final Uri url = Uri.parse(finalUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link format'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> openFileDirectly(BuildContext context, String filePath) async {
    final cleanPath = filePath.trim();
    if (cleanPath.isEmpty) return;

    try {
      final result = await OpenFilex.open(cleanPath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening file'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static void showFullImagePreview(BuildContext context, VaultItem item) {
    final isUrl = item.content.startsWith('http://') || item.content.startsWith('https://');
    final isLocal = !isUrl && item.content.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SwipeToDismissImageViewer(item: item, isUrl: isUrl, isLocal: isLocal),
      ),
    );
  }

  static void showItemLongPressBottomSheet(BuildContext context, WidgetRef ref, VaultItem item) {
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
              openItemDirectly(context, ref, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              showEditItemDialog(context, ref, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              showDeleteConfirmationDialog(context, ref, item);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static void showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, VaultItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          // we use standard AlertDialog normally, but let's keep the logic.
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            title: const Text('Delete Item?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('This will move the item to the trash.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(vaultProvider.notifier).trashItem(
                    item,
                    ref.read(trashProvider.notifier),
                    ref.read(reminderProvider.notifier),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item moved to trash'), backgroundColor: Colors.orange),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showEditItemDialog(BuildContext context, WidgetRef ref, VaultItem item) {
    final titleController = TextEditingController(text: item.title);
    final contentController = TextEditingController(text: item.content);
    final tagsController = TextEditingController(text: item.tags.join(', '));
    final collections = ref.read(collectionProvider);
    String? selectedCollection = collections.any((c) => c.name == item.collectionName) ? item.collectionName : (collections.isNotEmpty ? collections.first.name : 'Personal Research');

    final String titleLabel;
    final String? contentLabel;
    final bool showContentField;

    if (item.type.toLowerCase() == 'link') {
      titleLabel = 'Title';
      contentLabel = 'URL';
      showContentField = true;
    } else if (item.type.toLowerCase() == 'note') {
      titleLabel = 'Title';
      contentLabel = 'Note Content';
      showContentField = true;
    } else if (item.type.toLowerCase() == 'file') {
      titleLabel = 'File Name';
      contentLabel = null;
      showContentField = false;
    } else if (item.type.toLowerCase() == 'image') {
      titleLabel = 'Image Name';
      contentLabel = null;
      showContentField = false;
    } else {
      titleLabel = 'Title';
      contentLabel = 'Content';
      showContentField = true;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text('Edit ${item.type.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: titleLabel),
                ),
                if (showContentField && contentLabel != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: item.type.toLowerCase() == 'note' ? 5 : 1,
                    decoration: InputDecoration(labelText: contentLabel),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                ),
                const SizedBox(height: 16),
                const Text('Collection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCollection,
                  items: collections.isNotEmpty
                      ? collections.map((col) => DropdownMenuItem(value: col.name, child: Text(col.name))).toList()
                      : [DropdownMenuItem(value: item.collectionName, child: Text(item.collectionName))],
                  onChanged: (val) {
                    setState(() {
                      selectedCollection = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final newTitle = titleController.text.trim();
                final newContent = showContentField ? contentController.text.trim() : item.content;
                final newTags = tagsController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (newTitle.isNotEmpty) {
                  Navigator.pop(ctx);
                  final updatedItem = VaultItem(
                    id: item.id,
                    title: newTitle,
                    type: item.type,
                    content: newContent,
                    collectionName: selectedCollection ?? item.collectionName,
                    createdAt: item.createdAt,
                    tags: newTags,
                  );
                  await ref.read(vaultProvider.notifier).updateItem(updatedItem);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Zoom, Pan, Swipe-to-dismiss Fullscreen Image Viewer widget ---
class SwipeToDismissImageViewer extends StatefulWidget {
  final VaultItem item;
  final bool isUrl;
  final bool isLocal;

  const SwipeToDismissImageViewer({
    super.key,
    required this.item,
    required this.isUrl,
    required this.isLocal,
  });

  @override
  State<SwipeToDismissImageViewer> createState() => SwipeToDismissImageViewerState();
}

class SwipeToDismissImageViewerState extends State<SwipeToDismissImageViewer> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset.abs() > 150 || details.velocity.pixelsPerSecond.dy.abs() > 1000) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragOffset = 0.0;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: Colors.black.withOpacity(
          (0.9 - (_dragOffset.abs() / 1000)).clamp(0.0, 0.9),
        ),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(0.0, _dragOffset),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                maxScale: 4.0,
                child: widget.isUrl
                    ? Image.network(
                        widget.item.content,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 80, color: Colors.white30),
                        ),
                      )
                    : widget.isLocal
                        ? Image.file(
                            File(widget.item.content),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, size: 80, color: Colors.white30),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.broken_image, size: 80, color: Colors.white30),
                          ),
              ),
              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
