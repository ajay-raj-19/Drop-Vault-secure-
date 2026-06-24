Here is the equivalent Dart (Flutter) code for the **Drop Vault Account** page.

This implementation includes the responsive layout centering, the custom glassmorphism styling, the distinct gradient profiles, and the structured bento grid approach for statistics, while retaining the premium color palette derived from the provided HTML/Tailwind config.

### Dart (Flutter) Implementation

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultAccountApp());
}

class DropVaultAccountApp extends StatelessWidget {
  const DropVaultAccountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Account',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const AccountPage(),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Color Palette Constants
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color secondary = Color(0xFF8A4F39);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color outline = Color(0xFF7B757F);
  static const Color outlineVariant = Color(0xFFCCC4D0);
  
  // App specific gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE5958E), Color(0xFFD47A72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 40),
                _buildStatisticsGrid(),
                const SizedBox(height: 40),
                _buildAccountInformation(),
                const SizedBox(height: 40),
                _buildDangerZone(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: background.withOpacity(0.8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: outlineVariant.withOpacity(0.2))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: primary),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          hoverColor: const Color(0xFFEDE6EC).withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Account',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: primary),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      hoverColor: const Color(0xFFEDE6EC).withOpacity(0.5),
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

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDYRFdGWiAy_Q5TsfbYAhVh-EQnb7k6LrJnfy8WyrPiQNf4cGKKol-vRUT98VyIsVH5lHVd1483vwmeoQ4pr-UC8sfoyqbtkIVPHHb3Q36TBSsa1ho3FAt0FQjWVCpwwLcMfWdlHNsgRI9q7znLciBOoYclicgAADYWqPv2tcAr63Hf4tC2NxBVC6XUR6L75b5vtv822AHp68uTOh2xUPsDLG9Ey6BrArw-hp386-Z3Ahb4XskKIYlH1sTZPkv2MtXSZCeo-PD5M4PT'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Julianne Sterling',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
        ),
        const SizedBox(height: 4),
        const Text(
          'j.sterling@designvault.com',
          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          child: const Text('Edit Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('1,284', 'Saved Items')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('42', 'Collections')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('156', 'Favorites')),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primary, height: 1.1)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildAccountInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            'Account Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurfaceVariant),
          ),
        ),
        _GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildInfoRow(Icons.person, 'Display Name', 'Julianne Sterling', showDivider: true),
              _buildInfoRow(Icons.mail, 'Email Address', 'j.sterling@designvault.com', showDivider: true),
              _buildInfoRow(Icons.calendar_today, 'Join Date', 'October 14, 2023', showChevron: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showDivider = false, bool showChevron = true}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: showDivider ? Border(bottom: BorderSide(color: outlineVariant.withOpacity(0.1))) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: secondary),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(value, style: const TextStyle(fontSize: 16, color: onSurface)),
                    ],
                  ),
                ],
              ),
              if (showChevron)
                const Icon(Icons.chevron_right, color: outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            'Danger Zone',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: error),
          ),
        ),
        _GlassCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: onSurface),
                    SizedBox(width: 16),
                    Text('Logout', style: TextStyle(fontSize: 18, color: onSurface)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: errorContainer.withOpacity(0.1),
                border: Border.all(color: error.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.delete_forever, color: error),
                      SizedBox(width: 16),
                      Text('Delete Account', style: TextStyle(fontSize: 18, color: error)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('PERMANENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: error)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 32, top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D528E).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', false),
          _buildNavItem(Icons.search, 'Search', false),
          _buildAddFabItem(),
          _buildNavItem(Icons.folder_open, 'Vaults', false),
          _buildNavItem(Icons.person, 'Profile', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? primary : onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? primary : onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAddFabItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }
}

// Reusable Glass Card Widget
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
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
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D528E).withOpacity(0.05),
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

```