import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/providers/job_providers.dart';

class JobListingsScreen extends ConsumerStatefulWidget {
  const JobListingsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<JobListingsScreen> createState() => _JobListingsScreenState();
}

class _JobListingsScreenState extends ConsumerState<JobListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _jobTypes = const <String>[
    'All',
    'Full-time',
    'Part-time',
    'Contract',
    'Shift-based',
    'Internship',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(jobListingsProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Industrial Job Board'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Explore Jobs'),
            Tab(text: 'My Postings'),
            Tab(text: 'My Applications'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('postJobOpeningFab'),
        onPressed: () => context.push('/jobs/post'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a Job'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildExploreJobsTab(),
          _buildMyPostingsTab(),
          _buildMyApplicationsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: EXPLORE JOBS
  // ==========================================
  Widget _buildExploreJobsTab() {
    final JobListingsState state = ref.watch(jobListingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(jobListingsProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Search Bar
                  AppTextField(
                    controller: _searchController,
                    hintText: 'Search roles, skills, machine operators...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(jobListingsProvider.notifier).search('');
                            },
                          )
                        : null,
                    onChanged: (String val) {
                      ref.read(jobListingsProvider.notifier).search(val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Job Type Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _jobTypes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (BuildContext context, int index) {
                        final String type = _jobTypes[index];
                        final bool isSelected =
                            state.selectedJobType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              ref
                                  .read(jobListingsProvider.notifier)
                                  .setJobType(type);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Job Listings List
          if (state.isLoading && state.jobs.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.jobs.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.work_outline_rounded,
                title: 'No Job Openings Found',
                description:
                    'Try adjusting your search query or filters to discover active hiring vacancies.',
                actionLabel: 'Post a New Job Opening',
                onAction: () => context.push('/jobs/post'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final JobOpeningSummary job = state.jobs[index];
                    return _buildJobCard(job);
                  },
                  childCount: state.jobs.length,
                ),
              ),
            ),

          if (state.isLoading && state.jobs.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobOpeningSummary job) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Title & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          job.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                job.employerCompanyName ?? job.employerName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (job.isEmployerVerified) ...<Widget>[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: job.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      job.status.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: job.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Badges: Location, Workplace, JobType
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _buildTagBadge(Icons.location_on_outlined,
                      '${job.city}, ${job.state}'),
                  _buildTagBadge(Icons.work_outline_rounded, job.jobType),
                  _buildTagBadge(Icons.business_outlined, job.workplaceType),
                  _buildTagBadge(Icons.history_rounded, job.experienceDisplay),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Footer: Salary & Applications Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    job.salaryDisplay,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${job.applicationsCount} applied',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MY POSTINGS (EMPLOYER)
  // ==========================================
  Widget _buildMyPostingsTab() {
    final MyJobPostingsState state = ref.watch(myJobPostingsProvider);

    if (state.isLoading && state.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.read(myJobPostingsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 500,
            alignment: Alignment.center,
            child: AppEmptyState(
              icon: Icons.post_add_rounded,
              title: 'No Active Job Postings',
              description:
                  'Hire verified machinists, engineers, technicians, and industrial operators.',
              actionLabel: 'Post Your First Job',
              onAction: () => context.push('/jobs/post'),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(myJobPostingsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 80,
        ),
        itemCount: state.jobs.length,
        itemBuilder: (BuildContext context, int index) {
          final JobOpeningSummary job = state.jobs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          job.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: job.status.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.status.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: job.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${job.city}, ${job.state} • ${job.jobType} • ${job.openingsCount} Openings',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.people_outline_rounded, size: 16),
                        label: Text('Applicants (${job.applicationsCount})'),
                        onPressed: () =>
                            context.push('/jobs/${job.id}/applicants'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Job',
                        onPressed: () => context.push('/jobs/edit/${job.id}'),
                      ),
                      if (job.status == JobOpeningStatus.open)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: AppColors.error),
                          tooltip: 'Close Opening',
                          onPressed: () => _confirmCloseJob(job),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmCloseJob(JobOpeningSummary job) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Close Job Opening'),
        content: Text(
          'Are you sure you want to close "${job.title}"? Candidates will no longer be able to submit applications.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton.primary(
            text: 'Close Opening',
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final bool ok = await ref
                  .read(myJobPostingsProvider.notifier)
                  .closeJob(job.id);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job opening closed successfully.'),
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
  // TAB 3: MY APPLICATIONS (CANDIDATE)
  // ==========================================
  Widget _buildMyApplicationsTab() {
    final MyJobApplicationsState state = ref.watch(myJobApplicationsProvider);

    if (state.isLoading && state.applications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.applications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async =>
            ref.read(myJobApplicationsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 500,
            alignment: Alignment.center,
            child: AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No Job Applications Yet',
              description:
                  'Apply for industrial engineering, manufacturing, and technician openings on Connexa.',
              actionLabel: 'Browse Job Openings',
              onAction: () => _tabController.animateTo(0),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(myJobApplicationsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 80,
        ),
        itemCount: state.applications.length,
        itemBuilder: (BuildContext context, int index) {
          final JobApplicationSummary app = state.applications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/job-applications/${app.id}'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                app.jobTitle,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (app.employerCompanyName != null) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  app.employerCompanyName!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: app.status.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            app.status.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: app.status.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ref: #${app.applicationNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Applied on ${app.createdAtUtc.day}/${app.createdAtUtc.month}/${app.createdAtUtc.year}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
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

