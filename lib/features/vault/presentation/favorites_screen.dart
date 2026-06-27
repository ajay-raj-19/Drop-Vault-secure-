import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/premium_empty_state.dart';
import 'collection_items_screen.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final outlineVariant = context.appColors.border;

    final favoriteItems = ref.watch(vaultProvider).where((item) {
      return item.tags.any((t) => t.toLowerCase() == 'favorite' || t.toLowerCase() == 'fav');
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
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
                              'Favorites',
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
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 800));
              ref.read(vaultProvider.notifier).reloadItems();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: Column(
                    children: [
                      if (favoriteItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: PremiumEmptyState(
                            icon: Icons.star_border,
                            title: 'No Favorites Yet',
                            subtitle: 'Add the "favorite" tag to items to see them here.',
                            buttonText: '',
                            onTapButton: () {},
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: favoriteItems.length,
                          itemBuilder: (context, index) {
                            final item = favoriteItems[index];
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
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GestureDetector(
                                onTap: () => CollectionItemsScreen.openItemDirectly(context, ref, item),
                                onLongPress: () => CollectionItemsScreen.showItemLongPressBottomSheet(context, ref, item),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: tileBgColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(tileIcon, color: tileIconColor, size: 22),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.collectionName} • ${item.type.toUpperCase()}',
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
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
