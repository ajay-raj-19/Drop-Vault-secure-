import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/desktop_sidebar.dart';
import 'collection_items_screen.dart';

/// Configuration for each item category (icon, colors, sample data).
class _CategoryConfig {
  final String title;
  final IconData icon;
  final Color lightBg;
  final Color darkBg;
  final Color lightIcon;
  final Color darkIcon;
  final List<_SampleItem> sampleItems;

  const _CategoryConfig({
    required this.title,
    required this.icon,
    required this.lightBg,
    required this.darkBg,
    required this.lightIcon,
    required this.darkIcon,
    required this.sampleItems,
  });
}

class _SampleItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SampleItem({required this.title, required this.subtitle, required this.icon});
}

/// Maps category type strings to their display configuration.
final Map<String, _CategoryConfig> _categoryConfigs = {
  'link': const _CategoryConfig(
    title: 'Saved Links',
    icon: Icons.link,
    lightBg: Color(0xFFFEB196),
    darkBg: Color(0xFF3D2518),
    lightIcon: Color(0xFF79422D),
    darkIcon: Color(0xFFFEB196),
    sampleItems: [
      _SampleItem(title: 'Flutter Documentation', subtitle: 'flutter.dev • Saved 2 days ago', icon: Icons.language),
      _SampleItem(title: 'GitHub Repository — Drop Vault', subtitle: 'github.com • Saved today', icon: Icons.code),
      _SampleItem(title: 'UI Design Inspiration', subtitle: 'dribbble.com • Saved 1 week ago', icon: Icons.palette),
      _SampleItem(title: 'YouTube — Advanced Riverpod', subtitle: 'youtube.com • Saved 3 days ago', icon: Icons.play_circle_outline),
      _SampleItem(title: 'Medium — State Management Guide', subtitle: 'medium.com • Saved 5 days ago', icon: Icons.article),
      _SampleItem(title: 'Stack Overflow — GoRouter Help', subtitle: 'stackoverflow.com • Saved 1 week ago', icon: Icons.question_answer),
    ],
  ),
  'note': const _CategoryConfig(
    title: 'Saved Notes',
    icon: Icons.edit_note,
    lightBg: Color(0xFFEEDBFF),
    darkBg: Color(0xFF2A1845),
    lightIcon: Color(0xFF270B46),
    darkIcon: Color(0xFFD9B9FD),
    sampleItems: [
      _SampleItem(title: 'Meeting Notes — Sprint Planning', subtitle: 'Last edited 2 hours ago', icon: Icons.groups),
      _SampleItem(title: 'Personal Journal — June 2026', subtitle: 'Last edited yesterday', icon: Icons.book),
      _SampleItem(title: 'Study Notes — System Design', subtitle: 'Last edited 3 days ago', icon: Icons.school),
      _SampleItem(title: 'Quick Ideas & Brainstorming', subtitle: 'Last edited today', icon: Icons.lightbulb),
      _SampleItem(title: 'Recipe Collection', subtitle: 'Last edited 1 week ago', icon: Icons.restaurant),
    ],
  ),
  'file': const _CategoryConfig(
    title: 'Saved Files',
    icon: Icons.upload_file,
    lightBg: Color(0xFFD6E8FF),
    darkBg: Color(0xFF1A2538),
    lightIcon: Color(0xFF1B4A7D),
    darkIcon: Color(0xFF8CB4E8),
    sampleItems: [
      _SampleItem(title: 'Q3 Financial Report.pdf', subtitle: '4.2 MB • Uploaded 2 hours ago', icon: Icons.picture_as_pdf),
      _SampleItem(title: 'Project Proposal.docx', subtitle: '1.8 MB • Uploaded yesterday', icon: Icons.description),
      _SampleItem(title: 'Presentation — Q4 Goals.pptx', subtitle: '12.5 MB • Uploaded 3 days ago', icon: Icons.slideshow),
      _SampleItem(title: 'Source Code Backup.zip', subtitle: '48 MB • Uploaded 1 week ago', icon: Icons.folder_zip),
      _SampleItem(title: 'Resume_2026_v3.pdf', subtitle: '256 KB • Uploaded 2 weeks ago', icon: Icons.picture_as_pdf),
    ],
  ),
  'image': const _CategoryConfig(
    title: 'Saved Images',
    icon: Icons.image,
    lightBg: Color(0xFFFFDAD6),
    darkBg: Color(0xFF3A1816),
    lightIcon: Color(0xFF390B09),
    darkIcon: Color(0xFFFFB4AB),
    sampleItems: [
      _SampleItem(title: 'Mountain_Retreat_Header.jpg', subtitle: '12 MB • Uploaded today', icon: Icons.landscape),
      _SampleItem(title: 'App Screenshot — Dashboard.png', subtitle: '2.1 MB • Saved 2 days ago', icon: Icons.screenshot),
      _SampleItem(title: 'Design Reference — Color Palette', subtitle: '800 KB • Saved 1 week ago', icon: Icons.color_lens),
      _SampleItem(title: 'Team Photo — Hackathon 2026', subtitle: '5.4 MB • Saved 2 weeks ago', icon: Icons.people),
      _SampleItem(title: 'Wireframe Sketches.png', subtitle: '3.2 MB • Saved 3 days ago', icon: Icons.draw),
    ],
  ),
  'all': const _CategoryConfig(
    title: 'All Items',
    icon: Icons.all_inbox,
    lightBg: Color(0xFFEEDBFF),
    darkBg: Color(0xFF2A1845),
    lightIcon: Color(0xFF270B46),
    darkIcon: Color(0xFFD9B9FD),
    sampleItems: [
      _SampleItem(title: 'GitHub Repository — Drop Vault', subtitle: 'github.com • Saved today', icon: Icons.code),
      _SampleItem(title: 'Meeting Notes — Sprint Planning', subtitle: 'Last edited 2 hours ago', icon: Icons.groups),
      _SampleItem(title: 'Q3 Financial Report.pdf', subtitle: '4.2 MB • Uploaded 2 hours ago', icon: Icons.picture_as_pdf),
      _SampleItem(title: 'Mountain_Retreat_Header.jpg', subtitle: '12 MB • Uploaded today', icon: Icons.landscape),
    ],
  ),
};

/// A filtered list view that displays items of a single category.
///
/// Accessible via routes: /items/link, /items/note, /items/file, /items/image
class FilteredItemsScreen extends ConsumerWidget {
  final String categoryType;

  const FilteredItemsScreen({super.key, required this.categoryType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _categoryConfigs[categoryType];
    if (config == null) {
      return const Scaffold(body: Center(child: Text('Unknown category')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? config.darkBg : config.lightBg;
    final iconColor = isDark ? config.darkIcon : config.lightIcon;
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final primary = Theme.of(context).colorScheme.primary;

    // Get user-added items of this type from the vault provider
    final vaultItems = ref.watch(vaultProvider)
        .where((item) => categoryType == 'all' || item.type.toLowerCase() == categoryType.toLowerCase())
        .toList();

    final totalItems = vaultItems.length;

    final String emptyTitle;
    final String emptySubtitle;
    final String emptyButtonText;
    final IconData emptyIcon;

    switch (categoryType.toLowerCase()) {
      case 'link':
        emptyTitle = 'No Links Saved';
        emptySubtitle = 'Save your first link to keep it secure and accessible.';
        emptyButtonText = 'Add Link';
        emptyIcon = Icons.link;
        break;
      case 'note':
        emptyTitle = 'No Notes Saved';
        emptySubtitle = 'Write your first note to capture your thoughts.';
        emptyButtonText = 'Add Note';
        emptyIcon = Icons.edit_note;
        break;
      case 'file':
        emptyTitle = 'No Files Saved';
        emptySubtitle = 'Upload your first file to keep it backed up.';
        emptyButtonText = 'Add File';
        emptyIcon = Icons.upload_file;
        break;
      case 'image':
        emptyTitle = 'No Images Saved';
        emptySubtitle = 'Save your first image to secure your visual references.';
        emptyButtonText = 'Add Image';
        emptyIcon = Icons.image;
        break;
      default:
        emptyTitle = 'No Items Saved';
        emptySubtitle = 'Add links, notes, files, or images to start building your vault.';
        emptyButtonText = 'Add Item';
        emptyIcon = Icons.folder_open;
        break;
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    Widget bodyContent = CustomScrollView(
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
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: onSurface, size: 20),
              ),
              onPressed: () => context.go('/main/dashboard'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Category icon badge
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: bgColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(config.icon, size: 32, color: iconColor),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
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
                    'ALL ITEMS',
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
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
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
                    Color tileBgColor = bgColor;
                    Color tileIconColor = iconColor;

                    if (categoryType == 'all') {
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
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == vaultItems.length - 1 ? 120 : 12,
                      ),
                      child: GestureDetector(
                        onTap: () => CollectionItemsScreen.openItemDirectly(context, ref, item),
                        onLongPress: () => CollectionItemsScreen.showItemLongPressBottomSheet(context, ref, item),
                        onSecondaryTapDown: (details) => CollectionItemsScreen.showItemContextMenu(context, ref, item, details.globalPosition),
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
                  icon: emptyIcon,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                  buttonText: emptyButtonText,
                  onTapButton: () => context.go('/main/add'),
                ),
              ),
            ),
        ],
      );

    if (isWide) {
      bodyContent = Row(
        children: [
          const DesktopSidebar(),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? const Color(0x14FFFFFF) : Colors.black.withValues(alpha: 0.05),
          ),
          Expanded(child: bodyContent),
        ],
      );
    }

    return PopScope(
      canPop: isWide,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/main/dashboard');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: bodyContent,
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

}
