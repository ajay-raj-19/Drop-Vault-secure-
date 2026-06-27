import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_anim.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/onboarding_dots.dart';

class DropVaultOnboardingScreen extends StatefulWidget {
  final PageController controller;
  const DropVaultOnboardingScreen({super.key, required this.controller});

  @override
  State<DropVaultOnboardingScreen> createState() => _DropVaultOnboardingScreenState();
}

class _DropVaultOnboardingScreenState extends State<DropVaultOnboardingScreen> {
  // Parallax offsets for mouse/pointer interaction
  double _moveX = 0.0;
  double _moveY = 0.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Theme(
      data: AppTheme.lightTheme,
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            // Screen center se relative movement coordinate scale calculate karne ke liye
            _moveX = (event.localPosition.dx / screenSize.width - 0.5) * 20.0;
            _moveY = (event.localPosition.dy / screenSize.height - 0.5) * 20.0;
          });
        },
        child: Stack(
          children: [
            // --- Custom Mesh Gradient Background ---
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xfffef7fd), // Core background color
            ),
            // Radial mesh top-left ambient blob
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: screenSize.width * 0.6,
                height: screenSize.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xfffeb190).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Radial mesh top-right ambient blob
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: screenSize.width * 0.6,
                height: screenSize.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xffd9b9fd).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // --- Main Content Architecture Layout ---
            SafeArea(
              child: Column(
                children: [
                  // --- AppBar Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            BrandLogo(width: 28),
                            SizedBox(width: 8),
                            Text(
                              'Drop Vault',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
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
                              color: Color(0xff4a454f),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Central Body Area ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // --- Interactive Visual Stack Area ---
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background blur elements
                                  Positioned(
                                    top: 20,
                                    left: 20,
                                    child: Container(
                                      width: 128,
                                      height: 128,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xfffeb196).withValues(alpha: 0.2),
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    right: 20,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xffeedbff).withValues(alpha: 0.2),
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),

                                  // Card Layer 1: Fitness Card (Bottom Layer - Staggered -6 deg)
                                  FloatingAnim(
                                    duration: const Duration(seconds: 6),
                                    delay: const Duration(milliseconds: 1000),
                                    parallaxX: _moveX * 0.5,
                                    parallaxY: _moveY * 0.5,
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..translateByDouble(-20.0, 20.0, 0.0, 1.0)
                                        ..rotateZ(-0.1047), // -6 degrees in radians
                                      alignment: Alignment.center,
                                      child: GlassCard(
                                        width: 256,
                                        height: 192,
                                        padding: const EdgeInsets.all(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xff8a4f39).withValues(alpha: 0.1),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          )
                                        ],
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color(0xfffeb196).withValues(alpha: 0.2),
                                                  ),
                                                  child: const Icon(
                                                    Icons.fitness_center,
                                                    color: Color(0xff8a4f39),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(9999),
                                                    color: const Color(0xfffeb196).withValues(alpha: 0.1),
                                                  ),
                                                  child: const Text(
                                                    '#lifestyle',
                                                    style: TextStyle(
                                                      color: Color(0xff79422d),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Fitness',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xff1d1b1f),
                                                  ),
                                                ),
                                                Text(
                                                  '12 items saved',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff4a454f),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Card Layer 2: Study Sync Image Card (Top Layer - Staggered 3 deg)
                                  FloatingAnim(
                                    duration: const Duration(seconds: 6),
                                    delay: Duration.zero,
                                    parallaxX: _moveX * 1.0,
                                    parallaxY: _moveY * 1.0,
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..translateByDouble(20.0, -20.0, 0.0, 1.0)
                                        ..rotateZ(0.0523), // 3 degrees in radians
                                      alignment: Alignment.center,
                                      child: GlassCard(
                                        width: 256,
                                        height: 192,
                                        padding: EdgeInsets.zero,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xff8a4f39).withValues(alpha: 0.1),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          )
                                        ],
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.asset(
                                            AppAssets.organizeImage,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- Narrative Content Section ---
                            const Text(
                              'Organize Everything',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1d1b1f),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(
                              width: 320,
                              child: Text(
                                'Sort into collections and tags for a perfectly curated digital sanctuary.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 28 / 18,
                                  color: Color(0xff4a454f),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                            OnboardingDots(
                              controller: widget.controller,
                              pageCount: 3,
                              activeColor: const Color(0xff8a4f39),
                              inactiveColor: const Color(0xffccc4d0),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Sticky Action Footer Layer ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              widget.controller.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                color: Color(0xff8a4f39),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.controller.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 10,
                                  shadowColor: const Color(0xff8a4f39).withValues(alpha: 0.2),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.onboardingButtonGradient,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Next',
                                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
