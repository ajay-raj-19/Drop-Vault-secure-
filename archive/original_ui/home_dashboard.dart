import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultApp());
}

class DropVaultApp extends StatelessWidget {
  const DropVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D528E),
          background: const Color(0xFFFEF7FD),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Color constants from the Tailwind config
  static const Color primaryColor = Colors.black;
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color surfaceContainer = Color(0xFFF3ECF2);
  static const Color primaryFixedDim = Color(0xFFD9B9FD);
  static const Color secondary = Color(0xFF8A4F39);
  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color primaryFixed = Color(0xFFEEDBFF);
  static const Color surfaceContainerHighest = Color(0xFFE7E0E6);
  static const Color tertiaryFixed = Color(0xFFFFDAD6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to scroll behind the transparent bottom nav
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingAndSearch(),
                const SizedBox(height: 40),
                _buildStatsAndActions(context),
                const SizedBox(height: 40),
                _buildRecentCollections(),
                const SizedBox(height: 40),
                _buildMainContentSplit(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFEF7FD),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryFixedDim, width: 2),
              image: const DecorationImage(
                image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBCUrDOGkC3r-bES4V5VFN5eNZi5QAxBexp11P5PfamldrPOh1epSucs4EREYGmUEJaycOQrXhg7Cjr5zV5Ph4j0uKY_BEven3gz8xCwKUb2vCJGqcnu3f4rUMaLpV9PhZR3U6fg5RA9xMFTN72ii8L7UHxcmEsU0qHYj9B36QBgsOW8FgBFzaRDzZNxi3mAfhBc45mBmI9bdFMGwKvld_93HXfDLwDNjTF55VE2FK4-pMCz6s_9UEjmE4HCAfTi2DmZqHnDomQYrCS'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Drop Vault',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87),
          onPressed: () {},
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildGreetingAndSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good Morning, Ajay',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your digital sanctuary is secure.',
          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search your vault...',
            hintStyle: const TextStyle(color: onSurfaceVariant),
            prefixIcon: const Icon(Icons.search, color: onSurfaceVariant),
            filled: true,
            fillColor: surfaceContainer,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.2), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsAndActions(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 768;

    Widget statsCards = Row(
      children: [
        Expanded(child: _buildStatCard('Total Items', '1,248', '+12 today', secondary)),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Collections', '25', null, null, showAvatars: true),
        ),
      ],
    );

    Widget quickActions = Row(
      children: [
        Expanded(child: _buildQuickAction(Icons.link, 'Add Link', secondaryContainer, const Color(0xFF79422D))),
        const SizedBox(width: 16),
        Expanded(child: _buildQuickAction(Icons.edit_note, 'New Note', primaryFixed, const Color(0xFF270B46))),
        const SizedBox(width: 16),
        Expanded(child: _buildQuickAction(Icons.upload_file, 'File', surfaceContainerHighest, const Color(0xFF1D1B1F))),
        const SizedBox(width: 16),
        Expanded(child: _buildQuickAction(Icons.image, 'Image', tertiaryFixed, const Color(0xFF390B09))),
      ],
    );

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
          // Wrap quick actions for mobile to make them 2x2 if preferred, 
          // or scrollable. Here we wrap them in rows for a grid feel.
          Row(
            children: [
              Expanded(child: _buildQuickAction(Icons.link, 'Add Link', secondaryContainer, const Color(0xFF79422D))),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickAction(Icons.edit_note, 'New Note', primaryFixed, const Color(0xFF270B46))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildQuickAction(Icons.upload_file, 'File', surfaceContainerHighest, const Color(0xFF1D1B1F))),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickAction(Icons.image, 'Image', tertiaryFixed, const Color(0xFF390B09))),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, String? subtitle, Color? subtitleColor, {bool showAvatars = false}) {
    return _GlassCard(
      height: 160,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: onSurfaceVariant),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor),
                ),
              if (showAvatars)
                Row(
                  children: [
                    _buildMiniAvatar(primaryFixed),
                    Transform.translate(offset: const Offset(-8, 0), child: _buildMiniAvatar(secondaryContainer)),
                    Transform.translate(offset: const Offset(-16, 0), child: _buildMiniAvatar(tertiaryFixed)),
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

  Widget _buildQuickAction(IconData icon, String label, Color bgColor, Color iconColor) {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCollections() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Recent Collections', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('VIEW ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          // Overflow rendering
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildCollectionCard('Interior Design', '48 Items', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCJIz1cEVlXNcG8QUipunDEw6E5q9Gm3Vhs0M_pthGNIRp9w9pBygSpf8RFWpZu3dY47ru0H9FUxhj8GfvtuWFj9-B2x4BKQ3_lbvX9sJfL3twLy_c5fS3BZ9CmnOYGU7el0x3Jilc3hDRBgxwT1ByAN0Jf2o4uVeffKShS1CkDAXBM-c4eBkWhRIyR3DI3id4K89ys11Q_bhla9kPiTFjMXt4bQah6CiJLOwCi47ArIQr33U0grLYFsodPhyaEgzJ658G_jZ75ycca'),
              const SizedBox(width: 16),
              _buildCollectionCard('Tech Projects', '126 Items', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCu5-ep2b69gGMwVgwr23mhSEimqWmy0M2q3pQNoct_Jc3zSSqGCtqt8-o7ghcYWxSRt6oaIQm9HHn2AIT3IAlknLsmRFkVcWxMcnzys83ETOoMBnI578o9evdskbyiWFL060qNTiAew5ortWR0cjKiGc1tPatqV7zjtztw9ATlVfg1gwAjkM8mvc-lin3QE_TxYat93aJmNzmEyNe29Uv3encJvnSxwmn3Q5QmW4xHCTwn73k1Kx71QsDe3PlFT7itDnmVT2DD8A__'),
              const SizedBox(width: 16),
              _buildCollectionCard('Travel Log', '32 Items', 'https://lh3.googleusercontent.com/aida-public/AB6AXuB48oe9c0KmOiGYsSMyj1ckxM7-LO6ZF90eEUgy7sDjeHoDok4R1quTMcisM9ewR3qJUbEDXXAjm11ocDHvocVUiRfj0wpVvviWB-sCXe8dSnRYIJq8uzqbQcFDOwpEgKHS5VYenUYuDf0TJ2YHwKmG05NoUysjPDfZRLCr93d_c9Vchk_zQQJ3vF3kWLmJXzM78f-4NWAw97LdndEPaUDy9an0TR-7oNJ7sh2jM7kdZMOvyXSz-DYcyHlPn_u-ZJeGTU_Iv_LJkuYB'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(String title, String subtitle, String imageUrl) {
    return _GlassCard(
      width: 256,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrl, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentSplit(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget recentItems = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRecentListItem('Q3 Financial Statement.pdf', 'Modified 2 hours ago • 4.2 MB', Icons.description, const Color(0xFF270B46), const Color(0xFFEEDBFF)),
        const SizedBox(height: 12),
        _buildRecentListItem('The Future of AI - Article', 'Saved from newsletter • today', Icons.link, const Color(0xFF79422D), const Color(0xFFFEB196)),
        const SizedBox(height: 12),
        _buildRecentListItem('Mountain_Retreat_Header.jpg', 'Uploaded today • 12 MB', Icons.image, const Color(0xFF390B09), const Color(0xFFFFDAD6)),
        const SizedBox(height: 12),
        _buildRecentListItem('Brainstorming Session Notes', 'Last edit yesterday', Icons.notes, const Color(0xFF1D1B1F), const Color(0xFFE7E0E6)),
      ],
    );

    Widget reminders = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6D528E).withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            children: [
              _buildReminderItem('TODAY, 2:00 PM', 'Renew Storage Plan', true),
              const SizedBox(height: 16),
              _buildReminderItem('TOMORROW', 'Review Security Audit', false),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: recentItems),
          const SizedBox(width: 40),
          Expanded(flex: 1, child: reminders),
        ],
      );
    } else {
      return Column(
        children: [
          recentItems,
          const SizedBox(height: 40),
          reminders,
        ],
      );
    }
  }

  Widget _buildRecentListItem(String title, String subtitle, IconData icon, Color iconColor, Color bgColor) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
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
                Text(subtitle, style: const TextStyle(fontSize: 12, color: onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: onSurfaceVariant),
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

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEF7FD).withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          padding: const EdgeInsets.only(bottom: 32, top: 16, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', isActive: true),
              _buildNavItem(Icons.search, 'Search'),
              _buildAddFabItem(),
              _buildNavItem(Icons.folder_copy, 'Collections'),
              _buildNavItem(Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? primaryColor : onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? primaryColor : onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAddFabItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text('', style: TextStyle(fontSize: 12)), // Spacer to align text baseline
      ],
    );
  }
}

// Reusable Glass Card Widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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