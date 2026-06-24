import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultRemindersApp());
}

class DropVaultRemindersApp extends StatelessWidget {
  const DropVaultRemindersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Reminders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.transparent, // Background handled by container
        primaryColor: Colors.black,
      ),
      home: const RemindersPage(),
    );
  }
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with SingleTickerProviderStateMixin {
  // Theme Colors
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color outlineVariant = Color(0xFFCCC4D0);
  
  static const Color primaryContainer = Color(0xFF270B46);
  static const Color onPrimaryContainer = Color(0xFF9477B6);
  static const Color surfaceContainerLow = Color(0xFFF8F2F7);
  static const Color surfaceContainerHigh = Color(0xFFEDE6EC);
  static const Color surfaceContainerHighest = Color(0xFFE7E0E6);
  
  static const Color secondaryFixed = Color(0xFFFFDBCF);
  static const Color onSecondaryFixed = Color(0xFF370E01);
  static const Color tertiaryFixed = Color(0xFFFFDAD6);
  static const Color onTertiaryFixed = Color(0xFF390B09);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  bool _isUpcomingTab = true;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: background,
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            Color(0x33E5958E),
            Colors.transparent,
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.5,
            colors: [
              Color(0x11210440),
              Colors.transparent,
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: Scaffold(
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
                    _buildTabs(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isUpcomingTab ? _buildUpcomingList() : _buildCompletedState(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
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
                        'Reminders',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: onSurface),
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

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Upcoming', true),
          ),
          Expanded(
            child: _buildTabButton('Completed', false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isUpcoming) {
    final isActive = _isUpcomingTab == isUpcoming;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isUpcomingTab = isUpcoming;
          });
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? onPrimaryContainer : onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingList() {
    return Column(
      key: const ValueKey('upcoming'),
      children: [
        _buildReminderCard(
          tagLabel: 'Work Documents',
          tagBg: secondaryFixed,
          tagText: onSecondaryFixed,
          title: 'Review Project Alpha Vault',
          date: 'Oct 24, 2023 • 10:00 AM',
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 16),
        _buildReminderCard(
          tagLabel: 'Financials',
          tagBg: tertiaryFixed,
          tagText: onTertiaryFixed,
          title: 'Renew Subscription Box',
          date: 'In 2 days • 04:30 PM',
          icon: Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildReminderCard({
    required String tagLabel,
    required Color tagBg,
    required Color tagText,
    required String title,
    required String date,
    required IconData icon,
  }) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(16)),
                    child: Text(tagLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tagText)),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface)),
                ],
              ),
              IconButton(icon: const Icon(Icons.more_vert, color: onSurfaceVariant), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, size: 18, color: onSurfaceVariant),
              const SizedBox(width: 8),
              Text(date, style: const TextStyle(fontSize: 14, color: onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {},
                    style: IconButton.styleFrom(foregroundColor: onSurfaceVariant, hoverColor: surfaceContainerHighest),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {},
                    style: IconButton.styleFrom(foregroundColor: error, hoverColor: errorContainer.withOpacity(0.5)),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Complete'),
                style: TextButton.styleFrom(
                  foregroundColor: onSurface,
                  backgroundColor: surfaceContainerHigh,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) return primaryContainer;
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) return onPrimaryContainer;
                    return onSurface;
                  }),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCompletedState() {
    return Column(
      key: const ValueKey('completed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          width: 192,
          height: 192,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: surfaceContainerHigh.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCoBQwIVYC5u0oBu24ve4SgHEotx4o0t2RDC9UTtMal6cmrSyOEbble-rxJGrIWp3ClyUX85KLZVW59iqMMJA01zhiGgH5AmrPOoxAVyM0eM8z8a-xSfAgsZNhDhhzAJUp_WDGvZl80NdD16xiXDm0qH26QLLiG1cmscRVe3rv-kQh-KueTDz-KRVtxpmcJAVEZgot5YuladHzlaEy7E8c1RpYlk7iPAEoQsVVAaIdESjMocwYYk_XH3g8miS8mHC2vq-4_wIm-CAX-',
                    fit: BoxFit.contain,
                    color: Colors.white.withOpacity(0.2), // mix-blend-multiply approximation
                    colorBlendMode: BlendMode.dstIn,
                  ),
                ),
              ),
              RotationTransition(
                turns: _spinController,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: outlineVariant.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  // Using CustomPaint for dashed border would be better here in a full app
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Everything\'s Cleared', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No completed reminders yet. Tasks you finish will appear here for your records.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isUpcomingTab = true;
            });
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Upcoming', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
      ],
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
              _buildNavItem(Icons.folder_open, 'Vaults', true), // Assuming active for this context based on HTML
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