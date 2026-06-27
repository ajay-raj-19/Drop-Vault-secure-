import 'package:flutter/material.dart';

class DesignTokens {
  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;
  static const double radiusSuper = 28.0;
  static const double radiusCircular = 9999.0;

  static BorderRadius get borderSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderExtraLarge => BorderRadius.circular(radiusExtraLarge);
  static BorderRadius get borderSuper => BorderRadius.circular(radiusSuper);
  static BorderRadius get borderCircular => BorderRadius.circular(radiusCircular);

  // Spacings
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space60 = 60.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 1500);
  static const Duration durationOnboarding = Duration(milliseconds: 2500);

  // Box Shadow Presets
  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  static List<BoxShadow> get shadowDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  static List<BoxShadow> get shadowAccent => [
        BoxShadow(
          color: const Color(0xffC85B84).withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  static List<BoxShadow> get shadowNav => [
        BoxShadow(
          color: const Color(0xFF6D528E).withValues(alpha: 0.1),
          blurRadius: 30,
          offset: const Offset(0, -10),
        )
      ];
}
