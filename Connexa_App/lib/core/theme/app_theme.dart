import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// Centralized Material 3 theme configuration for Connexa.
abstract final class AppTheme {
  /// Primary light theme for the application.
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceContainerHigh,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const <String>[
        'Roboto',
        'Segoe UI',
        'San Francisco',
        'Arial',
      ],

      // Typography
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    );
  }

  /// Dark theme counterpart for Connexa.
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: Color(0xFF60A5FA),
      onPrimary: Color(0xFF0F172A),
      primaryContainer: Color(0xFF1E3A5F),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: AppColors.secondaryLight,
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF115E59),
      onSecondaryContainer: Color(0xFFCCFBF1),
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFF8FAFC),
      surfaceContainerHighest: Color(0xFF334155),
      surfaceContainer: Color(0xFF1E293B),
      error: Color(0xFFF87171),
      onError: Color(0xFF0F172A),
      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF090D16),
      cardTheme: CardThemeData(
        color: const Color(0xFF0F172A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
    );
  }
}
