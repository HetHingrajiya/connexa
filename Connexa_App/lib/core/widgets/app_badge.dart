import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// Semantic variants for standardized badges and status chips across Connexa.
enum AppBadgeVariant {
  brand,
  primary,
  secondary,
  success,
  warning,
  error,
  info,
  neutral,
}

/// Standardized, premium badge / tag component matching Connexa's brand palette.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  });

  /// Factory for a brand identity badge (Deep Navy tinted).
  const AppBadge.brand({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.brand;

  /// Factory for a primary action badge (Royal Blue tinted).
  const AppBadge.primary({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.primary;

  /// Factory for a secondary teal badge.
  const AppBadge.secondary({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.secondary;

  /// Factory for a success / verified badge (Emerald green).
  const AppBadge.success({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.success;

  /// Factory for a warning / pending badge (Amber).
  const AppBadge.warning({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.warning;

  /// Factory for an error badge (Red).
  const AppBadge.error({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.error;

  /// Factory for an info badge (Sky blue).
  const AppBadge.info({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.info;

  /// Factory for a neutral slate badge.
  const AppBadge.neutral({
    super.key,
    required this.label,
    this.icon,
    this.isPill = false,
    this.fontSize = 11.0,
    this.padding,
  }) : variant = AppBadgeVariant.neutral;

  final String label;
  final AppBadgeVariant variant;
  final Widget? icon;
  final bool isPill;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color border) = switch (variant) {
      AppBadgeVariant.brand => (
        AppColors.brandNavy.withValues(alpha: 0.08),
        AppColors.brandNavy,
        AppColors.brandNavy.withValues(alpha: 0.25),
      ),
      AppBadgeVariant.primary => (
        AppColors.primaryContainer,
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.25),
      ),
      AppBadgeVariant.secondary => (
        AppColors.secondaryContainer,
        AppColors.onSecondaryContainer,
        AppColors.secondary.withValues(alpha: 0.3),
      ),
      AppBadgeVariant.success => (
        AppColors.successContainer,
        AppColors.onSuccessContainer,
        AppColors.success.withValues(alpha: 0.3),
      ),
      AppBadgeVariant.warning => (
        AppColors.warningContainer,
        AppColors.onWarningContainer,
        AppColors.warning.withValues(alpha: 0.35),
      ),
      AppBadgeVariant.error => (
        AppColors.errorContainer,
        AppColors.onErrorContainer,
        AppColors.error.withValues(alpha: 0.3),
      ),
      AppBadgeVariant.info => (
        AppColors.infoContainer,
        AppColors.onInfoContainer,
        AppColors.info.withValues(alpha: 0.3),
      ),
      AppBadgeVariant.neutral => (
        AppColors.surfaceContainer,
        AppColors.textSecondary,
        AppColors.border,
      ),
    };

    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs + 1,
          ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: isPill
            ? AppSpacing.borderRadiusFull
            : AppSpacing.borderRadiusSm,
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            icon!,
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
