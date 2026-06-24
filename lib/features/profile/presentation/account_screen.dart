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
import '../../../core/providers/providers.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  // Color Palette Constants resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get secondary => context.colorScheme.secondary;
  Color get error => Theme.of(context).colorScheme.error;
  Color get errorContainer => Theme.of(context).colorScheme.errorContainer;
  Color get outline => context.appColors.mutedText;
  Color get outlineVariant => context.appColors.border;
  
  // App specific gradients
  static const LinearGradient accentGradient = AppColors.accentGradient;

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Safely delete this account via the auth provider
      await ref.read(authStateProvider.notifier).deleteAccount(user.email);
      
      if (mounted) {
        // Pop loading dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        // Pop loading dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    final textController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Type DELETE to continue.'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type DELETE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    canDelete = val == 'DELETE';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: canDelete
                  ? () async {
                      Navigator.pop(ctx);
                      await _deleteAccount();
                    }
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final fullName = user?.fullName ?? 'User';
    final joinDate = user?.joinDate ?? DateTime.now();

    final savedItemsCount = ref.watch(vaultProvider).length;
    final collectionsCount = ref.watch(collectionProvider).length;
    final favoritesCount = ref.watch(vaultProvider).where((item) => item.tags.any((t) => t.toLowerCase() == 'favorite' || t.toLowerCase() == 'fav')).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                _buildProfileHeader(displayName, email),
                const SizedBox(height: 40),
                _buildStatisticsGrid(savedItemsCount, collectionsCount, favoritesCount),
                const SizedBox(height: 40),
                _buildAccountInformation(fullName, displayName, email, joinDate),
                const SizedBox(height: 40),
                _buildDangerZone(),
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
                        icon: Icon(Icons.arrow_back, color: primary),
                        onPressed: () => context.pop(),
                        style: IconButton.styleFrom(
                          hoverColor: onSurfaceVariant.withOpacity(0.08),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Account',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: primary),
                    onPressed: () => context.go('/main/profile/settings'),
                    style: IconButton.styleFrom(
                      hoverColor: onSurfaceVariant.withOpacity(0.08),
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

  Widget _buildProfileHeader(String displayName, String email) {
    final profileImageWidget = UserAvatar(
      size: 128,
      borderRadius: 24,
      border: Border.all(color: Colors.white, width: 4),
    );
    return Column(
      children: [
        Stack(
          children: [
            profileImageWidget,
            Positioned(
              bottom: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => context.go('/main/profile/edit-profile'),
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
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.go('/main/profile/edit-profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          child: const Text('Edit Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(int savedItems, int collections, int favorites) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('$savedItems', 'Saved Items')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('$collections', 'Collections')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('$favorites', 'Favorites')),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      borderRadius: 16,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primary, height: 1.1),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInformation(String fullName, String displayName, String email, DateTime joinDate) {
    final dateStr = _formatDate(joinDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            'Account Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurfaceVariant),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: Column(
            children: [
              _buildInfoRow(Icons.badge, 'Full Name', fullName, showDivider: true, showChevron: false),
              _buildInfoRow(
                Icons.person, 
                'Display Name', 
                displayName, 
                showDivider: true, 
                showChevron: true, 
                onTap: () => context.go('/main/profile/edit-profile')
              ),
              _buildInfoRow(Icons.mail, 'Email Address', email, showDivider: true, showChevron: false),
              _buildInfoRow(Icons.calendar_today, 'Join Date', dateStr, showChevron: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showDivider = false, bool showChevron = true, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: showDivider ? Border(bottom: BorderSide(color: outlineVariant.withOpacity(0.1))) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: secondary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: TextStyle(fontSize: 16, color: onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showChevron)
                Icon(Icons.chevron_right, color: outline),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            'Danger Zone',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: error),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await ref.read(authStateProvider.notifier).signOut();
                if (mounted) {
                  context.go('/login');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: onSurface),
                    const SizedBox(width: 16),
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
            onTap: _showDeleteAccountDialog,
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
                  Row(
                    children: [
                      Icon(Icons.delete_forever, color: error),
                      const SizedBox(width: 16),
                      Text('Delete Account', style: TextStyle(fontSize: 18, color: error)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('PERMANENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
