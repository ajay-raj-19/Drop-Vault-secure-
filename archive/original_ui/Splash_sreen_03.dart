import 'dart:ui';
import 'package:flutter/material.dart';

class DropVaultFinalOnboarding extends StatefulWidget {
  const DropVaultFinalOnboarding({Key? key}) : super(key: key);

  @override
  State<DropVaultFinalOnboarding> createState() => _DropVaultFinalOnboardingState();
}

class _DropVaultFinalOnboardingState extends State<DropVaultFinalOnboarding> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Tailwind's 'sm' breakpoint is typically 640px
    final bool showDesktopMockup = screenWidth >= 640;

    return Scaffold(
      backgroundColor: const Color(0xfffef7fd), // background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // --- Top Actions ---
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    debugPrint('Skip clicked');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      color: Color(0xff4a454f), // on-surface-variant
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6, // label-md letter spacing
                    ),
                  ),
                ),
              ),

              // --- Main Content Area ---
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 512), // max-w-lg
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
                                      color: const Color(0xfffeb196).withOpacity(0.1), // secondary-container/10
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                      child: const SizedBox.shrink(),
                                    ),
                                  ),
                                ),

                                // Main Mobile Phone Mockup
                                FloatingWidget(
                                  duration: const Duration(seconds: 4),
                                  delay: Duration.zero,
                                  child: Container(
                                    width: 192, // w-48
                                    height: 320, // h-80
                                    decoration: BoxDecoration(
                                      color: const Color(0xffede6ec), // surface-container-high
                                      borderRadius: BorderRadius.circular(40), // rounded-[2.5rem]
                                      border: Border.all(
                                        color: const Color(0xff1d1b1f).withOpacity(0.05), // on-surface/5
                                        width: 6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(34), // Inner radius
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Opacity(
                                            opacity: 0.9,
                                            child: Image.asset(
                                              'assets/images/splash_03.png',
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
                                                  const Color(0xffede6ec).withOpacity(0.4),
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
                                    top: 48, // top-12
                                    right: -16, // -right-4
                                    child: FloatingWidget(
                                      duration: const Duration(seconds: 4),
                                      delay: const Duration(seconds: 2), // animate-float-delayed
                                      child: Container(
                                        width: 224, // w-56
                                        height: 160, // h-40
                                        decoration: BoxDecoration(
                                          color: const Color(0xffffffff), // surface-container-lowest
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xffccc4d0).withOpacity(0.3), // outline-variant/30
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 24,
                                              offset: const Offset(0, 12),
                                            )
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(7),
                                          child: Image.network(
                                            'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?q=80&w=600&auto=format&fit=crop',
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
                              fontSize: 28, // md:text-headline-lg (32) would go here based on constraints
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1d1b1f), // on-background
                              letterSpacing: -0.5, // tracking-tight
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 320, // max-w-xs
                          child: Text(
                            'Seamlessly keep your links, files, and notes updated across your Android phone and Windows PC.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              color: Color(0xff4a454f), // on-surface-variant
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
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: const Color(0xffccc4d0), borderRadius: BorderRadius.circular(9999)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: const Color(0xffccc4d0), borderRadius: BorderRadius.circular(9999)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 6,
                            decoration: BoxDecoration(color: const Color(0xff000000), borderRadius: BorderRadius.circular(9999)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Get Started CTA
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) {
                          setState(() => _isButtonPressed = false);
                          debugPrint('Navigating to login...');
                        },
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
                          transformAlignment: Alignment.center,
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xffFFBA00), // bg-custom-accent
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xfffeb196).withOpacity(0.2), // shadow-secondary-container/20
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Color(0xff1d1b1f), // text-on-background
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Smooth Implicit Animation Controller for the floating UI Mockups ---
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FloatingWidget({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
  }) : super(key: key);

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Replicating the CSS: 0% -> 0px, 50% -> -10px, 100% -> 0px
    _animation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}