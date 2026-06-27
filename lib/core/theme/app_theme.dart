import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color customBackground;
  final Color secondaryBackground;
  final Color cardBackground;
  final Color elevatedCardBackground;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  
  // Brand accents
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color surfaceContainerHigh;
  final Color customAccent;

  AppThemeExtension({
    required this.customBackground,
    required this.secondaryBackground,
    required this.cardBackground,
    required this.elevatedCardBackground,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.primaryFixedDim,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.surfaceContainerHigh,
    required this.customAccent,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? customBackground,
    Color? secondaryBackground,
    Color? cardBackground,
    Color? elevatedCardBackground,
    Color? border,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? primaryFixed,
    Color? onPrimaryFixed,
    Color? primaryFixedDim,
    Color? secondaryFixed,
    Color? onSecondaryFixed,
    Color? tertiaryFixed,
    Color? onTertiaryFixed,
    Color? surfaceContainerHigh,
    Color? customAccent,
  }) {
    return AppThemeExtension(
      customBackground: customBackground ?? this.customBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      elevatedCardBackground: elevatedCardBackground ?? this.elevatedCardBackground,
      border: border ?? this.border,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      customAccent: customAccent ?? this.customAccent,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      customBackground: Color.lerp(customBackground, other.customBackground, t)!,
      secondaryBackground: Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      elevatedCardBackground: Color.lerp(elevatedCardBackground, other.elevatedCardBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      primaryFixedDim: Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      onSecondaryFixed: Color.lerp(onSecondaryFixed, other.onSecondaryFixed, t)!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      onTertiaryFixed: Color.lerp(onTertiaryFixed, other.onTertiaryFixed, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      customAccent: Color.lerp(customAccent, other.customAccent, t)!,
    );
  }
}

extension AppThemeExtensionX on BuildContext {
  AppThemeExtension get appColors => Theme.of(this).extension<AppThemeExtension>()!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      focusColor: Colors.transparent,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceContainerLowest,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onError: Colors.white,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      extensions: [
        AppThemeExtension(
          customBackground: AppColors.background,
          secondaryBackground: AppColors.surfaceContainerLow,
          cardBackground: AppColors.surfaceContainerLowest,
          elevatedCardBackground: AppColors.surfaceContainerHigh,
          border: AppColors.outlineVariant,
          primaryText: AppColors.onSurface,
          secondaryText: AppColors.onSurfaceVariant,
          mutedText: AppColors.outline,
          primaryFixed: AppColors.primaryFixed,
          onPrimaryFixed: AppColors.onPrimaryFixed,
          primaryFixedDim: AppColors.primaryFixedDim,
          secondaryFixed: AppColors.secondaryFixed,
          onSecondaryFixed: AppColors.onSecondaryFixed,
          tertiaryFixed: AppColors.tertiaryFixed,
          onTertiaryFixed: AppColors.onTertiaryFixed,
          surfaceContainerHigh: AppColors.surfaceContainerHigh,
          customAccent: AppColors.customAccent,
        ),
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.black12,
        space: 1,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: Colors.white,
      focusColor: Colors.transparent,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: AppColors.secondary,
        surface: AppColors.darkCardBackground,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onError: Colors.white,
        onSurface: AppColors.darkPrimaryText,
        onSurfaceVariant: AppColors.darkSecondaryText,
        outline: AppColors.darkMutedText,
        outlineVariant: AppColors.darkBorder,
      ),
      extensions: [
        AppThemeExtension(
          customBackground: AppColors.darkBackground,
          secondaryBackground: AppColors.darkSecondaryBackground,
          cardBackground: AppColors.darkCardBackground,
          elevatedCardBackground: AppColors.darkElevatedCardBackground,
          border: AppColors.darkBorder,
          primaryText: AppColors.darkPrimaryText,
          secondaryText: AppColors.darkSecondaryText,
          mutedText: AppColors.darkMutedText,
          primaryFixed: AppColors.primaryFixed,
          onPrimaryFixed: AppColors.onPrimaryFixed,
          primaryFixedDim: AppColors.primaryFixedDim,
          secondaryFixed: AppColors.secondaryFixed,
          onSecondaryFixed: AppColors.onSecondaryFixed,
          tertiaryFixed: AppColors.tertiaryFixed,
          onTertiaryFixed: AppColors.onTertiaryFixed,
          surfaceContainerHigh: AppColors.darkElevatedCardBackground,
          customAccent: AppColors.customAccent,
        ),
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSecondaryBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.primaryFixedDim, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.white12,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
