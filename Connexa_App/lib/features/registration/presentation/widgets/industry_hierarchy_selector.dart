import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_dropdown.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';

/// Interactive 4-tier dependent dropdown selector for Industry Master Data:
/// Industry -> Business Group -> SubGroup -> Category.
///
/// Features:
/// - Real backend API consumption with no fabricated data.
/// - Cascading resets when an ancestor tier changes.
/// - Loading, empty, and error states with Retry actions.
/// - Responsive, keyboard-safe design matching the Connexa design system.
class IndustryHierarchySelector extends ConsumerWidget {
  const IndustryHierarchySelector({
    super.key,
    required this.roleName,
    this.errorMessage,
  });

  final String roleName;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IndustryHierarchyState hierarchyState = ref.watch(
      industryHierarchyProvider,
    );
    final IndustryHierarchyNotifier notifier = ref.read(
      industryHierarchyProvider.notifier,
    );

    // Watch top-level industries
    final AsyncValue<List<Industry>> industriesAsync = ref.watch(
      industriesProvider,
    );

    // Watch dependent business groups
    final int? selectedIndustryId = hierarchyState.selectedIndustry?.id;
    final AsyncValue<List<BusinessGroup>>? businessGroupsAsync =
        selectedIndustryId != null && selectedIndustryId > 0
        ? ref.watch(businessGroupsProvider(selectedIndustryId))
        : null;

    // Watch dependent sub-groups
    final int? selectedGroupId = hierarchyState.selectedBusinessGroup?.id;
    final AsyncValue<List<SubGroup>>? subGroupsAsync =
        selectedGroupId != null && selectedGroupId > 0
        ? ref.watch(subGroupsProvider(selectedGroupId))
        : null;

    // Watch dependent categories
    final int? selectedSubGroupId = hierarchyState.selectedSubGroup?.id;
    final AsyncValue<List<Category>>? categoriesAsync =
        selectedSubGroupId != null && selectedSubGroupId > 0
        ? ref.watch(categoriesProvider(selectedSubGroupId))
        : null;

    final String? activeError = errorMessage ?? hierarchyState.validationError;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: activeError != null ? AppColors.error : AppColors.border,
          width: activeError != null ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Industry Classification * (Required for $roleName)',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Industry -> Business Group -> SubGroup -> Category',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Level 1: Industry Dropdown
          _buildTierDropdown<Industry>(
            context: context,
            key: const Key('industryDropdown'),
            label: '1. Core Industry *',
            hintText: 'Select industry sector',
            selectedValue: hierarchyState.selectedIndustry,
            asyncValue: industriesAsync,
            enabled: true,
            getId: (Industry item) => item.id.toString(),
            getLabel: (Industry item) => item.name,
            onChanged: (Industry? selected) {
              notifier.selectIndustry(selected);
            },
            onRetry: () => ref.invalidate(industriesProvider),
          ),
          const SizedBox(height: AppSpacing.md),

          // Level 2: Business Group Dropdown
          _buildTierDropdown<BusinessGroup>(
            context: context,
            key: const Key('businessGroupDropdown'),
            label: '2. Business Group *',
            hintText: selectedIndustryId == null || selectedIndustryId <= 0
                ? 'Select an industry first'
                : 'Select business group',
            selectedValue: hierarchyState.selectedBusinessGroup,
            asyncValue: businessGroupsAsync,
            enabled: selectedIndustryId != null && selectedIndustryId > 0,
            getId: (BusinessGroup item) => item.id.toString(),
            getLabel: (BusinessGroup item) => item.name,
            onChanged: (BusinessGroup? selected) {
              notifier.selectBusinessGroup(selected);
            },
            onRetry: () {
              if (selectedIndustryId != null && selectedIndustryId > 0) {
                ref.invalidate(businessGroupsProvider(selectedIndustryId));
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Level 3: SubGroup Dropdown
          _buildTierDropdown<SubGroup>(
            context: context,
            key: const Key('subGroupDropdown'),
            label: '3. SubGroup *',
            hintText: selectedGroupId == null || selectedGroupId <= 0
                ? 'Select a business group first'
                : 'Select sub-group',
            selectedValue: hierarchyState.selectedSubGroup,
            asyncValue: subGroupsAsync,
            enabled: selectedGroupId != null && selectedGroupId > 0,
            getId: (SubGroup item) => item.id.toString(),
            getLabel: (SubGroup item) => item.name,
            onChanged: (SubGroup? selected) {
              notifier.selectSubGroup(selected);
            },
            onRetry: () {
              if (selectedGroupId != null && selectedGroupId > 0) {
                ref.invalidate(subGroupsProvider(selectedGroupId));
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Level 4: Category Dropdown
          _buildTierDropdown<Category>(
            context: context,
            key: const Key('categoryDropdown'),
            label: '4. Specific Category *',
            hintText: selectedSubGroupId == null || selectedSubGroupId <= 0
                ? 'Select a sub-group first'
                : 'Select category',
            selectedValue: hierarchyState.selectedCategory,
            asyncValue: categoriesAsync,
            enabled: selectedSubGroupId != null && selectedSubGroupId > 0,
            getId: (Category item) => item.id.toString(),
            getLabel: (Category item) => item.name,
            onChanged: (Category? selected) {
              notifier.selectCategory(selected);
            },
            onRetry: () {
              if (selectedSubGroupId != null && selectedSubGroupId > 0) {
                ref.invalidate(categoriesProvider(selectedSubGroupId));
              }
            },
          ),

          // Validation Error Banner
          if (activeError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const Key('industryValidationErrorBanner'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      activeError,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Selected Path Display (when complete)
          if (hierarchyState.isComplete) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Classification Path: ${hierarchyState.toSelection()!.displayPath}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierDropdown<T>({
    required BuildContext context,
    required Key key,
    required String label,
    required String hintText,
    required T? selectedValue,
    required AsyncValue<List<T>>? asyncValue,
    required bool enabled,
    required String Function(T) getId,
    required String Function(T) getLabel,
    required ValueChanged<T?> onChanged,
    required VoidCallback onRetry,
  }) {
    if (!enabled || asyncValue == null) {
      return AppDropdown<T>(
        key: key,
        label: label,
        hintText: hintText,
        enabled: false,
        items: <AppDropdownItem<T>>[],
      );
    }

    return asyncValue.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Loading catalog from server...',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      error: (Object error, StackTrace stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Master data unavailable',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
      data: (List<T> items) {
        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'No items found.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Map items to AppDropdownItem
        final List<AppDropdownItem<T>> dropdownItems = items.map((T item) {
          return AppDropdownItem<T>(value: item, label: getLabel(item));
        }).toList();

        // Check if current selectedValue is present in list
        T? effectiveValue = selectedValue;
        if (effectiveValue != null) {
          final T current = effectiveValue;
          if (!items.any((T it) => getId(it) == getId(current))) {
            effectiveValue = null;
          }
        }

        return AppDropdown<T>(
          key: key,
          label: label,
          hintText: hintText,
          value: effectiveValue,
          items: dropdownItems,
          onChanged: onChanged,
        );
      },
    );
  }
}
