import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/directory/models/directory_models.dart';
import 'package:connexa/features/directory/providers/directory_provider.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';

/// Screen displaying the paginated, searchable Business Directory backed by SQL Server.
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    ref.read(directoryNotifierProvider.notifier).setSearch(value);
  }

  void _showBusinessDetailsModal(
    BuildContext context,
    BusinessDirectoryItem item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext sheetCtx, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          item.companyName.isNotEmpty
                              ? item.companyName.substring(0, 1).toUpperCase()
                              : 'B',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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
                              ),
                            ),
                            Text(
                              'Contact: ${item.contactPersonName}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Industry Classification',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Text(
                      '${item.industryName}  ›  ${item.businessGroupName}  ›  ${item.subGroupName}  ›  ${item.categoryName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (item.businessCapabilities.isNotEmpty) ...<Widget>[
                    const Text(
                      'Capabilities',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: item.businessCapabilities.map((String c) {
                        return Chip(
                          label: Text(c, style: AppTextStyles.labelSmall),
                          backgroundColor: AppColors.secondaryContainer,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (item.businessDescription != null &&
                      item.businessDescription!.isNotEmpty) ...<Widget>[
                    const Text(
                      'About the Company',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.businessDescription!,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const Text(
                    'Contact & Verification',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.email_outlined, size: 20),
                    title: Text(item.email),
                    subtitle: const Text('Verified Email'),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.phone_outlined, size: 20),
                    title: Text(item.phoneNumber),
                    subtitle: const Text('Verified Mobile'),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.verified_outlined,
                      size: 20,
                      color: AppColors.success,
                    ),
                    title: Text('Verified Member #${item.memberId}'),
                    subtitle: Text(
                      'Member since ${item.memberSinceUtc.day}/${item.memberSinceUtc.month}/${item.memberSinceUtc.year}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    text: 'Close',
                    isFullWidth: true,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            key: const Key('directoryFilterToggleButton'),
            icon: Icon(
              _filtersExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: _filtersExpanded ? AppColors.secondary : null,
            ),
            tooltip: 'Toggle Filters',
            onPressed: () {
              setState(() {
                _filtersExpanded = !_filtersExpanded;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
              const SizedBox(height: AppSpacing.sm),

              // Search Bar
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: const Key('directorySearchTextField'),
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search company, person, or keywords...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchSubmitted('');
                                },
                              )
                            : null,
                      ),
                      onSubmitted: _onSearchSubmitted,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    key: const Key('directorySearchSubmitButton'),
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _onSearchSubmitted(_searchController.text),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Expandable 4-Tier Filter Panel
              if (_filtersExpanded) ...<Widget>[
                _buildFilterPanel(state, notifier),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Results Count Bar
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
                    if (state.filter.industryId != null ||
                        state.filter.capability != null ||
                        (state.filter.search != null &&
                            state.filter.search!.isNotEmpty))
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Reset Filters'),
                        onPressed: () {
                          _searchController.clear();
                          notifier.resetFilters();
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Area: Loading, Error, Empty or List
              Expanded(child: _buildContentArea(state, notifier)),

              // Pagination Footer
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
          actionLabel: 'Clear Filters',
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.companyName,
                      key: Key('businessItemName_${item.memberId}'),
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 16,
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
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                tooltip: 'View Details',
                onPressed: () => _showBusinessDetailsModal(context, item),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 4-Tier Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Text(
              '${item.industryName} › ${item.categoryName}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Capabilities
          if (item.businessCapabilities.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: item.businessCapabilities.take(3).map((String cap) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    cap,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(DirectoryState state, DirectoryNotifier notifier) {
    final AsyncValue<List<Industry>> industriesAsync = ref.watch(
      industriesProvider,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Filter by Industry Classification',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Industry Dropdown
          industriesAsync.when(
            data: (List<Industry> industries) {
              return DropdownButtonFormField<int?>(
                key: const Key('directoryIndustryFilterDropdown'),
                isExpanded: true,
                initialValue: state.filter.industryId,
                decoration: const InputDecoration(
                  labelText: 'Select Industry',
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

          // Business Group Dropdown
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
                        labelText: 'Select Business Group',
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Groups'),
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

          // Category Dropdown
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
                        labelText: 'Select Category',
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
                  error: (Object e, _) => Text('Error: $e'),
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
          TextButton.icon(
            key: const Key('directoryPrevPageButton'),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            onPressed: state.currentPage > 1
                ? () => notifier.setPage(state.currentPage - 1)
                : null,
          ),
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: AppTextStyles.labelMedium,
          ),
          TextButton.icon(
            key: const Key('directoryNextPageButton'),
            label: const Text('Next'),
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentPage < state.totalPages
                ? () => notifier.setPage(state.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
