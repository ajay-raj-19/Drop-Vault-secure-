import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final double opacity;
  final double borderOpacity;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final Color baseColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.isCircle = false,
    this.opacity = 0.7,
    this.borderOpacity = 0.2,
    this.blurSigma = 12.0,
    this.boxShadow,
    this.baseColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final shape = isCircle ? BoxShape.circle : BoxShape.rectangle;
    final r = isCircle ? BorderRadius.circular(9999) : BorderRadius.circular(borderRadius);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Resolve base color: if white (default), use dark card color in dark mode
    Color resolvedBaseColor;
    if (baseColor == Colors.white) {
      resolvedBaseColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    } else {
      resolvedBaseColor = baseColor;
    }

    // Resolve border color: use 0.08 alpha white border in dark mode, or configured opacity in light mode
    Color resolvedBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: borderOpacity);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: isCircle ? null : r,
            color: resolvedBaseColor.withValues(alpha: opacity),
            border: Border.all(
              color: resolvedBorderColor,
            ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
