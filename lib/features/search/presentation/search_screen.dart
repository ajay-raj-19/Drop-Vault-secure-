import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/providers.dart';
import '../../vault/presentation/collection_items_screen.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/user_avatar.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get primaryFixedDim => context.appColors.primaryFixedDim;
  Color get surfaceContainerHigh => context.appColors.secondaryBackground;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get outline => context.appColors.mutedText;
  Color get secondary => Theme.of(context).colorScheme.secondary;
  Color get secondaryContainer => AppColors.secondaryContainer;

  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    // Get search query from Riverpod
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();

    // Get vault items & collections
    final allItems = ref.watch(vaultProvider);
    final allCollections = ref.watch(collectionProvider);

    // Filter collections
    final filteredCollections = allCollections.where((col) {
      if (_selectedFilter != 'All' && _selectedFilter != 'Collections') {
        return false;
      }
      if (query.isEmpty) return true;
      final matchesName = col.name.toLowerCase().contains(query);
      final matchesDesc = col.description.toLowerCase().contains(query);
      return matchesName || matchesDesc;
    }).toList();

    // Filter vault items
    final filteredItems = allItems.where((item) {
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Links' && item.type.toLowerCase() != 'link') return false;
        if (_selectedFilter == 'Notes' && item.type.toLowerCase() != 'note') return false;
        if (_selectedFilter == 'Files' && item.type.toLowerCase() != 'file') return false;
        if (_selectedFilter == 'Images' && item.type.toLowerCase() != 'image') return false;
        if (_selectedFilter == 'Collections') return false;
      }
      if (query.isEmpty) return true;
      final matchesTitle = item.title.toLowerCase().contains(query);
      final matchesContent = item.content.toLowerCase().contains(query);
      final matchesCollectionName = item.collectionName.toLowerCase().contains(query);
      final matchesTags = item.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesTitle || matchesContent || matchesCollectionName || matchesTags;
    }).toList();

    // Combined results list
    final results = [
      ...filteredCollections,
      ...filteredItems,
    ];

    return Scaffold(
      backgroundColor: background,
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
          ref.read(vaultProvider.notifier).reloadItems();
          ref.read(collectionProvider.notifier).reloadCollections();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          slivers: [
            // Hide-on-scroll AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: background,
              elevation: 0,
              toolbarHeight: 80,
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16.0 : 0.0),
                child: Row(
                  children: [
                    UserAvatar(
                      size: 40,
                      borderRadius: 20,
                      border: Border.all(color: primaryFixedDim, width: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Drop Vault',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32.0 : 16.0),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: onSurface),
                    onPressed: () => context.go('/main/profile/settings'),
                  ),
                ),
              ],
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Search Bar
                        const _AnimatedSearchBar(),
                        const SizedBox(height: 24),

                        // Filter Chips
                        _buildFilterChips(),
                        const SizedBox(height: 32),

                        // Layout Grid (Recent Searches + Results)
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: _buildRecentSearches()),
                              const SizedBox(width: 40),
                              Expanded(flex: 8, child: _buildSearchResults(isDesktop, results)),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRecentSearches(),
                              const SizedBox(height: 32),
                              _buildSearchResults(isDesktop, results),
                            ],
                          ),
                        
                        // Bottom padding to clear nav bar
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = ['All', 'Links', 'Notes', 'Files', 'Images', 'Collections'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((label) {
          bool isSelected = label == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = label;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) 
                          : onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recentSearches = ref.watch(recentSearchesProvider);
    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface)),
              TextButton(
                onPressed: () {
                  ref.read(recentSearchesProvider.notifier).clearAll();
                },
                child: Text('Clear all', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentSearches.map((query) => _buildRecentSearchItem(query)),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: outline),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                ref.read(searchQueryProvider.notifier).state = query;
                ref.read(recentSearchesProvider.notifier).addSearch(query);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(query, style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: outline),
            onPressed: () {
              ref.read(recentSearchesProvider.notifier).removeSearch(query);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDesktop, List<dynamic> results) {
    if (results.isEmpty) {
      return PremiumEmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        subtitle: 'We couldn\'t find any items or collections matching your search.',
        buttonText: 'Reset Search',
        onTapButton: () {
          ref.read(searchQueryProvider.notifier).state = '';
          setState(() {
            _selectedFilter = 'All';
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Search Results ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface)),
            Text('(${results.length})', style: TextStyle(fontSize: 20, color: onSurfaceVariant.withValues(alpha: 0.8))),
          ],
        ),
        const SizedBox(height: 16),
        ...results.map((res) => _buildResultItemRow(res)),
      ],
    );
  }

  Widget _buildResultItemRow(dynamic searchResult) {
    final isCollection = searchResult is Collection;
    
    IconData iconData;
    Color iconColor = primary;
    String title = '';
    String categoryLabel = '';
    
    if (isCollection) {
      iconData = Icons.folder;
      title = searchResult.name;
      categoryLabel = 'Collection';
      iconColor = secondary;
    } else {
      final item = searchResult as VaultItem;
      title = item.title;
      categoryLabel = item.type.toUpperCase();
      
      iconData = item.getIconData();
      switch (item.type.toLowerCase()) {
        case 'link':
          iconColor = primary;
          break;
        case 'note':
          iconColor = Colors.orange;
          break;
        case 'file':
          iconColor = Colors.red;
          break;
        case 'image':
          iconColor = Colors.blue;
          break;
        default:
          iconColor = primary;
      }
    }
    
    return GestureDetector(
      onTap: () {
        if (isCollection) {
          context.push('/collection/${Uri.encodeComponent(searchResult.name)}');
        } else {
          CollectionItemsScreen.openItemDirectly(context, ref, searchResult as VaultItem);
        }
      },
      onLongPress: () {
        if (isCollection) {
          _showCollectionLongPressBottomSheet(context, searchResult);
        } else {
          CollectionItemsScreen.showItemLongPressBottomSheet(context, ref, searchResult as VaultItem);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          boxShadow: const [],
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceVariant.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollectionLongPressBottomSheet(BuildContext context, Collection collection) {
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

// Interactive Search Bar Widget
class _AnimatedSearchBar extends ConsumerStatefulWidget {
  const _AnimatedSearchBar();

  @override
  ConsumerState<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends ConsumerState<_AnimatedSearchBar> {
  bool _isFocused = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (_controller.text != next) {
        _controller.text = next;
      }
    });

    return AnimatedScale(
      scale: _isFocused ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: _isFocused 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))] 
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
        ),
        child: FocusScope(
          child: Focus(
            onFocusChange: (focus) => setState(() => _isFocused = focus),
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 18),
              textInputAction: TextInputAction.search,
              onChanged: (val) {
                ref.read(searchQueryProvider.notifier).state = val;
              },
              onSubmitted: (val) {
                ref.read(recentSearchesProvider.notifier).addSearch(val);
              },
              decoration: InputDecoration(
                hintText: 'Search your sanctuary...',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  child: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.appColors.primaryFixedDim
                        : Theme.of(context).colorScheme.secondary,
                    width: 2,
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
