import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_anim.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/widgets/brand_logo.dart';
import 'widgets/onboarding_dots.dart';
import 'splash_screen_02.dart';
import 'splash_screen_03.dart';

class DropVaultSplashScreen extends ConsumerStatefulWidget {
  const DropVaultSplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DropVaultSplashScreen> createState() => _DropVaultSplashScreenState();
}

class _DropVaultSplashScreenState extends ConsumerState<DropVaultSplashScreen> {
  // Parallax offsets
  double _pointerX = 0.0;
  double _pointerY = 0.0;

  // PageController for swipe navigation
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildScreen1(context),
            DropVaultOnboardingScreen(controller: _pageController),
            DropVaultFinalOnboarding(
              controller: _pageController,
              onGetStarted: _handleGetStarted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen1(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return MouseRegion(
      onHover: (event) {
        setState(() {
          // Normalize offsets between -10.0 and 10.0 for parallax depth
          _pointerX = (event.localPosition.dx / screenSize.width - 0.5) * 20.0;
          _pointerY = (event.localPosition.dy / screenSize.height - 0.5) * 20.0;
        });
      },
      child: Stack(
        children: [
          // --- Background Canvas Layer ---
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.darkPurpleRoseGradient,
            ),
          ),

          // Ambient Blobs
          Positioned(
            top: screenSize.height * 0.2,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xfffeb196).withOpacity(0.12),
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
                color: const Color(0xffeedbff).withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // --- Fixed Top Header Navigation ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      BrandLogo(width: 32),
                      SizedBox(width: 8),
                      Text(
                        'Drop Vault',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
                      context.go('/login');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Main Content (Scrollable if viewport is tiny) ---
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // --- 3D Canvas Mock Area ---
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 400,
                        height: 400,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Main Vault Center Asset
                            FloatingAnim(
                              duration: const Duration(seconds: 6),
                              delay: Duration.zero,
                              parallaxX: _pointerX * 0.5,
                              parallaxY: _pointerY * 0.5,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Shadow and rotate backplate
                                  Transform.rotate(
                                    angle: 0.05,
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        color: const Color(0xff270b46),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 30,
                                            offset: const Offset(4, 32),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Vault Image Frame
                                  Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        AppAssets.vaultImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Floating Item 1: Annual_Report.pdf
                            Positioned(
                              top: 40,
                              left: 20,
                              child: FloatingAnim(
                                duration: const Duration(seconds: 6),
                                delay: const Duration(milliseconds: 200),
                                parallaxX: _pointerX * 1.0,
                                parallaxY: _pointerY * 1.0,
                                child: GlassCard(
                                  opacity: 0.15,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.description, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Annual_Report.pdf',
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Floating Item 2: Summer_Vibes.jpg
                            Positioned(
                              bottom: 60,
                              right: 20,
                              child: FloatingAnim(
                                duration: const Duration(seconds: 6),
                                delay: const Duration(milliseconds: 300),
                                parallaxX: _pointerX * 1.5,
                                parallaxY: _pointerY * 1.5,
                                child: GlassCard(
                                  opacity: 0.15,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.image, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Summer_Vibes.jpg',
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Floating Circle Link Item
                            Positioned(
                              top: 180,
                              right: 30,
                              child: FloatingAnim(
                                duration: const Duration(seconds: 6),
                                delay: const Duration(milliseconds: 100),
                                parallaxX: _pointerX * 0.5,
                                parallaxY: _pointerY * 0.5,
                                child: const GlassCard(
                                  padding: EdgeInsets.all(12),
                                  isCircle: true,
                                  opacity: 0.15,
                                  child: Icon(Icons.link, color: Colors.white, size: 20),
                                ),
                              ),
                            ),

                            // Floating Circle Music Item
                            Positioned(
                              bottom: 120,
                              left: 45,
                              child: FloatingAnim(
                                duration: const Duration(seconds: 6),
                                delay: const Duration(milliseconds: 200),
                                parallaxX: _pointerX * 1.0,
                                parallaxY: _pointerY * 1.0,
                                child: const GlassCard(
                                  padding: EdgeInsets.all(12),
                                  isCircle: true,
                                  opacity: 0.15,
                                  child: Icon(Icons.music_note, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Copywriting / App Typography Identity ---
                    const Text(
                      'Drop Vault',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        height: 56 / 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.96,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save anything. Find it instantly. Access it everywhere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Your all-in-one space to store links, notes, files, and images. Elegant design meets peak productivity for your digital sanctuary.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Interactive Actions Layout Area ---
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 384),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9999),
                                gradient: AppColors.buttonSplashGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xffC85B84).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Next',
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.arrow_forward, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
                              context.go('/login');
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: Text(
                              'Already have an account? Log In',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Page Indicators Display ---
                    OnboardingDots(
                      controller: _pageController,
                      pageCount: 3,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
