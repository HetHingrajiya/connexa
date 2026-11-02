import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/services/models/service_models.dart';
import 'package:connexa/features/services/providers/services_providers.dart';

class ServicesMarketplaceScreen extends ConsumerStatefulWidget {
  const ServicesMarketplaceScreen({super.key});

  @override
  ConsumerState<ServicesMarketplaceScreen> createState() =>
      _ServicesMarketplaceScreenState();
}

class _ServicesMarketplaceScreenState
    extends ConsumerState<ServicesMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('B2B Services Marketplace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const <Widget>[
            Tab(text: 'Explore Services'),
            Tab(text: 'My Services'),
            Tab(text: 'Inquiries'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('postServiceFab'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Offer a Service'),
        onPressed: () => context.push('/services/post'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildExploreTab(),
          _buildMyServicesTab(),
          _buildInquiriesTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: EXPLORE SERVICES
  // ==========================================

  Widget _buildExploreTab() {
    final ServicesMarketplaceState state =
        ref.watch(servicesMarketplaceProvider);
    final AsyncValue<List<String>> categoriesAsync =
        ref.watch(serviceCategoriesProvider);

    return ResponsiveCenterBox(
      padding: AppSpacing.screenPaddingMobile,
      maxTabletWidth: AppSpacing.maxContentWidthTablet,
      maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
      child: RefreshIndicator(
        onRefresh: () => ref
            .read(servicesMarketplaceProvider.notifier)
            .loadServices(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            // Search Input
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: AppTextField(
                  controller: _searchController,
                  hintText: 'Search services, machining, repairs, engineering...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(servicesMarketplaceProvider.notifier)
                                .setSearchQuery(null);
                          },
                        )
                      : null,
                  onSubmitted: (String val) {
                    ref
                        .read(servicesMarketplaceProvider.notifier)
                        .setSearchQuery(val.trim().isEmpty ? null : val.trim());
                  },
                ),
              ),
            ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (List<String> categories) {
                  final List<String> allCats = <String>['All', ...categories];
                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allCats.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (BuildContext context, int index) {
                        final String cat = allCats[index];
                        final bool isSelected = state.selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              ref
                                  .read(servicesMarketplaceProvider.notifier)
                                  .setCategory(cat);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 40),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // Service Type Selector (On-Site, Remote, Workshop, Hybrid)
            SliverToBoxAdapter(
              child: Row(
                children: <Widget>[
                  Text(
                    'Delivery Mode:',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <String>[
                          'All',
                          'On-Site',
                          'Remote',
                          'Workshop',
                          'Hybrid'
                        ].map((String mode) {
                          final bool isSel = state.selectedServiceType == mode;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: FilterChip(
                              label: Text(mode, style: const TextStyle(fontSize: 12)),
                              selected: isSel,
                              onSelected: (_) => ref
                                  .read(servicesMarketplaceProvider.notifier)
                                  .setServiceType(mode),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // Results count
            if (!state.isLoading && state.services.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Found ${state.totalCount} industrial services',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

            // Loading / Error / Empty States
            if (state.isLoading && state.services.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: AppLoadingIndicator(
                    message: 'Loading industrial services...',
                  ),
                ),
              )
            else if (state.errorMessage != null && state.services.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: AppErrorState(
                    title: 'Unable to Load Services',
                    description: state.errorMessage!,
                    onRetry: () => ref
                        .read(servicesMarketplaceProvider.notifier)
                        .loadServices(refresh: true),
                  ),
                ),
              )
            else if (state.services.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.home_repair_service_rounded,
                    title: 'No Services Found',
                    description:
                        'Try adjusting your search terms or filters to discover matching B2B services.',
                  ),
                ),
              )
            else
              // Services List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final ServiceSummary service = state.services[index];
                    return _buildServiceCard(context, service);
                  },
                  childCount: state.services.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceSummary service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: InkWell(
          onTap: () => context.push('/services/${service.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Category & Mode Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  AppBadge.primary(label: service.serviceCategory),
                  AppBadge(
                    label: service.serviceType,
                    variant: AppBadgeVariant.secondary,
                    isPill: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                service.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Provider Information
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.business_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      service.providerCompanyName ?? service.providerName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (service.location != null && service.location!.isNotEmpty) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      service.location!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Description snippet
              Text(
                service.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: AppSpacing.lg),

              // Price & Details Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        service.pricingModel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        service.startingPrice != null
                            ? '₹${service.startingPrice!.toStringAsFixed(0)}${service.priceUnit != null ? " ${service.priceUnit}" : ""}'
                            : 'Custom Quote',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (service.turnaroundTime != null)
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.turnaroundTime!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MY SERVICES
  // ==========================================

  Widget _buildMyServicesTab() {
    final MyServicesState state = ref.watch(myServicesProvider);

    return ResponsiveCenterBox(
      padding: AppSpacing.screenPaddingMobile,
      maxTabletWidth: AppSpacing.maxContentWidthTablet,
      maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
      child: RefreshIndicator(
        onRefresh: () => ref.read(myServicesProvider.notifier).loadMyServices(),
        child: state.isLoading
            ? const Center(
                child: AppLoadingIndicator(message: 'Loading your services...'),
              )
            : state.services.isEmpty
                ? Center(
                    child: AppEmptyState(
                      icon: Icons.design_services_outlined,
                      title: 'No Published Services',
                      description:
                          'Offer your technical, engineering, or maintenance services to thousands of verified businesses.',
                      actionLabel: 'Publish Your First Service',
                      onAction: () => context.push('/services/post'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: 80,
                    ),
                    itemCount: state.services.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ServiceSummary s = state.services[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  AppBadge.primary(label: s.serviceCategory),
                                  const Spacer(),
                                  AppBadge(
                                    label: s.isActive ? 'Active' : 'Inactive',
                                    variant: s.isActive
                                        ? AppBadgeVariant.success
                                        : AppBadgeVariant.warning,
                                    isPill: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                s.title,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                s.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    s.startingPrice != null
                                        ? '₹${s.startingPrice!.toStringAsFixed(0)} ${s.priceUnit ?? ""}'
                                        : 'Quote Based',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        tooltip: 'Edit Service',
                                        onPressed: () => context.push(
                                          '/services/edit/${s.id}',
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: AppColors.error,
                                        ),
                                        tooltip: 'Delete / Deactivate',
                                        onPressed: () =>
                                            _confirmDeleteService(s),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                        tooltip: 'View Details',
                                        onPressed: () => context.push(
                                          '/services/${s.id}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _confirmDeleteService(ServiceSummary service) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to remove "${service.title}"? If inquiries already exist, the service will be deactivated.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton.primary(
            text: 'Confirm',
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final bool ok = await ref
                  .read(myServicesProvider.notifier)
                  .deleteService(service.id);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service updated successfully.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: INQUIRIES
  // ==========================================

  Widget _buildInquiriesTab() {
    final ServiceInquiriesState state = ref.watch(serviceInquiriesProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Container(
            color: AppColors.surface,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: <Widget>[
                Tab(text: 'Received Inquiries'),
                Tab(text: 'Sent Inquiries'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _buildInquiryList(state.receivedInquiries, isReceived: true),
                _buildInquiryList(state.sentInquiries, isReceived: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryList(List<ServiceInquiry> inquiries,
      {required bool isReceived}) {
    if (inquiries.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.chat_outlined,
          title: isReceived ? 'No Received Inquiries' : 'No Sent Inquiries',
          description: isReceived
              ? 'When buyers inquire about your services, they will appear here.'
              : 'Services you inquire about will be tracked here.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(serviceInquiriesProvider.notifier).loadInquiries(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: inquiries.length,
        itemBuilder: (BuildContext context, int index) {
          final ServiceInquiry inq = inquiries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: InkWell(
                onTap: () => context.push('/service-inquiries/${inq.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          inq.inquiryNumber,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: inq.status.color.withValues(alpha: 0.15),
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            inq.status.label,
                            style: TextStyle(
                              color: inq.status.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      inq.serviceTitle,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isReceived
                          ? 'From: ${inq.senderCompanyName ?? inq.senderName}'
                          : 'To: ${inq.recipientCompanyName ?? inq.recipientName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      inq.subject,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (inq.estimatedBudget != null)
                          Text(
                            'Budget: ₹${inq.estimatedBudget!.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
