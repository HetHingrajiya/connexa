import 'package:flutter/material.dart';

import 'package:connexa/core/theme/app_colors.dart';
import 'package:connexa/core/theme/app_spacing.dart';
import 'package:connexa/core/theme/app_text_styles.dart';

/// A specialized search input field with search prefix icon, clear button,
/// and rounded container styling suitable for tables, headers, and lists.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search businesses, industries, partners...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _showClear = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    super.dispose();
  }

  void _handleTextChange() {
    final bool hasText = _controller.text.isNotEmpty;
    if (hasText != _showClear) {
      setState(() {
        _showClear = hasText;
      });
    }
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: _showClear
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: _clearSearch,
                tooltip: 'Clear search',
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
