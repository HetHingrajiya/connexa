import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text }

/// A premium, reusable button supporting primary, secondary/outlined,
/// and text variants, with built-in loading and disabled states.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48.0,
  });

  /// Factory constructor for a primary button (deep navy background).
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48.0,
  }) : variant = AppButtonVariant.primary;

  /// Factory constructor for a secondary/outlined button.
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48.0,
  }) : variant = AppButtonVariant.secondary;

  /// Factory constructor for a subtle text button.
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48.0,
  }) : variant = AppButtonVariant.text;

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double height;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget content = _buildContent();

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
          ),
          child: content,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
          ),
          child: content,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
          ),
          child: content,
        );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildContent() {
    if (isLoading) {
      final Color indicatorColor = switch (variant) {
        AppButtonVariant.primary => AppColors.onPrimary,
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.text => AppColors.primary,
      };

      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    final List<Widget> children = <Widget>[];

    if (leadingIcon != null) {
      children.add(leadingIcon!);
      children.add(const SizedBox(width: AppSpacing.sm));
    }

    children.add(
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
    );

    if (trailingIcon != null) {
      children.add(const SizedBox(width: AppSpacing.sm));
      children.add(trailingIcon!);
    }

    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
