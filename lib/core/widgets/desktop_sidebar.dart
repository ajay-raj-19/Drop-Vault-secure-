import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'user_avatar.dart';

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final outlineVariant = context.appColors.border;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    // Get current location path
    final GoRouterState routerState = GoRouterState.of(context);
    final location = routerState.matchedLocation;

    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'email@example.com';

    Widget buildMenuItem({
      required IconData icon,
      required String label,
      required String routePath,
      required bool isActive,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          onTap: () => context.go(routePath),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isActive
                  ? (isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF210440), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? Colors.white : onSurface,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 260,
      color: isDark ? const Color(0xFF131316) : scaffoldBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Branding Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.admin_panel_settings, color: primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Drop Vault',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Add Item Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/main/add'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add New Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildMenuItem(
                      icon: Icons.home,
                      label: 'Home',
                      routePath: '/main/dashboard',
                      isActive: location == '/main/dashboard',
                    ),
                    buildMenuItem(
                      icon: Icons.search,
                      label: 'Search',
                      routePath: '/main/search',
                      isActive: location == '/main/search',
                    ),
                    buildMenuItem(
                      icon: Icons.folder_copy,
                      label: 'Collections',
                      routePath: '/main/vault',
                      isActive: location == '/main/vault' || location.startsWith('/collection/'),
                    ),
                    buildMenuItem(
                      icon: Icons.star,
                      label: 'Favorites',
                      routePath: '/main/profile/favorites',
                      isActive: location == '/main/profile/favorites',
                    ),
                    buildMenuItem(
                      icon: Icons.alarm,
                      label: 'Reminders',
                      routePath: '/main/profile/reminder',
                      isActive: location == '/main/profile/reminder',
                    ),
                    buildMenuItem(
                      icon: Icons.delete_outline,
                      label: 'Trash',
                      routePath: '/main/profile/trash',
                      isActive: location == '/main/profile/trash',
                    ),
                    buildMenuItem(
                      icon: Icons.person,
                      label: 'Profile',
                      routePath: '/main/profile',
                      isActive: location == '/main/profile' || location == '/main/profile/account' || location == '/main/profile/edit-profile',
                    ),
                    buildMenuItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      routePath: '/main/profile/settings',
                      isActive: location == '/main/profile/settings',
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: outlineVariant.withValues(alpha: 0.2)),

            // User Identity & Sign Out Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/main/profile'),
                    child: const UserAvatar(size: 40, borderRadius: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/main/profile'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: onSurfaceVariant, size: 18),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    tooltip: 'Sign Out',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
