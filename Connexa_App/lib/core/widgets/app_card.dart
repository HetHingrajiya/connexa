import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// A standard, premium container card with consistent border, subtle surface color,
/// and optional header/footer sections.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerAction,
    this.footer,
    this.padding = AppSpacing.paddingXl,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasHeader =
        title != null || subtitle != null || headerAction != null;

    final Widget cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: borderColor ?? AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasHeader) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (title != null)
                        Text(title!, style: AppTextStyles.titleLarge),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle!, style: AppTextStyles.bodySmall),
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
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
          ],
          child,
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );

    Widget content = cardBody;
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusLg,
          child: content,
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: content);
    }

    return content;
  }
}
