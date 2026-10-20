import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// A standard, premium container card with consistent border, subtle surface color,
/// soft SaaS shadow elevation, smooth hover feedback, and optional header/footer sections.
class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hasHeader =
        widget.title != null ||
        widget.subtitle != null ||
        widget.headerAction != null ||
        widget.headerLeading != null;
    final BorderRadius effectiveRadius =
        widget.borderRadius ?? AppSpacing.borderRadiusLg;

    final Widget cardContent = Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasHeader) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (widget.headerLeading != null) ...<Widget>[
                  widget.headerLeading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      if (widget.subtitle != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.headerAction != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  widget.headerAction!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
          ],
          widget.child,
          if (widget.footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            widget.footer!,
          ],
        ],
      ),
    );

    final bool isInteractive = widget.onTap != null;
    final Color effectiveBorderColor =
        widget.borderColor ??
        (isInteractive && _isHovered
            ? AppColors.primary.withValues(alpha: 0.45)
            : AppColors.border);

    final List<BoxShadow>? effectiveShadows = widget.hasShadow
        ? <BoxShadow>[
            BoxShadow(
              color: isInteractive && _isHovered
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.03),
              blurRadius: isInteractive && _isHovered ? 14 : 8,
              offset: isInteractive && _isHovered
                  ? const Offset(0, 4)
                  : const Offset(0, 2),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ]
        : null;

    final Widget cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorderColor, width: 1.0),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: isInteractive
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: effectiveRadius,
                  splashColor: AppColors.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  highlightColor: AppColors.surfaceContainer.withValues(
                    alpha: 0.4,
                  ),
                  child: cardContent,
                ),
              )
            : cardContent,
      ),
    );

    Widget result = cardBody;
    if (isInteractive) {
      result = MouseRegion(
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _isHovered = false);
        },
        cursor: SystemMouseCursors.click,
        child: result,
      );
    }

    if (widget.margin != null) {
      return Padding(padding: widget.margin!, child: result);
    }

    return result;
  }
}
