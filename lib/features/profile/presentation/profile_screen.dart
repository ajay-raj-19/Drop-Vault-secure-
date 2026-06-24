import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onPrimary => Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get surfaceVariant => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.secondaryBackground
      : const Color(0xFFE7E0E6);
  Color get secondary => context.colorScheme.secondary;
  Color get secondaryContainer => context.appColors.secondaryFixed;
  Color get outlineVariant => context.appColors.border;

  // Menu Icon Colors
  Color get primaryFixed => context.appColors.primaryFixed;
  Color get onPrimaryFixed => context.appColors.onPrimaryFixed;
  Color get secondaryFixed => context.appColors.secondaryFixed;
  Color get onSecondaryFixed => context.appColors.onSecondaryFixed;
  Color get tertiaryFixed => context.appColors.tertiaryFixed;
  Color get onTertiaryFixed => context.appColors.onTertiaryFixed;
  Color get primaryContainer => const Color(0xFF270B46);
  Color get onPrimaryContainer => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFEEDBFF)
      : const Color(0xFF9477B6);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'Ajay Singh';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512), // max-w-lg
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 800));
              await ref.read(authStateProvider.notifier).reloadSession();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 100, bottom: 120),
              children: [
                _buildProfileHeader(displayName),
                const SizedBox(height: 40),
                _buildMenuNav(),
                const SizedBox(height: 40),
                _buildSignOutButton(),
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
                  Text(
                    'Drop Vault',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: onSurface),
                    onPressed: () => context.go('/main/profile/settings'),
                    style: IconButton.styleFrom(
                      backgroundColor: onSurfaceVariant.withOpacity(0.1),
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

  Widget _buildProfileHeader(String displayName) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.go('/main/profile/edit-profile'),
          child: Stack(
            children: [
              UserAvatar(
                size: 96,
                borderRadius: 48,
                border: Border.all(color: Colors.white, width: 4),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(Icons.edit, size: 16, color: onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
        ),
      ],
    );
  }

  Widget _buildMenuNav() {
    return Column(
      children: [
        _buildMenuItem('Account', Icons.person, primaryFixed, onPrimaryFixed, '/main/profile/account'),
        const SizedBox(height: 12),
        _buildMenuItem('Settings', Icons.settings, secondaryFixed, onSecondaryFixed, '/main/profile/settings'),
        const SizedBox(height: 12),
        _buildMenuItem('Reminders', Icons.notifications, tertiaryFixed, onTertiaryFixed, '/main/profile/reminder'),
        const SizedBox(height: 12),
        _buildMenuItem('Trash', Icons.delete, surfaceVariant, onSurfaceVariant, '/main/profile/trash'),
        const SizedBox(height: 12),
        _buildMenuItem('Help & Support', Icons.help, primaryContainer, onPrimaryContainer, '/main/profile/help'),
        const SizedBox(height: 12),
        _buildMenuItem('About Developer', Icons.info_outline, secondaryFixed, onSecondaryFixed, '/main/profile/about-developer'),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, Color iconBgColor, Color iconColor, String routePath) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(routePath),
        borderRadius: BorderRadius.circular(12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: secondary.withOpacity(isDark ? 0.4 : 0.2), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            ref.read(authStateProvider.notifier).signOut();
            context.go('/login');
          },
          child: Center(
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
