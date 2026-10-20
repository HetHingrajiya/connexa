import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// A consistent, professional text input field with label, hint,
/// validation error, helper text, and prefix/suffix support.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;

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
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          maxLines: maxLines,
          minLines: minLines,
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            errorText: errorText,
            helperText: helperText,
            prefixIconColor: AppColors.textSecondary,
            suffixIconColor: AppColors.textSecondary,
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
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ),
      ],
    );
  }
}
