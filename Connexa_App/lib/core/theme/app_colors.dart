import 'package:flutter/material.dart';

/// Centralized brand and semantic color definitions for Connexa Enterprise Platform.
///
/// Palette specification:
/// - Primary brand / Deep Navy: #0F2744 (Brand identity, app bars, navigation emphasis, structural headers)
/// - Primary action / Royal Blue: #2563EB (Primary CTAs, links, focus states, active controls)
/// - Secondary accent / Professional Teal: #0D9488 (Secondary highlights, verification, business badges)
/// - Main background: #F8FAFC
/// - Card and input surfaces: #FFFFFF
/// - Main text: #1E293B
/// - Secondary text: #64748B
/// - Borders and dividers: #E2E8F0
/// - Success: #16A34A
/// - Warning: #D97706
/// - Error: #DC2626
abstract final class AppColors {
  // Brand Identity / Structural: Deep Navy (#0F2744)
  static const Color brandNavy = Color(0xFF0F2744);
  static const Color brandNavyLight = Color(0xFF1E3A5F);
  static const Color brandNavyDark = Color(0xFF0A1C30);
  static const Color onBrandNavy = Color(0xFFFFFFFF);

  // Primary Action / Active Controls: Royal Blue (#2563EB)
  static const Color primaryAction = Color(0xFF2563EB);
  static const Color primaryActionHover = Color(0xFF1D4ED8);
  static const Color primaryActionContainer = Color(0xFFEFF6FF);
  static const Color onPrimaryAction = Color(0xFFFFFFFF);

  // Material 3 Primary Theme Mapping (Primary action is Royal Blue #2563EB)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFEFF6FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1E40AF);

  // Secondary Accent: Professional Teal (#0D9488)
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF0F766E);
  static const Color secondaryContainer = Color(0xFFCCFBF1);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF115E59);

  // Neutral / Main Background (#F8FAFC) & Surfaces (#FFFFFF)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);

  // Borders & Dividers (#E2E8F0)
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Typography & Content: Main Text (#1E293B) & Secondary Text (#64748B)
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Semantic Feedback: Success (#16A34A), Warning (#D97706), Error (#DC2626)
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

  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFEFF6FF);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF1E40AF);
}
