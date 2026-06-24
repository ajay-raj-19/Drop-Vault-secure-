import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultSettingsApp());
}

class DropVaultSettingsApp extends StatelessWidget {
  const DropVaultSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Settings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black;
            }
            return const Color(0xFFCCC4D0); // outline-variant
          }),
        ),
      ),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Theme Colors
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color surfaceContainerHighest = Color(0xFFE7E0E6);
  static const Color outline = Color(0xFF7B757F);
  static const Color outlineVariant = Color(0xFFCCC4D0);

  // App specific palette
  static const Color secondaryFixed = Color(0xFFFFDBCF);
  static const Color onSecondaryFixed = Color(0xFF370E01);
  static const Color primaryFixedDim = Color(0xFFD9B9FD);
  static const Color onPrimaryFixedVariant = Color(0xFF553A75);
  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color onSecondaryContainer = Color(0xFF79422D);

  // Toggle States
  bool _notificationsEnabled = true;
  bool _remindersEnabled = false;
  bool _autoSyncEnabled = true;

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
            constraints: const BoxConstraints(maxWidth: 768), // max-w-3xl
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppearanceSection(),
                const SizedBox(height: 24),
                _buildNotificationsSection(),
                const SizedBox(height: 24),
                _buildSyncSection(),
                const SizedBox(height: 24),
                _buildPrivacySection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
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
                        icon: const Icon(Icons.arrow_back, color: onSurface),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: onSurface),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _SettingsSection(
      title: 'APPEARANCE',
      children: [
        _SettingsTile(
          icon: Icons.light_mode,
          iconBgColor: secondaryFixed,
          iconColor: onSecondaryFixed,
          title: 'Light Mode',
          trailing: const Icon(Icons.check_circle, color: primary),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.dark_mode,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Dark Mode',
          trailing: const Icon(Icons.radio_button_unchecked, color: outline),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _SettingsSection(
      title: 'NOTIFICATIONS',
      children: [
        _SettingsTile(
          icon: Icons.notifications,
          iconBgColor: primaryFixedDim,
          iconColor: onPrimaryFixedVariant,
          title: 'Enable Notifications',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
        ),
        _SettingsTile(
          icon: Icons.alarm,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Reminder Notifications',
          trailing: Switch(
            value: _remindersEnabled,
            onChanged: (val) => setState(() => _remindersEnabled = val),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSection() {
    return _SettingsSection(
      title: 'SYNC',
      children: [
        _SettingsTile(
          icon: Icons.sync,
          iconBgColor: secondaryContainer,
          iconColor: onSecondaryContainer,
          title: 'Auto Sync',
          trailing: Switch(
            value: _autoSyncEnabled,
            onChanged: (val) => setState(() => _autoSyncEnabled = val),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _SettingsSection(
      title: 'PRIVACY',
      children: [
        _SettingsTile(
          icon: Icons.policy,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Privacy Policy',
          trailing: const Icon(Icons.chevron_right, color: outline),
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.gavel,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Terms of Service',
          trailing: const Icon(Icons.chevron_right, color: outline),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _SettingsSection(
      title: 'ABOUT',
      children: [
        _SettingsTile(
          icon: Icons.info,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'App Version',
          trailing: const Text('v2.4.1-stable', style: TextStyle(color: onSurfaceVariant)),
          onTap: () {}, // Optional, kept non-interactive like HTML
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
          _buildNavItem(Icons.person, 'Profile', true), // Settings is implicitly under Profile in this design
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
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    );
  }
}

// Reusable Section Wrapper
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _SettingsPageState.onSurfaceVariant,
            ),
          ),
        ),
        _GlassCard(
          padding: const EdgeInsets.all(8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// Reusable Settings Tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: _SettingsPageState.onSurface),
                  ),
                ],
              ),
              trailing,
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
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCC4D0).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}