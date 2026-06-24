import 'package:flutter/material.dart';

class FloatingAnim extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double parallaxX;
  final double parallaxY;
  final double floatDepth;

  const FloatingAnim({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 6),
    this.delay = Duration.zero,
    this.parallaxX = 0.0,
    this.parallaxY = 0.0,
    this.floatDepth = -15.0,
  }) : super(key: key);

  @override
  State<FloatingAnim> createState() => _FloatingAnimState();
}

class _FloatingAnimState extends State<FloatingAnim> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.floatDepth).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
          offset: Offset(widget.parallaxX, _animation.value + widget.parallaxY),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
