import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color primaryText = Color(0xFF210440);
  
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  
  static const Color outline = Color(0xFF7B757F);
  static const Color outlineVariant = Color(0xFFCCC4D0);
  
  static const Color secondary = Color(0xFF8A4F39);
  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color onSecondaryContainer = Color(0xFF79422D);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color primaryFixed = Color(0xFFEEDBFF);
  static const Color onPrimaryFixed = Color(0xFF270B46);
  static const Color onPrimaryFixedVariant = Color(0xFF553A75);
  
  static const Color primaryFixedDim = Color(0xFFD9B9FD);
  static const Color secondaryFixed = Color(0xFFFFDBCF);
  static const Color onSecondaryFixed = Color(0xFF370E01);
  static const Color tertiaryFixed = Color(0xFFFFDAD6);
  static const Color onTertiaryFixed = Color(0xFF390B09);
  
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F2F7);
  static const Color surfaceContainer = Color(0xFFF3ECF2);
  static const Color surfaceContainerHigh = Color(0xFFEDE6EC);

  static const Color customAccent = Color(0xffFFBA00);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE5958E), Color(0xFFD47A72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onboardingButtonGradient = LinearGradient(
    colors: [Color(0xFF8A4F39), Color(0xFFFEB196)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient saveButtonGradient = LinearGradient(
    colors: [Color(0xFF8A4F39), Colors.black],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkPurpleRoseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xff210440),
      Color(0xffe5958e),
    ],
  );

  static const LinearGradient buttonSplashGradient = LinearGradient(
    colors: [Color(0xffE5958E), Color(0xffC85B84)],
  );

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSecondaryBackground = Color(0xFF1A1A1A);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkElevatedCardBackground = Color(0xFF242424);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFB3B3B3);
  static const Color darkMutedText = Color(0xFF8A8A8A);
}
