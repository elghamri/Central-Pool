import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

export 'app_colors.dart';
export 'app_typography.dart';
export 'app_spacing.dart';

/// Complete ThemeData definition for Collaborative Finance Platform.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.deepSlate,
      primaryColor: AppColors.emeraldGreen,
      canvasColor: AppColors.deepSlate,
      cardColor: AppColors.cardSurface,
      dividerColor: AppColors.borderSubtle,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emeraldGreen,
        onPrimary: AppColors.deepSlate,
        secondary: AppColors.sovereignGold,
        onSecondary: AppColors.deepSlate,
        error: AppColors.crimsonRed,
        onError: Colors.white,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepSlate,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderMd,
          side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.crimsonRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: const BorderSide(color: AppColors.crimsonRed, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.crimsonRed),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldGreen,
          foregroundColor: AppColors.deepSlate,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
          textStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.deepSlate,
          ),
        ),
      ),
    );
  }
}
