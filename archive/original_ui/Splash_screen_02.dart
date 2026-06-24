import 'dart:ui';
import 'package:flutter/material';

class DropVaultOnboardingScreen extends StatefulWidget {
  const DropVaultOnboardingScreen({Key? key}) : super(key: key);

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

    return Scaffold(
      body: MouseRegion(
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
                      const Color(0xfffeb190).withOpacity(0.15),
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
                      const Color(0xffd9b9fd).withOpacity(0.15),
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
                        const Text(
                          'Drop Vault',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // primary config equivalent
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
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
                              color: Color(0xff4a454f), // on-surface-variant
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
                            SizedBox(
                              width: double.infinity,
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
                                        color: const Color(0xfffeb196).withOpacity(0.2),
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
                                        color: const Color(0xffeedbff).withOpacity(0.2),
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),

                                  // Card Layer 1: Fitness Card (Bottom Layer - Staggered -6 deg)
                                  OnboardingFloatingAsset(
                                    baseDuration: 6,
                                    delayMillis: 1000,
                                    parallaxX: _moveX * 0.5,
                                    parallaxY: _moveY * 0.5,
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..translate(-20.0, 20.0)
                                        ..rotateZ(-0.1047), // -6 degrees in radians
                                      alignment: Alignment.center,
                                      child: _buildGlassCard(
                                        width: 256,
                                        height: 192,
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
                                                    color: const Color(0xfffeb196).withOpacity(0.2),
                                                  ),
                                                  child: const Icon(
                                                    Icons.fitness_center,
                                                    color: Color(0xff8a4f39), // secondary color
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(9999),
                                                    color: const Color(0xfffeb196).withOpacity(0.1),
                                                  ),
                                                  child: const Text(
                                                    '#lifestyle',
                                                    style: TextStyle(
                                                      color: Color(0xff79422d), // on-secondary-container
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  'Fitness',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xff1d1b1f), // on-surface
                                                  ),
                                                ),
                                                Text(
                                                  '12 items saved',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff4a454f), // on-surface-variant
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
                                  OnboardingFloatingAsset(
                                    baseDuration: 6,
                                    delayMillis: 0,
                                    parallaxX: _moveX * 1.0,
                                    parallaxY: _moveY * 1.0,
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..translate(20.0, -20.0)
                                        ..rotateZ(0.0523), // 3 degrees in radians
                                      alignment: Alignment.center,
                                      child: _buildGlassCard(
                                        width: 256,
                                        height: 192,
                                        padding: EdgeInsets.zero,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.asset(
                                            'assets/images/splash_02.png',
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
                                fontSize: 28, // mobile scale default
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1d1b1f),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(
                              width: 320, // max-w-xs bounded constraints
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

                            // --- Progress Line Indicators ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 6,
                                  decoration: BoxDecoration(color: const Color(0xffccc4d0), borderRadius: BorderRadius.circular(9999)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32, // Highlighted current step indicator
                                  height: 6,
                                  decoration: BoxDecoration(color: const Color(0xff8a4f39), borderRadius: BorderRadius.circular(9999)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 16,
                                  height: 6,
                                  decoration: BoxDecoration(color: const Color(0xffccc4d0), borderRadius: BorderRadius.circular(9999)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 16,
                                  height: 6,
                                  decoration: BoxDecoration(color: const Color(0xffccc4d0), borderRadius: BorderRadius.circular(9999)),
                                ),
                              ],
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
                    child: Container(
                      width: double.infinity,
                      maxFiniteWidthAllowed: false,
                      constraints: const BoxConstraints(maxWidth: 448), // max-w-md constraint
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          debugPrint('Redirecting to next onboarding screen dynamic flow...');
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          shadowColor: const Color(0xff8a4f39).withOpacity(0.2),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff8a4f39), Color(0xfffeb196)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
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
          ],
        ),
      ),
    );
  }

  // Glassmorphic Card Builder Structure
  Widget _buildGlassCard({
    required double width,
    required double height,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.7),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff8a4f39).withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- Smooth Implicit Animation Controller for Floating Motion & Drag Parallax ---
class OnboardingFloatingAsset extends StatefulWidget {
  final Widget child;
  final int baseDuration;
  final int delayMillis;
  final double parallaxX;
  final double parallaxY;

  const OnboardingFloatingAsset({
    Key? key,
    required this.child,
    required this.baseDuration,
    required this.delayMillis,
    required this.parallaxX,
    required this.parallaxY,
  }) : super(key: key);

  @override
  State<OnboardingFloatingAsset> createState() => _OnboardingFloatingAssetState();
}

class _OnboardingFloatingAssetState extends State<OnboardingFloatingAsset> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.baseDuration),
    );

    _animation = Tween<double>(begin: 0.0, end: -15.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delayMillis), () {
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
          offset: Offset(widget.parallaxX, _animation.value + widget.parallaxY),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}