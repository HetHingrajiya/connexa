import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/providers/job_providers.dart';
import 'package:connexa/features/recruitment/services/job_recruitment_service.dart';

class JobApplySheet extends ConsumerStatefulWidget {
  const JobApplySheet({super.key, required this.job});

  final JobOpeningDetail job;

  @override
  ConsumerState<JobApplySheet> createState() => _JobApplySheetState();
}

class _JobApplySheetState extends ConsumerState<JobApplySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _currentCompanyController =
      TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _expController = TextEditingController(text: '0');
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _noticeController =
      TextEditingController(text: '30');
  final TextEditingController _coverLetterController = TextEditingController();
  final TextEditingController _resumeUrlController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.user;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentCompanyController.dispose();
    _designationController.dispose();
    _expController.dispose();
    _salaryController.dispose();
    _noticeController.dispose();
    _coverLetterController.dispose();
    _resumeUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleApply() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final int exp = int.tryParse(_expController.text.trim()) ?? 0;
      final double? salary = double.tryParse(_salaryController.text.trim());
      final int? notice = int.tryParse(_noticeController.text.trim());

      final SubmitJobApplicationRequest req = SubmitJobApplicationRequest(
        jobOpeningId: widget.job.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        currentCompany: _currentCompanyController.text.trim().isNotEmpty
            ? _currentCompanyController.text.trim()
            : null,
        currentDesignation: _designationController.text.trim().isNotEmpty
            ? _designationController.text.trim()
            : null,
        yearsOfExperience: exp,
        expectedSalary: salary,
        noticePeriodDays: notice,
        coverLetter: _coverLetterController.text.trim().isNotEmpty
            ? _coverLetterController.text.trim()
            : null,
        resumeUrl: _resumeUrlController.text.trim().isNotEmpty
            ? _resumeUrlController.text.trim()
            : null,
        resumeFileName: _resumeUrlController.text.trim().isNotEmpty
            ? 'Candidate_Resume.pdf'
            : null,
      );

      await ref.read(jobRecruitmentServiceProvider).applyForJob(req);

      ref.invalidate(jobDetailProvider(widget.job.id));
      ref.invalidate(myJobApplicationsProvider);
      ref.invalidate(jobListingsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Apply for Position',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.job.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Full Name
              AppTextField(
                controller: _nameController,
                label: 'Full Name *',
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Email & Phone
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _emailController,
                      label: 'Email *',
                      keyboardType: TextInputType.emailAddress,
                      validator: (String? val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _phoneController,
                      label: 'Phone *',
                      keyboardType: TextInputType.phone,
                      validator: (String? val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Current Company & Designation
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _currentCompanyController,
                      label: 'Current Employer',
                      hintText: 'e.g. ABC Engineering',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _designationController,
                      label: 'Designation',
                      hintText: 'e.g. Machinist',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Experience, Expected Salary, Notice Period
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _expController,
                      label: 'Exp (Years)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _salaryController,
                      label: 'Expected Salary (₹)',
                      hintText: 'Monthly',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _noticeController,
                      label: 'Notice (Days)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Resume URL / Link
              AppTextField(
                controller: _resumeUrlController,
                label: 'Resume Link (Google Drive / Cloud URL)',
                hintText: 'https://drive.google.com/...',
                prefixIcon: const Icon(Icons.link_rounded),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Cover Letter
              AppTextField(
                controller: _coverLetterController,
                label: 'Cover Letter / Brief Pitch',
                hintText:
                    'Mention relevant machine models, CNC controls (Siemens, Fanuc), and key manufacturing achievements...',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppButton.primary(
                text: 'Submit Application',
                isLoading: _isSubmitting,
                onPressed: _handleApply,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
