import 'dart:async';
import 'dart:ui';
import 'package:flutter/material';

class DropVaultSplashScreen extends StatefulWidget {
  const DropVaultSplashScreen({Key? key}) : super(key: key);

  @override
  State<DropVaultSplashScreen> createState() => _DropVaultSplashScreenState();
}

class _DropVaultSplashScreenState extends State<DropVaultSplashScreen> {
  // Parallax offsets
  double _pointerX = 0.0;
  double _pointerY = 0.0;

  // Overlay state
  bool _showOverlay = false;
  bool _scaleIcon = false;

  void _handleGetStarted() {
    setState(() {
      _showOverlay = true;
    });

    // Trigger icon pop-in micro-interaction
    Timer(const Duration(milliseconds: 100), () {
      setState(() {
        _scaleIcon = true;
      });
    });

    // Simulate navigation transition
    Timer(const Duration(milliseconds: 2500), () {
      debugPrint("Navigating to Home Screen...");
      if (mounted) {
        setState(() {
          _showOverlay = false;
          _scaleIcon = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: MouseRegion(
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff210440), // Dark Deep Purple
                    Color(0xffe5958e), // Soft Rose Gold
                  ],
                ),
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
                    const Text(
                      'Drop Vault',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
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
                    crossAxisAlignment: CenterAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // --- 3D Canvas Mock Area ---
                      SizedBox(
                        width: 400,
                        height: 400,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Main Vault Center Asset
                            FloatingAsset(
                              baseDuration: 6,
                              delayMultiplier: 0.1,
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
                                        'assets/images/splash_01.png',
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
                              child: FloatingAsset(
                                baseDuration: 6,
                                delayMultiplier: 0.2,
                                parallaxX: _pointerX * 1.0,
                                parallaxY: _pointerY * 1.0,
                                child: _buildGlassCard(
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
                              child: FloatingAsset(
                                baseDuration: 6,
                                delayMultiplier: 0.3,
                                parallaxX: _pointerX * 1.5,
                                parallaxY: _pointerY * 1.5,
                                child: _buildGlassCard(
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
                              child: FloatingAsset(
                                baseDuration: 6,
                                delayMultiplier: 0.1,
                                parallaxX: _pointerX * 0.5,
                                parallaxY: _pointerY * 0.5,
                                child: _buildGlassCard(
                                  padding: const EdgeInsets.all(12),
                                  isCircle: true,
                                  child: const Icon(Icons.link, color: Colors.white, size: 20),
                                ),
                              ),
                            ),

                            // Floating Circle Music Item
                            Positioned(
                              bottom: 120,
                              left: 45,
                              child: FloatingAsset(
                                baseDuration: 6,
                                delayMultiplier: 0.2,
                                parallaxX: _pointerX * 1.0,
                                parallaxY: _pointerY * 1.0,
                                child: _buildGlassCard(
                                  padding: const EdgeInsets.all(12),
                                  isCircle: true,
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
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
                          fontWeight: FontWeight.medium,
                          color: Colors.white90,
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
                        constraints: const BoxConstraints(maxWidth: 384), // equivalent max-w-sm
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _handleGetStarted,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9999),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xffE5958E), Color(0xffC85B84)],
                                  ),
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
                                      'Get Started',
                                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.semibold),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.arrow_forward, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {},
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9999)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(9999)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(9999)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // --- Success Feedback Overlay System ---
            IgnorePointer(
              ignoring: !_showOverlay,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: _scaleIcon ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xfffeb196), width: 4),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 48),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Preparing Your Vault',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Establishing secure connection...',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper Custom Widget to render Glassmorphic Card Blocks
  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding, bool isCircle = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCircle ? 9999 : 16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- Custom Widget helper to emulate the continuous Floating Cycle & Parallax Offset ---
class FloatingAsset extends StatefulWidget {
  final Widget child;
  final int baseDuration;
  final double delayMultiplier;
  final double parallaxX;
  final double parallaxY;

  const FloatingAsset({
    Key? key,
    required this.child,
    required this.baseDuration,
    required this.delayMultiplier,
    required this.parallaxX,
    required this.parallaxY,
  }) : super(key: key);

  @override
  State<FloatingAsset> createState() => _FloatingAssetState();
}

class _FloatingAssetState extends State<FloatingAsset> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.baseDuration),
    );

    _animation = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Apply staggering delay
    Future.delayed(Duration(milliseconds: (widget.delayMultiplier * 1000).toInt()), () {
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
        // Combined transformation mechanics: Continuous floating loop state + Parallax cursor impact
        return Transform.translate(
          offset: Offset(widget.parallaxX, _animation.value + widget.parallaxY),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}