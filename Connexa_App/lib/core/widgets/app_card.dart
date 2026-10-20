import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// A standard, premium container card with consistent border, subtle surface color,
/// soft SaaS shadow elevation, and optional header/footer sections.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerLeading,
    this.headerAction,
    this.footer,
    this.padding = AppSpacing.paddingXl,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.hasShadow = true,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? headerLeading;
  final Widget? headerAction;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final bool hasShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasHeader =
        title != null ||
        subtitle != null ||
        headerAction != null ||
        headerLeading != null;
    final BorderRadius effectiveRadius =
        borderRadius ?? AppSpacing.borderRadiusLg;

    final Widget cardContent = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasHeader) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (headerLeading != null) ...<Widget>[
                  headerLeading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (title != null)
                        Text(
                          title!,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerAction != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  headerAction!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
        ],
      ),
    );

    final Widget cardBody = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: effectiveRadius,
        border: Border.all(color: borderColor ?? AppColors.border, width: 1.0),
        boxShadow: hasShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: effectiveRadius,
                  splashColor: AppColors.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  highlightColor: AppColors.surfaceContainer.withValues(
                    alpha: 0.5,
                  ),
                  child: cardContent,
                ),
              )
            : cardContent,
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: cardBody);
    }

    return cardBody;
  }
}
