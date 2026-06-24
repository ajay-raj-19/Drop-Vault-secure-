import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultHelpApp());
}

class DropVaultHelpApp extends StatelessWidget {
  const DropVaultHelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Help & Support',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const HelpSupportPage(),
    );
  }
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> with SingleTickerProviderStateMixin {
  // Theme Colors based on the Tailwind config
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color primaryText = Color(0xFF210440);
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color outlineVariant = Color(0xFFCCC4D0);

  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color onSecondaryContainer = Color(0xFF79422D);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primaryFixed = Color(0xFFEEDBFF);
  static const Color onPrimaryFixedVariant = Color(0xFF553A75);

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

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
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Help & Support',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: primary),
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

  Widget _buildHeroSection() {
    return Column(
      children: [
        _GlassCard(
          padding: EdgeInsets.zero,
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
        const Text(
          'How can we help?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryText),
        ),
        const SizedBox(height: 8),
        const Text(
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
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'FAQS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: onSurfaceVariant),
          ),
        ),
        _FaqCard(
          title: 'How to save links',
          content: "Simply tap the 'Add' button in the navigation bar and paste your URL. You can also share directly from your browser to Drop Vault using the share extension.",
        ),
        const SizedBox(height: 16),
        _FaqCard(
          title: 'How collections work',
          content: 'Collections are smart folders designed to keep your vault organized. Create a collection, add a custom icon, and drag-and-drop your items into them for quick access.',
        ),
        const SizedBox(height: 16),
        _FaqCard(
          title: 'How reminders work',
          content: "Set a notification for any item in your vault. We'll send you a gentle nudge at your specified time so you never forget to review that important link or note.",
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
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
                _buildContactCard(Icons.mail, 'Email Support', secondaryContainer, onSecondaryContainer),
                _buildContactCard(Icons.bug_report, 'Report Bug', errorContainer, onErrorContainer),
                _buildContactCard(Icons.chat_bubble, 'Send Feedback', primaryFixed, onPrimaryFixedVariant),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactCard(IconData icon, String label, Color bgColor, Color iconColor) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {},
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return _GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: primary, size: 28),
              SizedBox(width: 12),
              Text(
                'About Drop Vault',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Drop Vault is your personal digital sanctuary, built to secure and organize your digital life. We believe in privacy, beautiful aesthetics, and seamless utility. Our mission is to empower you to capture what matters, without the clutter.',
            style: TextStyle(fontSize: 16, color: onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Version 2.4.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
              GestureDetector(
                onTap: () {},
                child: const Text(
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
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              _buildNavItem(Icons.folder_open, 'Vaults', false),
              _buildNavItem(Icons.person, 'Profile', true), // Assuming active contextually
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
}

// Custom FAQ Card utilizing ExpansionTile over a GlassCard
class _FaqCard extends StatelessWidget {
  final String title;
  final String content;

  const _FaqCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HelpSupportPage.primaryText),
          ),
          iconColor: HelpSupportPage.primaryText,
          collapsedIconColor: HelpSupportPage.primaryText,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          children: [
            Text(
              content,
              style: const TextStyle(fontSize: 16, color: HelpSupportPage.onSurfaceVariant),
            ),
          ],
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
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
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