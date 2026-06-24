import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultSearchApp());
}

class DropVaultSearchApp extends StatelessWidget {
  const DropVaultSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Theme Colors
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color primaryFixedDim = Color(0xFFD9B9FD);
  static const Color surfaceContainer = Color(0xFFF3ECF2);
  static const Color surfaceContainerHigh = Color(0xFFEDE6EC);
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color outline = Color(0xFF7B757F);
  static const Color secondary = Color(0xFF8A4F39);
  static const Color secondaryContainer = Color(0xFFFEB196);

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryFixedDim, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA6ho6wlRZTm47f61uXRWC4LbSV1mpjRrIgNCFt6vwn7dI4EIVX0vQraTBTH0VvegM_AEGjGAe70hTaJCI5NKZuy6SMO8IznYczjylrGRC6wQEy8mYWus2TJRP22giQBWcWqGWSWGD0XeY0iaj0qPYU-XZ4ZHYel7FeG2tmV7NgZiVWPnMd2YBg4Ec0E3kpr7bVT168e9aF80v-2ZS57SsA6MVuSmiDezbcg9FDHULe-b60fRSSAZIw1t4ZoBPQRxjOWEDQYXxwGuWv'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
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
                  icon: const Icon(Icons.settings, color: onSurface),
                  onPressed: () {},
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
                            Expanded(flex: 8, child: _buildSearchResults(isDesktop)),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecentSearches(),
                            const SizedBox(height: 32),
                            _buildSearchResults(isDesktop),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFilterChips() {
    final categories = ['All', 'Links', 'Notes', 'Files', 'Images', 'Collections'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.asMap().entries.map((entry) {
          int idx = entry.key;
          String label = entry.value;
          bool isSelected = idx == 0;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : onSurfaceVariant,
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
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface)),
              TextButton(
                onPressed: () {},
                child: const Text('Clear all', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecentSearchItem('Moodboard 2024'),
          _buildRecentSearchItem('Quarterly Review.pdf'),
          _buildRecentSearchItem('New York Trip Ideas'),
          _buildRecentSearchItem('Recipe: Sourdough'),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: outline),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, color: onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Search Results ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface)),
            Text('(12)', style: TextStyle(fontSize: 20, color: onSurfaceVariant.withOpacity(0.8))),
          ],
        ),
        const SizedBox(height: 16),
        
        // Result Card 1: Image
        _GlassCard(
          padding: EdgeInsets.zero,
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isDesktop ? 250 : double.infinity,
                height: 192,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAzFR9L07F-wzdYQKt2upH6zIVnuwI4eDQcuCE1RMk33AvP2CGgwnIKHgYzzXg4cIFZqZlzNNJ416P6W5Pufvb8O_0DUIo3jl_esQDQ0tKMGfJ1Ekvnc5NzPCtHWNbkE-jyB_H-Bkg5GLLncxRnBV8uCItnOStyetNvgK-jUd1sLcWDkqTqbUJZd2rvr94negVebNDjKORiAv2Oyd4CMBTYFa7siczmV6T1L9ahhYbuL58oBPaAPqNjOHj28w0yb8FVO8ahTnFHTId8'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12, left: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            color: Colors.white.withOpacity(0.8),
                            child: const Text('IMAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primary)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('Abstract Geometric Textures', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                          Icon(Icons.star_outline, color: onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('High-resolution textures for the upcoming UI redesign project. Part of the Visual Research collection.', style: TextStyle(fontSize: 14, color: onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: secondaryContainer.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                Icon(Icons.folder, size: 14, color: secondary),
                                const SizedBox(width: 4),
                                Text('Inspiration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('Edited 2h ago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: outline)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result Card 2: Link
        _GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.link, size: 32, color: primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Linear.app - Modern Project Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Icon(Icons.more_vert, color: onSurfaceVariant),
                      ],
                    ),
                    const Text('https://linear.app/features', style: TextStyle(fontSize: 14, color: primary, decoration: TextDecoration.underline)),
                    const SizedBox(height: 8),
                    const Text('Saved this for the workflow optimization case study. Excellent keyboard shortcut implementation references.', style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTag('Web Resource'),
                        const SizedBox(width: 8),
                        _buildTag('Reference'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result Card 3: Note
        Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: primary, width: 4)),
          ),
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes, color: primary),
                        SizedBox(width: 8),
                        Text('Design System Philosophy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Icon(Icons.open_in_new, color: onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'The design system should prioritize clarity over decoration. Every component must serve a functional purpose while maintaining a premium tactile feel. We are aiming for a "Digital Sanctuary" effect—a space where users feel in control and at peace with their data...',
                  style: TextStyle(fontSize: 16, color: onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black12),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildAvatarInitials('AS', const Color(0xFFE7E0E6)),
                        Transform.translate(offset: const Offset(-8, 0), child: _buildAvatarInitials('JD', primaryFixedDim)),
                      ],
                    ),
                    const Text('Modified Sep 14, 2023', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: outline)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Result Card 4: File
        _GlassCard(
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFFFDAD6).withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.picture_as_pdf, size: 28, color: Colors.red),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Brand_Styleguide_v2.pdf', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('4.2 MB • Updated 12 days ago', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {},
                style: IconButton.styleFrom(backgroundColor: surfaceContainerHigh),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
    );
  }

  Widget _buildAvatarInitials(String initials, Color bgColor) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEF7FD).withOpacity(0.8),
            border: Border(top: BorderSide(color: outline.withOpacity(0.3))),
          ),
          padding: const EdgeInsets.only(bottom: 32, top: 16, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'home', false),
              _buildActiveSearchNavItem(),
              _buildAddFabItem(),
              _buildNavItem(Icons.folder_copy, 'vault', false),
              _buildNavItem(Icons.person, 'profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? primary : onSurfaceVariant.withOpacity(0.6)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? primary : onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSearchNavItem() {
    return Transform.scale(
      scale: 1.1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search, color: primary),
          SizedBox(height: 4),
          Text('search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
        ],
      ),
    );
  }

  Widget _buildAddFabItem() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: primary, shape: BoxShape.circle),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

// Interactive Search Bar Widget
class _AnimatedSearchBar extends StatefulWidget {
  const _AnimatedSearchBar();

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar> {
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController(text: "Design Inspiration");

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: _isFocused 
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))] 
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: FocusScope(
          child: Focus(
            onFocusChange: (focus) => setState(() => _isFocused = focus),
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Search your sanctuary...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 20, right: 12),
                  child: Icon(Icons.search, color: Colors.black),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF4A454F)),
                  onPressed: () => _controller.clear(),
                ),
                filled: true,
                fillColor: const Color(0xFFF3ECF2),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: Color(0xFFD9B9FD), width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Glass Card Widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D528E).withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}