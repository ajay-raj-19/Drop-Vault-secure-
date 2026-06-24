import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultCollectionsApp());
}

class DropVaultCollectionsApp extends StatelessWidget {
  const DropVaultCollectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Collections',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const CollectionsPage(),
    );
  }
}

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  // Theme Colors
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color surfaceContainer = Color(0xFFF3ECF2);
  static const Color surfaceContainerLow = Color(0xFFF8F2F7);
  static const Color primaryFixedDim = Color(0xFFD9B9FD);
  static const Color outlineVariant = Color(0xFFCCC4D0);

  final String _profileImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBQOzJCqTPd2ZK9-Xk7KW2cNc1GKFmYCecwLp2aSH6VJ3OysoYNEsUIxO_d6ydVqRmLGn4dxT-BK37k3tNWxz6Wpoe44LSLhwGXwNIVd0LqObfcdqk7LEIDqiIaDhubB1He3tl8aJRNRvVlYde79f1aiCDvYItVCoGUzYJEY46x1b1uMUAzaXxUd-GX1uJiZ2bz5Y7G2BysSrCpAqu2RUKU2xUTNp7irZ9M3l2xzzJ8Lxl8NwLl2oob3Wr-SwxWsYVXZDxCby96pDJx';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          // Desktop Navigation Rail
          if (isDesktop) _buildNavRail(),
          
          // Main Content
          Expanded(
            child: CustomScrollView(
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
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildCollectionsGrid(isDesktop),
                            const SizedBox(height: 48),
                            const Text(
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
        ],
      ),
      bottomNavigationBar: !isDesktop ? _buildBottomNav() : null,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surfaceContainer,
              shape: BoxShape.circle,
              image: DecorationImage(image: NetworkImage(_profileImageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Drop Vault', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: onSurface),
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: onSurfaceVariant.withOpacity(0.05),
          ),
        ),
        SizedBox(width: isDesktop ? 32 : 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Collections', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface, height: 1.2)),
              const SizedBox(height: 4),
              const Text('5 active vaults organized for your peace of mind', style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
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
            onPressed: () {},
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsGrid(bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 220,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildCard(
              title: 'Study',
              items: '24 Items',
              updated: 'Updated 2h ago',
              icon: Icons.school,
              watermark: Icons.menu_book,
              gradientColors: [const Color(0xFFF8F2F7), const Color(0xFFEEDBFF)],
              iconColor: primary,
              hasActiveTag: true,
            );
          case 1:
            return _buildCard(
              title: 'Programming',
              items: '142 Items',
              updated: 'Updated yesterday',
              icon: Icons.terminal,
              watermark: Icons.code,
              gradientColors: [const Color(0xFFE7E0E6), const Color(0xFFD9B9FD)],
              iconColor: primary,
            );
          case 2:
            return _buildCard(
              title: 'Fitness',
              items: '12 Items',
              updated: 'Updated 3d ago',
              icon: Icons.fitness_center,
              watermark: Icons.directions_run,
              gradientColors: [const Color(0xFFFEB196), const Color(0xFFFFDBCF)],
              iconColor: const Color(0xFF79422D),
              textColor: const Color(0xFF79422D),
            );
          case 3:
            return _buildCard(
              title: 'Travel',
              items: '38 Items',
              updated: 'Updated Oct 12',
              icon: Icons.explore,
              watermark: Icons.public,
              gradientColors: [const Color(0xFFF3ECF2), const Color(0xFFFFDAD6)],
              iconColor: primary,
            );
          case 4:
            return _buildCard(
              title: 'Personal',
              items: '56 Items',
              updated: 'Updated 1h ago',
              icon: Icons.lock_person,
              watermark: Icons.shield,
              gradientColors: [const Color(0xFFFFFFFF), const Color(0xFFEDE6EC)],
              iconColor: primary,
              topRightIcon: Icons.enhanced_encryption,
              isBordered: true,
            );
          case 5:
            return _buildEmptyStateCard();
          default:
            return const SizedBox();
        }
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String items,
    required String updated,
    required IconData icon,
    required IconData watermark,
    required List<Color> gradientColors,
    required Color iconColor,
    Color textColor = Colors.black,
    bool hasActiveTag = false,
    IconData? topRightIcon,
    bool isBordered = false,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: isBordered ? Border.all(color: outlineVariant.withOpacity(0.3)) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            // Watermark Icon
            Positioned(
              right: -24,
              bottom: -24,
              child: Icon(watermark, size: 120, color: Colors.black.withOpacity(0.05)),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glass Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), shape: BoxShape.circle),
                          child: Icon(icon, color: iconColor),
                        ),
                      ),
                    ),
                    if (hasActiveTag)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: Colors.white.withOpacity(0.4),
                            child: const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    if (topRightIcon != null)
                      Icon(topRightIcon, color: onSurfaceVariant.withOpacity(0.4)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(items, style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8))),
                        Text(updated, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: textColor.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineVariant.withOpacity(0.5), width: 2, style: BorderStyle.solid), // In a real app, use dotted_border package
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 48, color: onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('Create New Vault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Organize your digital life', style: TextStyle(fontSize: 12, color: onSurfaceVariant.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRail() {
    return Container(
      width: 80,
      color: surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.admin_panel_settings, color: primary, size: 32),
          const SizedBox(height: 48),
          _buildRailIcon(Icons.home, false),
          const SizedBox(height: 16),
          _buildRailIcon(Icons.folder_copy, true),
          const SizedBox(height: 16),
          _buildRailIcon(Icons.inventory_2, false),
          const Spacer(),
          _buildRailIcon(Icons.settings, false),
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary.withOpacity(0.2), width: 2),
              image: DecorationImage(image: NetworkImage(_profileImageUrl), fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailIcon(IconData icon, bool isActive) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Icon(icon, color: isActive ? Colors.white : onSurfaceVariant),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(bottom: 32, top: 16, left: 16, right: 16),
          decoration: BoxDecoration(
            color: background.withOpacity(0.8),
            border: Border(top: BorderSide(color: outlineVariant.withOpacity(0.3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavIcon(Icons.home, 'Home', false),
              _buildBottomNavIcon(Icons.search, 'Search', false),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              _buildBottomNavIcon(Icons.folder_copy, 'Collections', true),
              _buildBottomNavIcon(Icons.person, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? primary : onSurfaceVariant.withOpacity(0.6)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? primary : onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}