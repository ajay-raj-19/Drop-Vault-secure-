import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultTrashApp());
}

class DropVaultTrashApp extends StatelessWidget {
  const DropVaultTrashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Trash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const TrashPage(),
    );
  }
}

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  // Theme Colors based on the provided Tailwind config
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color surfaceContainerLow = Color(0xFFF8F2F7);
  static const Color surfaceContainerHighest = Color(0xFFE7E0E6);
  static const Color outline = Color(0xFF7B757F);
  static const Color outlineVariant = Color(0xFFCCC4D0);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color secondary = Color(0xFF8A4F39);
  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color secondaryFixed = Color(0xFFFFDBCF);
  static const Color onSecondaryFixedVariant = Color(0xFF6D3824);
  
  static const Color primaryContainer = Color(0xFF270B46);
  static const Color onPrimaryContainer = Color(0xFF9477B6);
  
  static const Color tertiaryFixed = Color(0xFFFFDAD6);
  static const Color onTertiaryFixedVariant = Color(0xFF703531);

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWarningCard(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildTrashList(),
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
                          hoverColor: surfaceContainerHighest.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Trash',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'Empty Trash',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
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

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: secondaryFixed.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: secondaryContainer.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-deletion enabled',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSecondaryFixedVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Items in the trash will be permanently deleted after 30 days. Restored items will return to their original vaults.',
                  style: TextStyle(fontSize: 16, color: onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search deleted items...',
          hintStyle: TextStyle(color: outlineVariant, fontSize: 16),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(Icons.search, color: outline),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: primary.withOpacity(0.1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildTrashList() {
    return Column(
      children: [
        _buildTrashItem(
          icon: Icons.link,
          iconBgColor: primaryContainer.withOpacity(0.1),
          iconColor: onPrimaryContainer,
          title: 'Architecture Inspo 2024',
          deletedText: 'Deleted 2 days ago',
          daysLeft: '28 days left',
          badgeColor: tertiaryFixed,
          badgeTextColor: onTertiaryFixedVariant,
        ),
        const SizedBox(height: 12),
        _buildTrashItem(
          icon: Icons.description,
          iconBgColor: secondaryContainer.withOpacity(0.1),
          iconColor: secondary,
          title: 'Product Roadmap Q4',
          deletedText: 'Deleted 15 days ago',
          daysLeft: '15 days left',
          badgeColor: tertiaryFixed,
          badgeTextColor: onTertiaryFixedVariant,
        ),
        const SizedBox(height: 12),
        _buildTrashItem(
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD9S_5jZNzDuabXiEYHTgprUz4TEuY0P9YewfQK0OftjSRsaQrRU_5UST9C3uJdfUqJ_Gus5pd7SKlVuOfKyzxlesrq6iiLK0gldwYWW_WSPkOshLck0rKzSdF-wKWjbUntQFYOhnqU6zntjA7V53HTcYwS3loDEAJa_XFDXf_ykpqb8yU0q5dIx0Dk_xxmpehfQwWGyOskWBifWGO7EhGFD2MjtNwEQZXm25wbG_3vrcSgCOn6hvvix2vbbGfrloNgRgrkB313OfR9',
          title: 'Hero_Visual_Final.png',
          deletedText: 'Deleted 27 days ago',
          daysLeft: '3 days left',
          badgeColor: errorContainer,
          badgeTextColor: onErrorContainer,
          isUrgent: true,
        ),
        const SizedBox(height: 12),
        _buildTrashItem(
          icon: Icons.picture_as_pdf,
          iconBgColor: surfaceContainerHighest,
          iconColor: onSurfaceVariant,
          title: 'Tax_Returns_2023.pdf',
          deletedText: 'Deleted 5 days ago',
          daysLeft: '25 days left',
          badgeColor: tertiaryFixed,
          badgeTextColor: onTertiaryFixedVariant,
        ),
      ],
    );
  }

  Widget _buildTrashItem({
    IconData? icon,
    String? imageUrl,
    Color? iconBgColor,
    Color? iconColor,
    required String title,
    required String deletedText,
    required String daysLeft,
    required Color badgeColor,
    required Color badgeTextColor,
    bool isUrgent = false,
  }) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 500;
          
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon / Image
              if (imageUrl != null)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineVariant.withOpacity(0.3)),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.white, size: 24),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor!.withOpacity(0.2)),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
              const SizedBox(width: 16),
              
              // Title & Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(deletedText, style: const TextStyle(fontSize: 14, color: outline)),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: outlineVariant, shape: BoxShape.circle)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isUrgent ? Icons.warning : Icons.timer, size: 14, color: badgeTextColor),
                              const SizedBox(width: 4),
                              Text(daysLeft, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.settings_backup_restore, size: 20, color: onSurfaceVariant),
                label: const Text('Restore', style: TextStyle(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_forever, size: 24, color: outline),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  hoverColor: errorContainer.withOpacity(0.5),
                  foregroundColor: error,
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                content,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: content),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
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
              _buildNavItem(Icons.person, 'Profile', false),
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
        Icon(icon, color: isActive ? primary : outline),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? primary : outline,
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
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}