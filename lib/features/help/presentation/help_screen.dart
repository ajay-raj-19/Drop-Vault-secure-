import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get primaryText => context.appColors.primaryText;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get outlineVariant => context.appColors.border;

  Color get secondaryContainer => AppColors.secondaryContainer;
  Color get onSecondaryContainer => AppColors.onSecondaryContainer;
  Color get errorContainer => Theme.of(context).colorScheme.errorContainer;
  Color get onErrorContainer => Theme.of(context).colorScheme.onError;
  Color get primaryFixed => context.appColors.primaryFixed;
  Color get onPrimaryFixedVariant => AppColors.onPrimaryFixedVariant;

  @override
  void initState() {
    super.initState();
    // Replicating the 'ambient-float' CSS animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

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
            constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(),
                const SizedBox(height: 40),
                _buildFaqsSection(),
                const SizedBox(height: 40),
                _buildContactSection(),
                const SizedBox(height: 40),
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
                        icon: Icon(Icons.arrow_back, color: primary),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Help & Support',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: primary),
                    onPressed: () => context.go('/main/profile/settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 12,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Floating Illustration
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: child,
                    );
                  },
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC3J3pn9pWr-0ZaHePPpqmGzyRjsd4gfptUwyKqS6SN7y1_XdJ4hZBF24ya7yscUCR0K1RKCLHfJYtHui4F_vwfLhhaSt1WMCQoQn77F2wwXL3ZDXXiQTWqiai50BvkVNJib9CeD8KtFY6wUMDnXc2jjZf0SR4YJsgUgtjv3hy2tiCs_80_pP6anO2YRSxMSrV5POJYGpim-uNOx0FCvrWYoyHsGjtRiapQyho8cJStgtwP7yQT3U3upbDzE_a5eSPaSuQsZwgeR42B',
                    fit: BoxFit.cover,
                  ),
                ),
                // Glow Overlay (Subtle gradient overlay)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [const Color(0xFFD9B9FD).withOpacity(0.2), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
                // Bottom Fade
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [background.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'How can we help?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryText),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore our guide or reach out to our team for personalized assistance.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFaqsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'FAQS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: onSurfaceVariant),
          ),
        ),
        const _FaqCard(
          title: 'How to save links',
          content: "Simply tap the 'Add' button in the navigation bar and paste your URL. You can also share directly from your browser to Drop Vault using the share extension.",
        ),
        const SizedBox(height: 16),
        const _FaqCard(
          title: 'How collections work',
          content: 'Collections are smart folders designed to keep your vault organized. Create a collection, add a custom icon, and drag-and-drop your items into them for quick access.',
        ),
        const SizedBox(height: 16),
        const _FaqCard(
          title: 'How reminders work',
          content: "Set a notification for any item in your vault. We'll send you a gentle nudge at your specified time so you never forget to review that important link or note.",
        ),
      ],
    );
  }

  Future<void> _launchMail(String subject, String body) async {
    const String emailAddress = 'ajay.raj.cd24@ggits.net';
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email application found on this device.')),
          );
          _showFallbackDialog(emailAddress);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email application found on this device.')),
        );
        _showFallbackDialog(emailAddress);
      }
    }
  }

  void _showFallbackDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not open email application. Please email us directly at:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: email));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email copied successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, color: Colors.white),
            label: const Text('Copy Email'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'CONTACT SUPPORT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: onSurfaceVariant),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isMobile ? 3 : 1,
              children: [
                _buildContactCard(
                  Icons.mail,
                  'Email Support',
                  secondaryContainer,
                  onSecondaryContainer,
                  () => _launchMail(
                    'Drop Vault Support Request',
                    'Hello,\n\nI need help with:',
                  ),
                ),
                _buildContactCard(
                  Icons.bug_report,
                  'Report Bug',
                  errorContainer,
                  onErrorContainer,
                  () => _launchMail(
                    'Drop Vault Bug Report',
                    'Device:\n\nAndroid Version:\n\nApp Version:\n\nBug Description:\n\nSteps To Reproduce:',
                  ),
                ),
                _buildContactCard(
                  Icons.chat_bubble,
                  'Send Feedback',
                  primaryFixed,
                  onPrimaryFixedVariant,
                  () => _launchMail(
                    'Drop Vault Feedback',
                    'Feedback:',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactCard(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'About Drop Vault',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Drop Vault is your personal digital sanctuary, built to secure and organize your digital life. We believe in privacy, beautiful aesthetics, and seamless utility. Our mission is to empower you to capture what matters, without the clutter.',
            style: TextStyle(fontSize: 16, color: onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          Divider(color: outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Version 2.4.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
              GestureDetector(
                onTap: () => context.push('/main/profile/terms'),
                child: Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom FAQ Card utilizing ExpansionTile over a GlassCard
class _FaqCard extends StatelessWidget {
  final String title;
  final String content;

  const _FaqCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.appColors.primaryText),
          ),
          iconColor: context.appColors.primaryText,
          collapsedIconColor: context.appColors.primaryText,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          children: [
            Text(
              content,
              style: TextStyle(fontSize: 16, color: context.appColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
