import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/core/widgets/app_feedback_states.dart';
import 'package:connexa/core/widgets/app_search_field.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';
import 'package:connexa/features/job_work/providers/job_work_providers.dart';

class JobWorkMarketplaceScreen extends ConsumerStatefulWidget {
  const JobWorkMarketplaceScreen({super.key});

  @override
  ConsumerState<JobWorkMarketplaceScreen> createState() =>
      _JobWorkMarketplaceScreenState();
}

class _JobWorkMarketplaceScreenState
    extends ConsumerState<JobWorkMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _popularProcesses = <String>[
    'All',
    'CNC Milling',
    'CNC Turning',
    'Laser Cutting',
    'Sheet Metal Fabrication',
    'Injection Molding',
    'Die Casting',
    'Precision Grinding',
    'TIG/MIG Welding',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        title: const Text(
          'Industrial Job Work',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Job Work Orders',
            onPressed: () => context.push('/job-work-orders'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const <Widget>[
            Tab(text: 'Marketplace'),
            Tab(text: 'My Requirements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildMarketplaceTab(),
          _buildMyRequirementsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Requirement',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/job-works/create'),
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    final JobWorkMarketplaceState state =
        ref.watch(jobWorkMarketplaceProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(jobWorkMarketplaceProvider.notifier)
          .loadMarketplace(isRefresh: true),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSearchField(
                    controller: _searchController,
                    hintText: 'Search machine, process, tolerance, material...',
                    onSubmitted: (String val) {
                      ref
                          .read(jobWorkMarketplaceProvider.notifier)
                          .setSearch(val.trim().isEmpty ? null : val.trim());
                    },
                    onClear: () {
                      _searchController.clear();
                      ref
                          .read(jobWorkMarketplaceProvider.notifier)
                          .setSearch(null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildProcessChips(state.selectedProcess),
                ],
              ),
            ),
          ),
          if (state.isLoading && state.requirements.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: AppLoadingIndicator(
                    message: 'Loading job work requirements...'),
              ),
            )
          else if (state.errorMessage != null && state.requirements.isEmpty)
            SliverFillRemaining(
              child: AppErrorState(
                title: 'Failed to load requirements',
                description: state.errorMessage!,
                onRetry: () => ref
                    .read(jobWorkMarketplaceProvider.notifier)
                    .loadMarketplace(isRefresh: true),
              ),
            )
          else if (state.requirements.isEmpty)
            const SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.precision_manufacturing_outlined,
                title: 'No Job Work Requirements Found',
                description:
                    'Be the first to post a manufacturing or machining requirement!',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final JobWorkRequirement req = state.requirements[index];
                    return _buildRequirementCard(req);
                  },
                  childCount: state.requirements.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessChips(String? selectedProcess) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _popularProcesses.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final String process = _popularProcesses[index];
          final bool isSelected = process == 'All'
              ? (selectedProcess == null)
              : (selectedProcess?.toLowerCase() == process.toLowerCase());

          return FilterChip(
            label: Text(process),
            selected: isSelected,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            checkmarkColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            onSelected: (bool selected) {
              if (process == 'All') {
                ref.read(jobWorkMarketplaceProvider.notifier).setProcess(null);
              } else {
                ref
                    .read(jobWorkMarketplaceProvider.notifier)
                    .setProcess(selected ? process : null);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildRequirementCard(JobWorkRequirement req) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/job-works/${req.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Requirement Number & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    req.requirementNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      req.status.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                req.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Company & Verification Badge
              Row(
                children: <Widget>[
                  const Icon(Icons.business_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      req.ownerCompanyName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (req.ownerIsVerified) ...<Widget>[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0D9488),
                      size: 15,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Technical Spec Badges
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _buildSpecBadge(Icons.precision_manufacturing_rounded,
                      req.jobWorkProcess, const Color(0xFFEEF2FF), const Color(0xFF4338CA)),
                  if (req.machineType != null && req.machineType!.isNotEmpty)
                    _buildSpecBadge(Icons.settings_suggest_rounded,
                        req.machineType!, const Color(0xFFF0FDF4), const Color(0xFF15803D)),
                  if (req.requiredTolerance != null &&
                      req.requiredTolerance!.isNotEmpty)
                    _buildSpecBadge(Icons.straighten_rounded,
                        'Tol: ${req.requiredTolerance}', const Color(0xFFFFFBEB), const Color(0xFFB45309)),
                  if (req.materialType != null && req.materialType!.isNotEmpty)
                    _buildSpecBadge(Icons.category_outlined,
                        req.materialType!, const Color(0xFFF8FAFC), const Color(0xFF475569)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // Footer: Quantity, Location & Quotations Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        req.formattedQuantity,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 2),
                      Text(
                        req.locationSummary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.request_quote_outlined,
                          size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        '${req.quotationsCount} ${req.quotationsCount == 1 ? 'quote' : 'quotes'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
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

  Widget _buildSpecBadge(
      IconData icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequirementsTab() {
    final MyJobWorkRequirementsState state =
        ref.watch(myJobWorkRequirementsProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(myJobWorkRequirementsProvider.notifier)
          .loadMyRequirements(),
      child: state.isLoading && state.requirements.isEmpty
          ? const Center(
              child:
                  AppLoadingIndicator(message: 'Loading your requirements...'))
          : state.errorMessage != null && state.requirements.isEmpty
              ? AppErrorState(
                  title: 'Failed to load requirements',
                  description: state.errorMessage!,
                  onRetry: () => ref
                      .read(myJobWorkRequirementsProvider.notifier)
                      .loadMyRequirements(),
                )
              : state.requirements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.post_add_rounded,
                            size: 64,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'No Job Work Requirements Posted',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Post a manufacturing requirement to receive quotations.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton.primary(
                            text: 'Post New Requirement',
                            onPressed: () => context.push('/job-works/create'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.requirements.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == state.requirements.length) {
                          return const SizedBox(height: 80);
                        }
                        return _buildRequirementCard(state.requirements[index]);
                      },
                    ),
    );
  }
}

