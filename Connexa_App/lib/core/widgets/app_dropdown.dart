import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// An item definition for [AppDropdown].
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final Widget? icon;
}

/// A consistent dropdown select field with label, error handling,
/// placeholder hint, and rounded border styling.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.hintText = 'Select an option',
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.prefixIcon,
  });

  final List<AppDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String hintText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
          items: items.map((AppDropdownItem<T> item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: <Widget>[
                  if (item.icon != null) ...<Widget>[
                    item.icon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
