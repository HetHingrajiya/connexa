import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/presentation/job_apply_sheet.dart';
import 'package:connexa/features/recruitment/providers/job_providers.dart';

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<JobOpeningDetail> jobAsync =
        ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job opening link copied!')),
              );
            },
          ),
        ],
      ),
      body: jobAsync.when(
        data: (JobOpeningDetail job) => _buildContent(context, ref, job),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load job: $err'),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                text: 'Retry',
                onPressed: () => ref.invalidate(jobDetailProvider(jobId)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, JobOpeningDetail job) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
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
                                  job.title,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      job.employerCompanyName ??
                                          job.employerName,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (job.isEmployerVerified) ...<Widget>[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
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
                              horizontal: 10,
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
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),

                      // Quick Overview Specs Grid
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _buildSpecTile(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Salary',
                              value: job.salaryDisplay,
                            ),
                          ),
                          Expanded(
                            child: _buildSpecTile(
                              icon: Icons.history_rounded,
                              label: 'Experience',
                              value: job.experienceDisplay,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _buildSpecTile(
                              icon: Icons.work_outline_rounded,
                              label: 'Job Type',
                              value: job.jobType,
                            ),
                          ),
                          Expanded(
                            child: _buildSpecTile(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: '${job.city}, ${job.state}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Openings & Details
                Text('Overview & Requirements',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                _buildInfoRow('Number of Openings', '${job.openingsCount}'),
                _buildInfoRow('Workplace Mode', job.workplaceType),
                if (job.department != null)
                  _buildInfoRow('Department', job.department!),
                if (job.educationRequirements != null)
                  _buildInfoRow('Education', job.educationRequirements!),
                if (job.address != null)
                  _buildInfoRow('Address / Site', job.address!),
                const SizedBox(height: AppSpacing.lg),

                // Skills Tags
                if (job.requiredSkillsJson != null &&
                    job.requiredSkillsJson!.isNotEmpty) ...<Widget>[
                  Text('Required Skills & Tools',
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: job.requiredSkillsJson!
                        .split(',')
                        .map((s) => Chip(
                              label: Text(s.trim()),
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Description
                Text('Job Description',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    job.description,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),

        // Bottom Action Bar
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildBottomActions(context, ref, job),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
      BuildContext context, WidgetRef ref, JobOpeningDetail job) {
    if (job.isOwner) {
      return Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.people_outline_rounded),
              label: Text('Applicants (${job.applicationsCount})'),
              onPressed: () => context.push('/jobs/${job.id}/applicants'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton.primary(
              text: 'Edit Opening',
              onPressed: () => context.push('/jobs/edit/${job.id}'),
            ),
          ),
        ],
      );
    }

    if (job.hasApplied) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Application Submitted',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (job.myApplicationId != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: () =>
                  context.push('/job-applications/${job.myApplicationId}'),
              child: const Text('View Details'),
            ),
          ],
        ],
      );
    }

    if (job.status != JobOpeningStatus.open) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'This job opening is closed',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return AppButton.primary(
      text: 'Apply for this Position',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => JobApplySheet(job: job),
        );
      },
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

