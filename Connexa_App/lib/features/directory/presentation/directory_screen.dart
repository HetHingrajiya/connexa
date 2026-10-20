import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/connections/providers/connection_provider.dart';
import 'package:connexa/features/connections/services/connection_service.dart';
import 'package:connexa/features/directory/models/directory_models.dart';
import 'package:connexa/features/directory/providers/directory_provider.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';

/// Screen displaying the paginated, searchable Business Directory backed by real SQL Server data.
class BusinessDirectoryScreen extends ConsumerStatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  ConsumerState<BusinessDirectoryScreen> createState() =>
      _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState
    extends ConsumerState<BusinessDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = false;

  static const List<String> _businessTypeOptions = <String>[
    'All',
    'Manufacturer / Company',
    'Contractor / Job Worker',
    'Trader / Supplier',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(directoryNotifierProvider.notifier).setSearch(value);
  }

  void _onSearchSubmitted(String value) {
    ref
        .read(directoryNotifierProvider.notifier)
        .setSearch(value, immediate: true);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(directoryNotifierProvider.notifier).setSearch('', immediate: true);
  }

  void _showBusinessDetailsModal(
    BuildContext context,
    BusinessDirectoryItem item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (BuildContext sheetCtx, ScrollController scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Header Identity
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              width: 2.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              item.companyName.isNotEmpty
                                  ? item.companyName
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'B',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.companyName,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      'Contact: ${item.contactPersonName}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: <Widget>[
                                  _buildBusinessTypeBadge(item.businessType),
                                  const AppBadge.success(
                                    label: 'Verified Member',
                                    icon: Icon(
                                      Icons.verified_rounded,
                                      size: 13,
                                      color: AppColors.onSuccessContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),

                    // Location / Service Area
                    _buildSectionHeader('Location & Service Area'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              item.displayLocation,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 4-Tier Master Data Hierarchy
                    _buildSectionHeader('Industry Classification'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildHierarchyStep(
                            label: 'Industry',
                            value: item.industryName,
                            icon: Icons.domain_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildHierarchyStep(
                            label: 'Business Group',
                            value: item.businessGroupName,
                            icon: Icons.layers_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildHierarchyStep(
                            label: 'SubGroup',
                            value: item.subGroupName,
                            icon: Icons.account_tree_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildHierarchyStep(
                            label: 'Category',
                            value: item.categoryName,
                            icon: Icons.category_rounded,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Capabilities
                    if (item.businessCapabilities.isNotEmpty) ...<Widget>[
                      _buildSectionHeader('Capabilities & Specializations'),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: item.businessCapabilities.map((String c) {
                          return AppBadge.secondary(label: c);
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // About / Description
                    if (item.businessDescription != null &&
                        item.businessDescription!
                            .trim()
                            .isNotEmpty) ...<Widget>[
                      _buildSectionHeader('About the Business'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          item.businessDescription!.trim(),
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Contact & Verification Card
                    _buildSectionHeader('Contact & Verification'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              item.displayEmail,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text('Verified Email'),
                            trailing: const AppBadge.neutral(label: 'Masked'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              item.displayPhone,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text('Verified Mobile'),
                            trailing: const AppBadge.neutral(label: 'Masked'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.successContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppColors.success,
                              ),
                            ),
                            title: Text(
                              'Verified Member #${item.memberId}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Member since ${item.memberSinceUtc.day}/${item.memberSinceUtc.month}/${item.memberSinceUtc.year} (via ${item.verifiedMethod})',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Privacy notice alert
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.infoContainer.withValues(alpha: 0.5),
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Contact details are protected by Connexa Member Privacy. Direct contact is unlocked through mutual Business Connections.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onInfoContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Actions
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton.secondary(
                            text: 'Close',
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildModalActionButton(context, ctx, item),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModalActionButton(
    BuildContext context,
    BuildContext sheetCtx,
    BusinessDirectoryItem item,
  ) {
    switch (item.connectionStatus) {
      case 'Self':
        return const AppButton.secondary(text: 'Your Profile', onPressed: null);
      case 'Connected':
        return AppButton(
          key: const Key('directoryDetailsConnectedButton'),
          text: 'Connected',
          leadingIcon: const Icon(Icons.check_circle_rounded, size: 16),
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          onPressed: () =>
              _handleRemoveConnectionAction(context, sheetCtx, item),
        );
      case 'PendingSent':
        return AppButton(
          key: const Key('directoryDetailsPendingSentButton'),
          text: 'Request Sent',
          leadingIcon: const Icon(Icons.access_time_rounded, size: 16),
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          onPressed: () => _handleCancelSentAction(context, sheetCtx, item),
        );
      case 'PendingReceived':
        return AppButton(
          key: const Key('directoryDetailsPendingReceivedButton'),
          text: 'Respond',
          leadingIcon: const Icon(Icons.mark_email_unread_rounded, size: 16),
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          onPressed: () => _handleRespondAction(context, sheetCtx, item),
        );
      default:
        return AppButton.primary(
          key: const Key('directoryDetailsConnectButton'),
          text: 'Connect',
          leadingIcon: const Icon(Icons.person_add_outlined, size: 18),
          onPressed: () => _handleConnectAction(context, sheetCtx, item),
        );
    }
  }

  Future<void> _handleConnectAction(
    BuildContext context,
    BuildContext sheetCtx,
    BusinessDirectoryItem item,
  ) async {
    final TextEditingController noteCtrl = TextEditingController();
    final bool? send = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: Text('Connect with ${item.companyName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Send a business connection request to ${item.contactPersonName} at ${item.companyName}.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                maxLength: 250,
                decoration: const InputDecoration(
                  labelText: 'Personal Note (Optional)',
                  hintText:
                      'Introduce yourself or describe your business collaboration interest...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton.primary(
              text: 'Send Request',
              height: 38,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    );

    if (send == true && context.mounted) {
      try {
        await ref
            .read(connectionServiceProvider)
            .sendRequest(
              recipientMemberId: item.memberId,
              note: noteCtrl.text.trim().isNotEmpty
                  ? noteCtrl.text.trim()
                  : null,
            );

        if (context.mounted) {
          ref
              .read(directoryNotifierProvider.notifier)
              .updateItemConnectionStatus(item.memberId, 'PendingSent');
          ref.read(connectionsNotifierProvider.notifier).loadAll();

          Navigator.of(sheetCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection request sent to ${item.companyName}!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final String err = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleRemoveConnectionAction(
    BuildContext context,
    BuildContext sheetCtx,
    BusinessDirectoryItem item,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Remove Connection'),
          content: Text(
            'Are you sure you want to remove your connection with ${item.companyName}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Remove',
              height: 38,
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      try {
        await ref
            .read(connectionServiceProvider)
            .removeConnection(item.memberId);
        if (context.mounted) {
          ref
              .read(directoryNotifierProvider.notifier)
              .updateItemConnectionStatus(item.memberId, 'Not Connected');
          ref.read(connectionsNotifierProvider.notifier).loadAll();

          Navigator.of(sheetCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed connection with ${item.companyName}.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final String err = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _handleCancelSentAction(
    BuildContext context,
    BuildContext sheetCtx,
    BusinessDirectoryItem item,
  ) {
    Navigator.of(sheetCtx).pop();
    context.push('/network', extra: 2);
  }

  void _handleRespondAction(
    BuildContext context,
    BuildContext sheetCtx,
    BusinessDirectoryItem item,
  ) {
    Navigator.of(sheetCtx).pop();
    context.push('/network', extra: 1);
  }

  Widget _buildConnectionBadge(String status) {
    switch (status) {
      case 'Connected':
        return const AppBadge.success(
          label: 'Connected',
          icon: Icon(
            Icons.check_circle_rounded,
            size: 11,
            color: AppColors.onSuccessContainer,
          ),
        );
      case 'PendingSent':
        return const AppBadge.warning(label: 'Request Sent');
      case 'PendingReceived':
        return const AppBadge.secondary(label: 'Respond');
      case 'Self':
        return const AppBadge.neutral(label: 'You');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessTypeBadge(String businessType) {
    if (businessType.contains('Manufacturer')) {
      return AppBadge.primary(label: businessType);
    } else if (businessType.contains('Contractor') ||
        businessType.contains('Worker')) {
      return AppBadge.secondary(label: businessType);
    } else if (businessType.contains('Trader') ||
        businessType.contains('Supplier')) {
      return AppBadge.info(label: businessType);
    }
    return AppBadge.neutral(label: businessType);
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildHierarchyStep({
    required String label,
    required String value,
    required IconData icon,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: isLast ? AppColors.secondary : AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value.isNotEmpty ? value : 'Not Specified',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isLast
                      ? AppColors.secondaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DirectoryState state = ref.watch(directoryNotifierProvider);
    final DirectoryNotifier notifier = ref.read(
      directoryNotifierProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Directory'),
        actions: <Widget>[
          IconButton(
            key: const Key('directoryMyNetworkButton'),
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'My Network',
            onPressed: () => context.push('/network'),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: <Widget>[
              IconButton(
                key: const Key('directoryFilterToggleButton'),
                icon: Icon(
                  _filtersExpanded
                      ? Icons.filter_list_off_rounded
                      : Icons.filter_list_rounded,
                  color: (_filtersExpanded || state.hasActiveFilters)
                      ? AppColors.primary
                      : null,
                ),
                tooltip: 'Toggle Filters',
                onPressed: () {
                  setState(() {
                    _filtersExpanded = !_filtersExpanded;
                  });
                },
              ),
              if (state.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadDirectory(),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xs),

              // Modern Search Input
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: const Key('directorySearchTextField'),
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search company, capabilities, keywords...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: _clearSearch,
                              )
                            : null,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    key: const Key('directorySearchSubmitButton'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                    tooltip: 'Search',
                    onPressed: () => _onSearchSubmitted(_searchController.text),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Business Type Filter Chips Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _businessTypeOptions.map((String type) {
                    final bool isSelected =
                        (state.filter.businessType == null && type == 'All') ||
                        state.filter.businessType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (bool selected) {
                          notifier.setBusinessType(type == 'All' ? null : type);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Expandable 4-Tier Master Data Hierarchy Filter Panel
              if (_filtersExpanded) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                _buildHierarchyFilterPanel(state, notifier),
                const SizedBox(height: AppSpacing.xs),
              ],

              // Results Count Bar & Reset Action
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${state.totalCount} businesses found',
                      key: const Key('directoryResultCountText'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (state.hasActiveFilters)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('Reset All'),
                        onPressed: () {
                          _searchController.clear();
                          notifier.resetFilters();
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Area: Loading, Error, Empty or Listing Cards
              Expanded(child: _buildContentArea(state, notifier)),

              // Pagination Footer Bar
              if (state.totalPages > 1) ...<Widget>[
                const Divider(height: 1),
                _buildPaginationBar(state, notifier),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(DirectoryState state, DirectoryNotifier notifier) {
    if (state.isLoading) {
      return const Center(
        child: AppLoadingIndicator(
          message: 'Searching Connexa Business Directory...',
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: AppErrorState(
          title: 'Unable to Load Directory',
          description: state.errorMessage!,
          onRetry: () => notifier.loadDirectory(),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'No Businesses Found',
          description:
              'No businesses match the search or filter criteria. Try adjusting your filters or search keywords.',
          actionLabel: 'Clear All Filters',
          onAction: () {
            _searchController.clear();
            notifier.resetFilters();
          },
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.items.length,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final BusinessDirectoryItem item = state.items[index];
        return _buildBusinessCard(context, item);
      },
    );
  }

  Widget _buildBusinessCard(BuildContext context, BusinessDirectoryItem item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => _showBusinessDetailsModal(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row: Avatar, Name, Verified Badge, Info Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    item.companyName.isNotEmpty
                        ? item.companyName.substring(0, 1).toUpperCase()
                        : 'B',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.companyName,
                            key: Key('businessItemName_${item.memberId}'),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.contactPersonName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Business Type, Location, and Connection Status Badges
          Row(
            children: <Widget>[
              _buildBusinessTypeBadge(item.businessType),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        item.displayLocation,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _buildConnectionBadge(item.connectionStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 4-Tier Hierarchy Breadcrumb
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.account_tree_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${item.industryName}  ›  ${item.categoryName}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Capabilities Chips
          if (item.businessCapabilities.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: item.businessCapabilities.take(4).map((String cap) {
                return AppBadge.secondary(label: cap, isPill: true);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHierarchyFilterPanel(
    DirectoryState state,
    DirectoryNotifier notifier,
  ) {
    final AsyncValue<List<Industry>> industriesAsync = ref.watch(
      industriesProvider,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Expanded(
                child: Text(
                  '4-Tier Industry Hierarchy Filter',
                  style: AppTextStyles.labelMedium,
                ),
              ),
              if (state.filter.industryId != null)
                TextButton(
                  onPressed: () => notifier.setIndustry(null),
                  child: const Text('Clear Hierarchy'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 1. Industry Dropdown
          industriesAsync.when(
            data: (List<Industry> industries) {
              return DropdownButtonFormField<int?>(
                key: const Key('directoryIndustryFilterDropdown'),
                isExpanded: true,
                initialValue: state.filter.industryId,
                decoration: const InputDecoration(
                  labelText: '1. Select Industry',
                  isDense: true,
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Industries'),
                  ),
                  ...industries.map((Industry ind) {
                    return DropdownMenuItem<int?>(
                      value: ind.id,
                      child: Text(ind.name, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (int? id) => notifier.setIndustry(id),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (Object e, _) => Text('Error loading industries: $e'),
          ),

          // 2. Business Group Dropdown
          if (state.filter.industryId != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ref
                .watch(businessGroupsProvider(state.filter.industryId!))
                .when(
                  data: (List<BusinessGroup> groups) {
                    return DropdownButtonFormField<int?>(
                      key: const Key('directoryGroupFilterDropdown'),
                      isExpanded: true,
                      initialValue: state.filter.businessGroupId,
                      decoration: const InputDecoration(
                        labelText: '2. Select Business Group',
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Business Groups'),
                        ),
                        ...groups.map((BusinessGroup g) {
                          return DropdownMenuItem<int?>(
                            value: g.id,
                            child: Text(
                              g.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (int? id) => notifier.setBusinessGroup(id),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (Object e, _) => Text('Error loading groups: $e'),
                ),
          ],

          // 3. SubGroup Dropdown
          if (state.filter.businessGroupId != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ref
                .watch(subGroupsProvider(state.filter.businessGroupId!))
                .when(
                  data: (List<SubGroup> subGroups) {
                    return DropdownButtonFormField<int?>(
                      key: const Key('directorySubGroupFilterDropdown'),
                      isExpanded: true,
                      initialValue: state.filter.subGroupId,
                      decoration: const InputDecoration(
                        labelText: '3. Select SubGroup',
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All SubGroups'),
                        ),
                        ...subGroups.map((SubGroup sg) {
                          return DropdownMenuItem<int?>(
                            value: sg.id,
                            child: Text(
                              sg.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (int? id) => notifier.setSubGroup(id),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (Object e, _) => Text('Error loading subgroups: $e'),
                ),
          ],

          // 4. Category Dropdown
          if (state.filter.subGroupId != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ref
                .watch(categoriesProvider(state.filter.subGroupId!))
                .when(
                  data: (List<Category> categories) {
                    return DropdownButtonFormField<int?>(
                      key: const Key('directoryCategoryFilterDropdown'),
                      isExpanded: true,
                      initialValue: state.filter.categoryId,
                      decoration: const InputDecoration(
                        labelText: '4. Select Category',
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...categories.map((Category c) {
                          return DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (int? id) => notifier.setCategory(id),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (Object e, _) => Text('Error loading categories: $e'),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationBar(DirectoryState state, DirectoryNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          AppButton.secondary(
            key: const Key('directoryPrevPageButton'),
            leadingIcon: const Icon(Icons.chevron_left_rounded, size: 18),
            text: 'Previous',
            height: 38,
            onPressed: (state.currentPage > 1 && !state.isLoading)
                ? () => notifier.setPage(state.currentPage - 1)
                : null,
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppButton.secondary(
            key: const Key('directoryNextPageButton'),
            text: 'Next',
            trailingIcon: const Icon(Icons.chevron_right_rounded, size: 18),
            height: 38,
            onPressed:
                (state.currentPage < state.totalPages && !state.isLoading)
                ? () => notifier.setPage(state.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
