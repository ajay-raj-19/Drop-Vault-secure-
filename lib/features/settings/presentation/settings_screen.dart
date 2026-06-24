import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/user_avatar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get surfaceContainerHighest => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.secondaryBackground
      : const Color(0xFFE7E0E6);
  Color get outline => context.appColors.mutedText;
  Color get outlineVariant => context.appColors.border;

  // App specific palette
  Color get secondaryFixed => context.appColors.secondaryFixed;
  Color get onSecondaryFixed => context.appColors.onSecondaryFixed;
  Color get primaryFixedDim => context.appColors.primaryFixedDim;
  Color get onPrimaryFixedVariant => AppColors.onPrimaryFixedVariant;
  Color get secondaryContainer => AppColors.secondaryContainer;
  Color get onSecondaryContainer => AppColors.onSecondaryContainer;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                _buildBackupSection(),
                const SizedBox(height: 24),
                _buildPrivacySection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: null, // Managed by MainLayoutShell
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: background.withOpacity(0.8),
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
                        icon: Icon(Icons.arrow_back, color: onSurface),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.help_outline, color: onSurface),
                        onPressed: () => context.go('/main/profile/help'),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.go('/main/profile'),
                        child: const UserAvatar(size: 32, borderRadius: 16),
                      ),
                    ],
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
    final themeMode = ref.watch(themeModeProvider);

    return _SettingsSection(
      title: 'APPEARANCE',
      children: [
        _SettingsTile(
          icon: Icons.light_mode,
          iconBgColor: secondaryFixed,
          iconColor: onSecondaryFixed,
          title: 'Light Mode',
          trailing: Icon(
            themeMode == ThemeMode.light ? Icons.check_circle : Icons.radio_button_unchecked,
            color: themeMode == ThemeMode.light ? primary : outline,
          ),
          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
        ),
        _SettingsTile(
          icon: Icons.dark_mode,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Dark Mode',
          trailing: Icon(
            themeMode == ThemeMode.dark ? Icons.check_circle : Icons.radio_button_unchecked,
            color: themeMode == ThemeMode.dark ? primary : outline,
          ),
          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    final settings = ref.watch(userSettingsProvider);
    return _SettingsSection(
      title: 'NOTIFICATIONS',
      children: [
        _SettingsTile(
          icon: Icons.notifications,
          iconBgColor: primaryFixedDim,
          iconColor: onPrimaryFixedVariant,
          title: 'Enable Notifications',
          trailing: Switch(
            value: settings.notificationsEnabled,
            onChanged: (val) => ref.read(userSettingsProvider.notifier).updateSettings(notificationsEnabled: val),
          ),
        ),
        _SettingsTile(
          icon: Icons.alarm,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Reminder Notifications',
          trailing: Switch(
            value: settings.remindersEnabled,
            onChanged: (val) => ref.read(userSettingsProvider.notifier).updateSettings(remindersEnabled: val),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSection() {
    final settings = ref.watch(userSettingsProvider);
    return _SettingsSection(
      title: 'SYNC',
      children: [
        _SettingsTile(
          icon: Icons.sync,
          iconBgColor: secondaryContainer,
          iconColor: onSecondaryContainer,
          title: 'Auto Sync',
          trailing: Switch(
            value: settings.autoSyncEnabled,
            onChanged: (val) => ref.read(userSettingsProvider.notifier).updateSettings(autoSyncEnabled: val),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return _SettingsSection(
      title: 'BACKUP & RESTORE',
      children: [
        _SettingsTile(
          icon: Icons.backup,
          iconBgColor: primaryFixedDim,
          iconColor: onPrimaryFixedVariant,
          title: 'Export & Backup Data',
          trailing: Icon(Icons.chevron_right, color: outline),
          onTap: () => context.push('/main/profile/backup'),
        ),
        _SettingsTile(
          icon: Icons.restore,
          iconBgColor: secondaryFixed,
          iconColor: onSecondaryFixed,
          title: 'Restore from Backup',
          trailing: Icon(Icons.chevron_right, color: outline),
          onTap: () => context.push('/main/profile/backup'),
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
          trailing: Icon(Icons.chevron_right, color: outline),
          onTap: () => context.push('/main/profile/privacy-policy'),
        ),
        _SettingsTile(
          icon: Icons.gavel,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Terms of Service',
          trailing: Icon(Icons.chevron_right, color: outline),
          onTap: () => context.push('/main/profile/terms'),
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
          trailing: Text('v2.4.1-stable', style: TextStyle(color: onSurfaceVariant)),
          onTap: () {},
        ),
      ],
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: context.appColors.secondaryText,
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(8),
          borderRadius: 16,
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
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 16, color: context.appColors.primaryText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
