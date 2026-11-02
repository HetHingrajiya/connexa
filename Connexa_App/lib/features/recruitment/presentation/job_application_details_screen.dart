import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/providers/job_providers.dart';
import 'package:connexa/features/recruitment/services/job_recruitment_service.dart';

class JobApplicationDetailsScreen extends ConsumerStatefulWidget {
  const JobApplicationDetailsScreen({super.key, required this.applicationId});

  final int applicationId;

  @override
  ConsumerState<JobApplicationDetailsScreen> createState() =>
      _JobApplicationDetailsScreenState();
}

class _JobApplicationDetailsScreenState
    extends ConsumerState<JobApplicationDetailsScreen> {
  bool _isProcessing = false;

  void _showStatusDialog(JobApplicationDetail app) {
    JobApplicationStatus selectedStatus = app.status;
    final TextEditingController remarksController = TextEditingController();
    final TextEditingController notesController =
        TextEditingController(text: app.employerNotes ?? '');

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext modalCtx, StateSetter setModalState) =>
            AlertDialog(
          title: const Text('Update Application Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Application #${app.applicationNumber}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<JobApplicationStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: const <DropdownMenuItem<JobApplicationStatus>>[
                    DropdownMenuItem<JobApplicationStatus>(
                      value: JobApplicationStatus.submitted,
                      child: Text('Submitted'),
                    ),
                    DropdownMenuItem<JobApplicationStatus>(
                      value: JobApplicationStatus.underReview,
                      child: Text('Under Review'),
                    ),
                    DropdownMenuItem<JobApplicationStatus>(
                      value: JobApplicationStatus.shortlisted,
                      child: Text('Shortlisted'),
                    ),
                    DropdownMenuItem<JobApplicationStatus>(
                      value: JobApplicationStatus.accepted,
                      child: Text('Accepted / Offered'),
                    ),
                    DropdownMenuItem<JobApplicationStatus>(
                      value: JobApplicationStatus.rejected,
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (JobApplicationStatus? val) {
                    if (val != null) {
                      setModalState(() => selectedStatus = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: remarksController,
                  label: 'Remarks for Candidate (Optional)',
                  hintText: 'e.g. Scheduled for interview on Thursday...',
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: notesController,
                  label: 'Internal Employer Notes',
                  hintText: 'Visible only to your hiring team...',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            AppButton.primary(
              text: 'Save Status',
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isProcessing = true);
                try {
                  final UpdateJobApplicationStatusRequest req =
                      UpdateJobApplicationStatusRequest(
                    status: selectedStatus,
                    remarks: remarksController.text.trim().isNotEmpty
                        ? remarksController.text.trim()
                        : null,
                    employerNotes: notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : null,
                  );

                  await ref
                      .read(jobRecruitmentServiceProvider)
                      .updateApplicationStatus(app.id, req);

                  ref.invalidate(
                      jobApplicationDetailProvider(widget.applicationId));
                  ref.invalidate(
                      jobApplicantsForPostProvider(app.jobOpeningId));

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update status: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmWithdraw(JobApplicationDetail app) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text(
          'Are you sure you want to withdraw your application? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton.primary(
            text: 'Withdraw',
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isProcessing = true);
              try {
                final bool ok = await ref
                    .read(jobRecruitmentServiceProvider)
                    .withdrawApplication(app.id);

                ref.invalidate(
                    jobApplicationDetailProvider(widget.applicationId));
                ref.invalidate(myJobApplicationsProvider);

                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application withdrawn successfully.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to withdraw: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<JobApplicationDetail> appAsync =
        ref.watch(jobApplicationDetailProvider(widget.applicationId));
    final int? currentUserId = ref.watch(authProvider).user?.memberId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
      ),
      body: appAsync.when(
        data: (JobApplicationDetail app) {
          final bool isApplicant = app.applicantMemberId == currentUserId;
          final bool isEmployer = !isApplicant;

          return Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Header Card
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        app.jobTitle,
                                        style: AppTextStyles.titleLarge
                                            .copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Ref: #${app.applicationNumber}',
                                        style:
                                            AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontFamily: 'monospace',
                                        ),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Candidate Details Section
                      Text('Candidate Profile',
                          style: AppTextStyles.titleMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.xs),
                      _buildInfoTile('Full Name', app.fullName),
                      _buildInfoTile('Email', app.email, isEmail: true),
                      _buildInfoTile('Phone', app.phone, isPhone: true),
                      if (app.currentCompany != null)
                        _buildInfoTile(
                            'Current Employer', app.currentCompany!),
                      if (app.currentDesignation != null)
                        _buildInfoTile(
                            'Designation', app.currentDesignation!),
                      _buildInfoTile(
                          'Experience', '${app.yearsOfExperience} Years'),
                      if (app.expectedSalary != null)
                        _buildInfoTile('Expected Salary',
                            '₹${app.expectedSalary!.toStringAsFixed(0)} / Month'),
                      if (app.noticePeriodDays != null)
                        _buildInfoTile('Notice Period',
                            '${app.noticePeriodDays} Days'),
                      const SizedBox(height: AppSpacing.md),

                      // Resume Link
                      if (app.resumeUrl != null &&
                          app.resumeUrl!.isNotEmpty) ...<Widget>[
                        Text('Candidate Resume',
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.picture_as_pdf_rounded,
                                  color: Color(0xFF2563EB)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  app.resumeFileName ?? 'Resume Document',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy Link'),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: app.resumeUrl!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Resume URL copied to clipboard!'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Cover Letter
                      if (app.coverLetter != null &&
                          app.coverLetter!.isNotEmpty) ...<Widget>[
                        Text('Cover Letter',
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            app.coverLetter!,
                            style: AppTextStyles.bodyMedium
                                .copyWith(height: 1.4),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Internal Employer Notes (visible only to employer)
                      if (isEmployer && app.employerNotes != null) ...<Widget>[
                        Text('Internal Notes',
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            app.employerNotes!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: const Color(0xFF92400E)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Timeline Audit Trail
                      Text('Application Timeline',
                          style: AppTextStyles.titleMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.xs),
                      if (app.statusHistory.isEmpty)
                        Text(
                          'Submitted on ${app.createdAtUtc.day}/${app.createdAtUtc.month}/${app.createdAtUtc.year}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: app.statusHistory.length,
                          itemBuilder: (BuildContext context, int idx) {
                            final JobApplicationStatusHistory item =
                                app.statusHistory[idx];
                            return _buildTimelineTile(item);
                          },
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
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border:
                        Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: isEmployer
                      ? AppButton.primary(
                          text: 'Change Application Status',
                          isLoading: _isProcessing,
                          onPressed: () => _showStatusDialog(app),
                        )
                      : (app.status != JobApplicationStatus.withdrawn
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                    color: AppColors.error),
                                minimumSize:
                                    const Size(double.infinity, 48),
                              ),
                              onPressed: () => _confirmWithdraw(app),
                              child: const Text('Withdraw Application'),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Text('Failed to load application: $err'),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value,
      {bool isEmail = false, bool isPhone = false}) {
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
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: (isEmail || isPhone)
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(JobApplicationStatusHistory item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.newStatus.color,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      item.statusName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: item.newStatus.color,
                      ),
                    ),
                    Text(
                      '${item.changedAtUtc.day}/${item.changedAtUtc.month} ${item.changedAtUtc.hour.toString().padLeft(2, '0')}:${item.changedAtUtc.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  'By ${item.changedByName}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (item.remarks != null && item.remarks!.isNotEmpty)
                  Text(
                    item.remarks!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
