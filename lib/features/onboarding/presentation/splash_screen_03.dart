import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/floating_anim.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/onboarding_dots.dart';

class DropVaultFinalOnboarding extends StatefulWidget {
  final PageController controller;
  final VoidCallback onGetStarted;

  const DropVaultFinalOnboarding({
    super.key,
    required this.controller,
    required this.onGetStarted,
  });

  @override
  State<DropVaultFinalOnboarding> createState() => _DropVaultFinalOnboardingState();
}

class _DropVaultFinalOnboardingState extends State<DropVaultFinalOnboarding> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showDesktopMockup = screenWidth >= 640;

    return Theme(
      data: AppTheme.lightTheme,
      child: Container(
      color: const Color(0xfffef7fd),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // --- Top Actions Spacing ---
              const SizedBox(height: 32),

              // --- Main Content Area ---
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        // -- 3D Illustration Mockup Canvas --
                        SizedBox(
                          width: double.infinity,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Ambient Background Glow
                                Transform.scale(
                                  scale: 0.9,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xfffeb196).withValues(alpha: 0.1),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                      child: const SizedBox.shrink(),
                                    ),
                                  ),
                                ),

                                // Main Mobile Phone Mockup
                                FloatingAnim(
                                  duration: const Duration(seconds: 4),
                                  delay: Duration.zero,
                                  child: Container(
                                    width: 192,
                                    height: 320,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffede6ec),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: const Color(0xff1d1b1f).withValues(alpha: 0.05),
                                        width: 6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(34),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Opacity(
                                            opacity: 0.9,
                                            child: Image.asset(
                                              AppAssets.accessImage,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          // Bottom Gradient Overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  const Color(0xffede6ec).withValues(alpha: 0.4),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Desktop Laptop Mockup (Hidden on smaller screens)
                                if (showDesktopMockup)
                                  Positioned(
                                    top: 48,
                                    right: -16,
                                    child: FloatingAnim(
                                      duration: const Duration(seconds: 4),
                                      delay: const Duration(seconds: 2),
                                      child: Container(
                                        width: 224,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          color: const Color(0xffffffff),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xffccc4d0).withValues(alpha: 0.3),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 24,
                                              offset: const Offset(0, 12),
                                            )
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(7),
                                          child: Image.network(
                                            AppAssets.laptopMockImage,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // -- Copywriting / Text Section --
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Access Everywhere',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1d1b1f),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 320,
                          child: Text(
                            'Seamlessly keep your links, files, and notes updated across your Android phone and Windows PC.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              color: Color(0xff4a454f),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

              // --- Footer Action Section ---
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, top: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OnboardingDots(
                        controller: widget.controller,
                        pageCount: 3,
                        activeColor: const Color(0xff000000),
                        inactiveColor: const Color(0xffccc4d0),
                      ),
                      const SizedBox(height: 24),
                      Row(
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
                                color: Color(0xff4a454f),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _isButtonPressed = true),
                              onTapUp: (_) {
                                setState(() => _isButtonPressed = false);
                                widget.onGetStarted();
                              },
                              onTapCancel: () => setState(() => _isButtonPressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                transform: Matrix4.identity()..scaleByDouble(
                                  _isButtonPressed ? 0.95 : 1.0,
                                  _isButtonPressed ? 0.95 : 1.0,
                                  1.0,
                                  1.0,
                                ),
                                transformAlignment: Alignment.center,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.customAccent,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xfffeb196).withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: TextStyle(
                                        color: Color(0xff1d1b1f),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Color(0xff1d1b1f),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
