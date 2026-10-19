import 'package:flutter/material.dart';

/// Centralized brand and semantic color definitions for Connexa.
///
/// Brand personality: Trustworthy, professional, modern, clean, business-focused.
abstract final class AppColors {
  // Brand Primary: Deep Navy Blue
  static const Color primary = Color(0xFF0F2744);
  static const Color primaryLight = Color(0xFF1E3A5F);
  static const Color primaryDark = Color(0xFF09182B);
  static const Color primaryContainer = Color(0xFFE8EEF5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0F2744);

  // Brand Secondary / Accent: Professional Teal
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF0F766E);
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF115E59);

  // Neutral / Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEEF2F6);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Typography & Content
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF14532D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF78350F);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF0284C7);
  static const Color infoContainer = Color(0xFFE0F2FE);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF075985);
}
