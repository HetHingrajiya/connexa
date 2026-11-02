import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/providers/job_providers.dart';

class JobApplicantsScreen extends ConsumerWidget {
  const JobApplicantsScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<JobApplicationSummary>> applicantsAsync =
        ref.watch(jobApplicantsForPostProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Applications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(jobApplicantsForPostProvider(jobId)),
        child: applicantsAsync.when(
          data: (List<JobApplicationSummary> applicants) {
            if (applicants.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 500,
                  alignment: Alignment.center,
                  child: const AppEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Applications Yet',
                    description:
                        'Candidates have not applied for this opening yet. Ensure details and salary expectations are clear.',
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: applicants.length,
              itemBuilder: (BuildContext context, int index) {
                final JobApplicationSummary app = applicants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        context.push('/job-applications/${app.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  app.fullName.isNotEmpty
                                      ? app.fullName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      app.fullName,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${app.yearsOfExperience} yrs exp • ${app.currentDesignation ?? "Industrial Worker"}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
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
                                  color: app.status.color
                                      .withValues(alpha: 0.12),
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
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                app.expectedSalary != null
                                    ? 'Expected: ₹${app.expectedSalary!.toStringAsFixed(0)}/mo'
                                    : 'Salary: Negotiable',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Applied: ${app.createdAtUtc.day}/${app.createdAtUtc.month}/${app.createdAtUtc.year}',
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
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text('Error: $err'),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  text: 'Retry',
                  onPressed: () =>
                      ref.invalidate(jobApplicantsForPostProvider(jobId)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

