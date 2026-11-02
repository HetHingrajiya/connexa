import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/recruitment/models/job_models.dart';
import 'package:connexa/features/recruitment/providers/job_providers.dart';
import 'package:connexa/features/recruitment/services/job_recruitment_service.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key, this.jobId});

  final int? jobId;

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _minExpController = TextEditingController();
  final TextEditingController _maxExpController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _openingsController =
      TextEditingController(text: '1');
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _jobType = 'Full-time';
  String _workplaceType = 'On-site';
  String _salaryPeriod = 'Per Month';
  bool _isSaving = false;
  bool _isLoadingExisting = false;

  final List<String> _jobTypes = const <String>[
    'Full-time',
    'Part-time',
    'Contract',
    'Shift-based',
    'Internship',
  ];

  final List<String> _workplaceTypes = const <String>[
    'On-site',
    'Remote',
    'Hybrid',
  ];

  final List<String> _salaryPeriods = const <String>[
    'Per Month',
    'Per Annum',
    'Per Hour',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      _loadExistingJob(widget.jobId!);
    }
  }

  Future<void> _loadExistingJob(int id) async {
    setState(() => _isLoadingExisting = true);
    try {
      final JobOpeningDetail job =
          await ref.read(jobRecruitmentServiceProvider).getJobById(id);
      _titleController.text = job.title;
      _departmentController.text = job.department ?? '';
      _cityController.text = job.city;
      _stateController.text = job.state;
      _addressController.text = job.address ?? '';
      _minExpController.text = job.minExperienceYears.toString();
      _maxExpController.text = job.maxExperienceYears?.toString() ?? '';
      _minSalaryController.text = job.minSalary?.toStringAsFixed(0) ?? '';
      _maxSalaryController.text = job.maxSalary?.toStringAsFixed(0) ?? '';
      _openingsController.text = job.openingsCount.toString();
      _skillsController.text = job.requiredSkillsJson ?? '';
      _educationController.text = job.educationRequirements ?? '';
      _descriptionController.text = job.description;

      _jobType = _jobTypes.contains(job.jobType) ? job.jobType : _jobTypes.first;
      _workplaceType = _workplaceTypes.contains(job.workplaceType)
          ? job.workplaceType
          : _workplaceTypes.first;
      _salaryPeriod = _salaryPeriods.contains(job.salaryPeriod)
          ? job.salaryPeriod
          : _salaryPeriods.first;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load job details: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _departmentController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _minExpController.dispose();
    _maxExpController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _openingsController.dispose();
    _skillsController.dispose();
    _educationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final int minExp = int.tryParse(_minExpController.text.trim()) ?? 0;
      final int? maxExp = int.tryParse(_maxExpController.text.trim());
      final double? minSalary =
          double.tryParse(_minSalaryController.text.trim());
      final double? maxSalary =
          double.tryParse(_maxSalaryController.text.trim());
      final int openings =
          int.tryParse(_openingsController.text.trim()) ?? 1;

      if (widget.jobId == null) {
        final CreateJobOpeningRequest req = CreateJobOpeningRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          department: _departmentController.text.trim().isNotEmpty
              ? _departmentController.text.trim()
              : null,
          jobType: _jobType,
          workplaceType: _workplaceType,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          minExperienceYears: minExp,
          maxExperienceYears: maxExp,
          minSalary: minSalary,
          maxSalary: maxSalary,
          salaryPeriod: _salaryPeriod,
          openingsCount: openings,
          requiredSkillsJson: _skillsController.text.trim().isNotEmpty
              ? _skillsController.text.trim()
              : null,
          educationRequirements: _educationController.text.trim().isNotEmpty
              ? _educationController.text.trim()
              : null,
        );

        await ref.read(jobRecruitmentServiceProvider).createJobOpening(req);
      } else {
        final UpdateJobOpeningRequest req = UpdateJobOpeningRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          department: _departmentController.text.trim().isNotEmpty
              ? _departmentController.text.trim()
              : null,
          jobType: _jobType,
          workplaceType: _workplaceType,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          minExperienceYears: minExp,
          maxExperienceYears: maxExp,
          minSalary: minSalary,
          maxSalary: maxSalary,
          salaryPeriod: _salaryPeriod,
          openingsCount: openings,
          requiredSkillsJson: _skillsController.text.trim().isNotEmpty
              ? _skillsController.text.trim()
              : null,
          educationRequirements: _educationController.text.trim().isNotEmpty
              ? _educationController.text.trim()
              : null,
        );

        await ref
            .read(jobRecruitmentServiceProvider)
            .updateJobOpening(widget.jobId!, req);
      }

      ref.invalidate(jobListingsProvider);
      ref.invalidate(myJobPostingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.jobId == null
                ? 'Job opening published successfully!'
                : 'Job opening updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.jobId != null;

    if (_isLoadingExisting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Job Opening')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Job Opening' : 'Post a Job Opening'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton.primary(
            text: isEditing ? 'Save Changes' : 'Publish Job Opening',
            isLoading: _isSaving,
            onPressed: _handleSubmit,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Job Title
              AppTextField(
                controller: _titleController,
                label: 'Job Title *',
                hintText: 'e.g. CNC Machine Operator, Industrial Electrician',
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Department
              AppTextField(
                controller: _departmentController,
                label: 'Department',
                hintText: 'e.g. Production, Maintenance, Quality Assurance',
              ),
              const SizedBox(height: AppSpacing.md),

              // Job Type & Workplace Type
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Job Type', style: AppTextStyles.labelMedium),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _jobType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          items: _jobTypes
                              .map((String t) => DropdownMenuItem<String>(
                                    value: t,
                                    child: Text(t),
                                  ))
                              .toList(),
                          onChanged: (String? val) {
                            if (val != null) setState(() => _jobType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Workplace', style: AppTextStyles.labelMedium),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _workplaceType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          items: _workplaceTypes
                              .map((String wt) => DropdownMenuItem<String>(
                                    value: wt,
                                    child: Text(wt),
                                  ))
                              .toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              setState(() => _workplaceType = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Location: City, State
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: 'City *',
                      hintText: 'e.g. Rajkot',
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
                      controller: _stateController,
                      label: 'State *',
                      hintText: 'e.g. Gujarat',
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
              const SizedBox(height: AppSpacing.md),

              // Address / Industrial Area
              AppTextField(
                controller: _addressController,
                label: 'Address / Industrial Area',
                hintText: 'e.g. GIDC Shapar, Metoda Industrial Estate',
              ),
              const SizedBox(height: AppSpacing.md),

              // Experience Range
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _minExpController,
                      label: 'Min Exp (Years)',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _maxExpController,
                      label: 'Max Exp (Years)',
                      hintText: 'Optional',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Salary Range & Period
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _minSalaryController,
                      label: 'Min Salary (₹)',
                      hintText: 'e.g. 25000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _maxSalaryController,
                      label: 'Max Salary (₹)',
                      hintText: 'e.g. 40000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Salary Period & Openings Count
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Salary Frequency',
                            style: AppTextStyles.labelMedium),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _salaryPeriod,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          items: _salaryPeriods
                              .map((String p) => DropdownMenuItem<String>(
                                    value: p,
                                    child: Text(p),
                                  ))
                              .toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              setState(() => _salaryPeriod = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _openingsController,
                      label: 'Number of Openings',
                      hintText: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Required Skills
              AppTextField(
                controller: _skillsController,
                label: 'Key Skills & Tools',
                hintText: 'e.g. Fanuc, Siemens, Turning, VMC 4-Axis, Blueprint Reading',
              ),
              const SizedBox(height: AppSpacing.md),

              // Education Requirements
              AppTextField(
                controller: _educationController,
                label: 'Education / Certification',
                hintText: 'e.g. ITI Machinist, Diploma in Mechanical Engineering',
              ),
              const SizedBox(height: AppSpacing.md),

              // Detailed Job Description
              AppTextField(
                controller: _descriptionController,
                label: 'Detailed Job Description *',
                hintText:
                    'Outline core responsibilities, shift timings, factory safety requirements, tooling, and machine models...',
                maxLines: 5,
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter job description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
