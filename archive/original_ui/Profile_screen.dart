import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultProfileApp());
}

class DropVaultProfileApp extends StatelessWidget {
  const DropVaultProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Profile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD), // background
        primaryColor: Colors.black,
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Tailwind Theme Colors
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color surfaceVariant = Color(0xFFE7E0E6);
  static const Color secondary = Color(0xFF8A4F39);
  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color outlineVariant = Color(0xFFCCC4D0);

  // Menu Icon Colors
  static const Color primaryFixed = Color(0xFFEEDBFF);
  static const Color onPrimaryFixed = Color(0xFF270B46);
  static const Color secondaryFixed = Color(0xFFFFDBCF);
  static const Color onSecondaryFixed = Color(0xFF370E01);
  static const Color tertiaryFixed = Color(0xFFFFDAD6);
  static const Color onTertiaryFixed = Color(0xFF390B09);
  static const Color primaryContainer = Color(0xFF270B46);
  static const Color onPrimaryContainer = Color(0xFF9477B6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512), // max-w-lg
          child: ListView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 40),
              _buildStorageCard(),
              const SizedBox(height: 24),
              _buildMenuNav(),
              const SizedBox(height: 40),
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: background.withOpacity(0.8),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: const Text(
        'Drop Vault',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: onSurface),
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: onSurfaceVariant.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                ],
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCuuxR85Su-5RPCcp62I6JWwcu7yMzThl3zvCmYmetb6pjYNDDnOhH1vCFTexgAXp-p7i_UkTxU1M1P1c4TTnPX10BuMoVp48UPDhAyD8IlxNrqL7caLb2lc0WkULlitU0F88wgpQJcgXd8pQhj_7fM_02qERfSJhzntwDs_oUNqap9Sm_XkkZW0R-8Gz-XsDylTlqcLA2qXoXroFEyNHi05ORJU40yeJjaFGoJEioUR7uESzqdGjlKMABqQGyOjfgrw5oK_SqQgU85'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.edit, size: 16, color: onPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Ajay Singh',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
        ),
      ],
    );
  }

  Widget _buildStorageCard() {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Storage Used', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      text: '2.45 GB ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
                      children: [
                        TextSpan(
                          text: '/ 10 GB',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Text('24%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(color: surfaceVariant, borderRadius: BorderRadius.circular(5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.24,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(colors: [secondary, secondaryContainer]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuNav() {
    return Column(
      children: [
        _buildMenuItem('Account', Icons.person, primaryFixed, onPrimaryFixed),
        const SizedBox(height: 12),
        _buildMenuItem('Settings', Icons.settings, secondaryFixed, onSecondaryFixed),
        const SizedBox(height: 12),
        _buildMenuItem('Reminders', Icons.notifications, tertiaryFixed, onTertiaryFixed),
        const SizedBox(height: 12),
        _buildMenuItem('Trash', Icons.delete, surfaceVariant, onSurfaceVariant),
        const SizedBox(height: 12),
        _buildMenuItem('Help & Support', Icons.help, primaryContainer, onPrimaryContainer),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, Color iconBgColor, Color iconColor) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
            ],
          ),
          const Icon(Icons.chevron_right, color: onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: secondary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {},
          child: const Center(
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onPrimary),
            ),
          ),
        ),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.home, color: Colors.grey),
              const Icon(Icons.search, color: Colors.grey),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: primary, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: onPrimary),
              ),
              const Icon(Icons.folder_copy, color: Colors.grey),
              const Icon(Icons.person, color: primary), // Active Tab
            ],
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
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF553A75).withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}