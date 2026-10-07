import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/connection_helper.dart';

class StartupLoadingPage extends ConsumerStatefulWidget {
  const StartupLoadingPage({super.key});

  @override
  ConsumerState<StartupLoadingPage> createState() => _StartupLoadingPageState();
}

class _StartupLoadingPageState extends ConsumerState<StartupLoadingPage> {
  @override
  void initState() {
    super.initState();
    _checkOfflineStatus();
  }

  Future<void> _checkOfflineStatus() async {
    // Check internet availability at startup
    bool isOffline = false;
    try {
      final result = await checkInternetConnection();
      isOffline = !result;
    } catch (_) {
      isOffline = true;
    }
    if (mounted) {
      ref.read(isOfflineProvider.notifier).state = isOffline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: Stack(
          children: [
            // Ambient background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.darkPurpleRoseGradient,
              ),
            ),

            // Soft glowing ambient orbs
            Positioned(
              top: screenSize.height * 0.2,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfffeb196).withValues(alpha: 0.12),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.2,
              right: -80,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffeedbff).withValues(alpha: 0.08),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),

            // Central Loading Card
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: GlassCard(
                    padding: const EdgeInsets.all(32),
                    borderRadius: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Security Icon container
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.security,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Drop Vault',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Checking Authentication...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
