import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class AboutDeveloperPage extends StatelessWidget {
  const AboutDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final outlineVariant = context.appColors.border;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: background.withValues(alpha: 0.8),
                border: Border(bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.2))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About Developer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 110, bottom: 40, left: 24, right: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Profile Avatar Photo Section (Circular style, centered)
                Center(
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF6D528E).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/developer.webp',
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                        errorBuilder: (ctx, err, st) => Container(
                          width: 140,
                          height: 140,
                          color: isDark ? const Color(0xFF242424) : const Color(0xFFF3ECF2),
                          child: Icon(
                            Icons.person,
                            size: 72,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Developer name and subtitle
                Text(
                  'Ajay Raj',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full Stack Developer & Data Science ',
                  style: TextStyle(fontSize: 16, color: onSurfaceVariant, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Main Info Glass Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio Section
                      Text(
                        'BIOGRAPHY',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'I am a passionate Full Stack Developer and Data Science student focused on building practical, user-friendly software solutions. I enjoy creating modern applications, exploring emerging technologies, and designing products that solve real-world problems. Drop Vault was created with the vision of providing users with a secure and organized digital space for managing their important content.',
                        style: TextStyle(fontSize: 15, color: onSurface, height: 1.5),
                      ),
                      
                      const SizedBox(height: 24),
                      Divider(color: outlineVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 24),

                      // Key details
                      _buildInfoItem(Icons.school_outlined, 'Institution', 'Gyan Ganga Institute of Technology and Sciences, Jabalpur MP', onSurface, onSurfaceVariant),
                      const SizedBox(height: 16),
                      _buildInfoItem(Icons.workspace_premium_outlined, 'Degree', 'B.Tech Data Science', onSurface, onSurfaceVariant),
                      const SizedBox(height: 16),
                      _buildInfoItem(Icons.psychology_outlined, 'Roles', 'Full Stack Developer\nFlutter Developer\nData Science ', onSurface, onSurfaceVariant),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value, Color textCol, Color subtitleCol) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subtitleCol, letterSpacing: 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, color: textCol, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
