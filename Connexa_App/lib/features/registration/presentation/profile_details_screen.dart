import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/presentation/widgets/industry_hierarchy_selector.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Screen 2 of Registration: Collects Profile-Specific Details based on the
/// selected ProfileType from Step 1.
class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Business / Company Controllers & State
  late final TextEditingController _companyNameController;
  late final TextEditingController _businessDescController;
  final Set<BusinessCapability> _selectedBusinessCapabilities =
      <BusinessCapability>{};
  String? _businessCapabilityError;

  // Employee / Job Seeker Controllers
  late final TextEditingController _jobTitleController;
  late final TextEditingController _skillsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _jobTypeController;

  // Service Engineer Controllers
  late final TextEditingController _specializationController;
  late final TextEditingController _equipmentController;
  late final TextEditingController _yearsExpController;
  late final TextEditingController _serviceCoverageController;

  // Trader / Supplier Controllers & State
  late final TextEditingController _tradingNameController;
  final Set<BusinessCapability> _selectedTraderCapabilities =
      <BusinessCapability>{};
  late final TextEditingController _productsSuppliedController;
  late final TextEditingController _traderCoverageController;
  String? _traderCapabilityError;

  // Contractor / Job Worker Controllers & State
  late final TextEditingController _workNameController;
  final Set<String> _selectedContractorCapabilities = <String>{};
  late final TextEditingController _processesController;
  late final TextEditingController _contractorCoverageController;
  String? _contractorCapabilityError;

  // Contractor Capability Options
  final List<String> _contractorCapabilityOptions = const <String>[
    'Machining',
    'Fabrication',
    'Assembly',
    'Casting / Forging',
    'Tooling & Die',
    'Surface Treatment',
  ];

  String? _industryRequirementMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final RegistrationDraft draft = ref.read(registrationDraftProvider);

    // Initialize Business Controllers
    _companyNameController = TextEditingController(
      text: draft.businessDetails?.companyName ?? '',
    );
    _businessDescController = TextEditingController(
      text: draft.businessDetails?.businessDescription ?? '',
    );
    if (draft.businessDetails != null) {
      _selectedBusinessCapabilities.addAll(
        draft.businessDetails!.businessCapabilities,
      );
    }

    // Initialize Employee Controllers
    _jobTitleController = TextEditingController(
      text: draft.employeeDetails?.jobTitle ?? '',
    );
    _skillsController = TextEditingController(
      text: draft.employeeDetails?.skills ?? '',
    );
    _experienceController = TextEditingController(
      text: draft.employeeDetails?.experience ?? '',
    );
    _jobTypeController = TextEditingController(
      text: draft.employeeDetails?.preferredJobType ?? '',
    );

    // Initialize Service Engineer Controllers
    _specializationController = TextEditingController(
      text: draft.serviceEngineerDetails?.specialization ?? '',
    );
    _equipmentController = TextEditingController(
      text: draft.serviceEngineerDetails?.supportedEquipment ?? '',
    );
    _yearsExpController = TextEditingController(
      text: draft.serviceEngineerDetails?.yearsOfExperience ?? '',
    );
    _serviceCoverageController = TextEditingController(
      text: draft.serviceEngineerDetails?.serviceCoverage ?? '',
    );

    // Initialize Trader Controllers
    _tradingNameController = TextEditingController(
      text: draft.traderDetails?.tradingName ?? '',
    );
    if (draft.traderDetails != null) {
      _selectedTraderCapabilities.addAll(draft.traderDetails!.capabilities);
    }
    _productsSuppliedController = TextEditingController(
      text: draft.traderDetails?.productsSupplied ?? '',
    );
    _traderCoverageController = TextEditingController(
      text: draft.traderDetails?.serviceCoverage ?? '',
    );

    // Initialize Contractor Controllers
    _workNameController = TextEditingController(
      text: draft.contractorDetails?.workName ?? '',
    );
    if (draft.contractorDetails != null) {
      _selectedContractorCapabilities.addAll(
        draft.contractorDetails!.workCapabilities,
      );
    }
    _processesController = TextEditingController(
      text: draft.contractorDetails?.processesSupported ?? '',
    );
    _contractorCoverageController = TextEditingController(
      text: draft.contractorDetails?.workCoverage ?? '',
    );

    // If returning to edit and industry was already selected, ensure hierarchy notifier is restored
    final IndustrySelection? savedSelection =
        draft.businessDetails?.industrySelection ??
        draft.contractorDetails?.industrySelection;
    if (savedSelection != null && savedSelection.isComplete) {
      final IndustryHierarchyState currentHierarchy = ref.read(
        industryHierarchyProvider,
      );
      if (currentHierarchy.selectedIndustry == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(industryHierarchyProvider.notifier)
                .restoreFromSelection(savedSelection);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessDescController.dispose();
    _jobTitleController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _jobTypeController.dispose();
    _specializationController.dispose();
    _equipmentController.dispose();
    _yearsExpController.dispose();
    _serviceCoverageController.dispose();
    _tradingNameController.dispose();
    _productsSuppliedController.dispose();
    _traderCoverageController.dispose();
    _workNameController.dispose();
    _processesController.dispose();
    _contractorCoverageController.dispose();
    super.dispose();
  }

  void _handleContinue(ProfileType profileType) {
    if (_isSubmitting) return;

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    bool hasCustomValidationError = false;

    // Validate capability & industry selections
    if (profileType == ProfileType.businessCompany) {
      if (_selectedBusinessCapabilities.isEmpty) {
        setState(() {
          _businessCapabilityError = 'Please select at least one business type';
        });
        hasCustomValidationError = true;
      }
      final IndustryHierarchyState industryState = ref.read(
        industryHierarchyProvider,
      );
      if (!industryState.isComplete) {
        const String err =
            'Industry classification is required for Business profiles. Please complete all 4 levels (Industry, Business Group, SubGroup, and Category) from the connected catalog.';
        setState(() {
          _industryRequirementMessage = err;
        });
        ref.read(industryHierarchyProvider.notifier).setValidationError(err);
        hasCustomValidationError = true;
      } else {
        setState(() {
          _industryRequirementMessage = null;
        });
      }
    } else if (profileType == ProfileType.traderSupplier) {
      if (_selectedTraderCapabilities.isEmpty) {
        setState(() {
          _traderCapabilityError =
              'Please select at least one supplier capability';
        });
        hasCustomValidationError = true;
      }
    } else if (profileType == ProfileType.contractorJobWorker) {
      if (_selectedContractorCapabilities.isEmpty) {
        setState(() {
          _contractorCapabilityError =
              'Please select at least one work capability';
        });
        hasCustomValidationError = true;
      }
      final IndustryHierarchyState industryState = ref.read(
        industryHierarchyProvider,
      );
      if (!industryState.isComplete) {
        const String err =
            'Industry classification is required for Contractor profiles. Please complete all 4 levels (Industry, Business Group, SubGroup, and Category) from the connected catalog.';
        setState(() {
          _industryRequirementMessage = err;
        });
        ref.read(industryHierarchyProvider.notifier).setValidationError(err);
        hasCustomValidationError = true;
      } else {
        setState(() {
          _industryRequirementMessage = null;
        });
      }
    }

    if (!isFormValid || hasCustomValidationError) {
      return;
    }

    setState(() => _isSubmitting = true);

    // Save profile-specific details to the active in-memory draft
    final RegistrationDraft currentDraft = ref.read(registrationDraftProvider);
    RegistrationDraft updatedDraft = currentDraft;

    switch (profileType) {
      case ProfileType.businessCompany:
        final IndustryHierarchyState industryState = ref.read(
          industryHierarchyProvider,
        );
        final IndustrySelection? selection = industryState.toSelection();
        updatedDraft = currentDraft.copyWith(
          businessDetails: BusinessProfileDetails(
            companyName: _companyNameController.text.trim(),
            businessCapabilities: Set<BusinessCapability>.from(
              _selectedBusinessCapabilities,
            ),
            businessDescription: _businessDescController.text.trim(),
            industry: selection?.industryName,
            industrySelection: selection,
          ),
        );
      case ProfileType.employeeJobSeeker:
        updatedDraft = currentDraft.copyWith(
          employeeDetails: EmployeeProfileDetails(
            jobTitle: _jobTitleController.text.trim(),
            skills: _skillsController.text.trim(),
            experience: _experienceController.text.trim(),
            preferredJobType: _jobTypeController.text.trim(),
          ),
        );
      case ProfileType.serviceEngineer:
        updatedDraft = currentDraft.copyWith(
          serviceEngineerDetails: ServiceEngineerProfileDetails(
            specialization: _specializationController.text.trim(),
            supportedEquipment: _equipmentController.text.trim(),
            yearsOfExperience: _yearsExpController.text.trim(),
            serviceCoverage: _serviceCoverageController.text.trim(),
          ),
        );
      case ProfileType.traderSupplier:
        updatedDraft = currentDraft.copyWith(
          traderDetails: TraderProfileDetails(
            tradingName: _tradingNameController.text.trim(),
            capabilities: Set<BusinessCapability>.from(
              _selectedTraderCapabilities,
            ),
            productsSupplied: _productsSuppliedController.text.trim(),
            serviceCoverage: _traderCoverageController.text.trim(),
          ),
        );
      case ProfileType.contractorJobWorker:
        final IndustryHierarchyState industryState = ref.read(
          industryHierarchyProvider,
        );
        final IndustrySelection? selection = industryState.toSelection();
        updatedDraft = currentDraft.copyWith(
          contractorDetails: ContractorProfileDetails(
            workName: _workNameController.text.trim(),
            workCapabilities: Set<String>.from(_selectedContractorCapabilities),
            industry: selection?.industryName,
            industrySelection: selection,
            processesSupported: _processesController.text.trim(),
            workCoverage: _contractorCoverageController.text.trim(),
          ),
        );
    }

    ref.read(registrationDraftProvider.notifier).state = updatedDraft;

    if (!mounted) return;
    context.go('/registration/review');
  }

  @override
  Widget build(BuildContext context) {
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);

    // Handle missing draft or missing profile type gracefully
    if (draft.profileType == null) {
      return _buildMissingDraftRecovery();
    }

    final ProfileType profileType = draft.profileType!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration - Step 2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/registration');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Step Indicator
                  _buildStepIndicator(profileType),
                  const SizedBox(height: AppSpacing.xl),

                  // Header Titles
                  _buildHeaderTitles(profileType),
                  const SizedBox(height: AppSpacing.xxl),

                  // Profile-Specific Form Body
                  _buildProfileForm(profileType),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Continue Action Button
                  AppButton.primary(
                    key: const Key('profileDetailsContinueButton'),
                    text: 'Continue',
                    isLoading: _isSubmitting,
                    isFullWidth: true,
                    trailingIcon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleContinue(profileType),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingDraftRecovery() {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration - Step 2')),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          child: Center(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.warningContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'No Profile Type Selected',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please complete Step 1 (Basic Details and Profile Type) before accessing this section.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton.primary(
                    text: 'Return to Step 1',
                    leadingIcon: const Icon(Icons.arrow_back_rounded, size: 18),
                    onPressed: () => context.go('/registration'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ProfileType profileType) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Step 2 of the registration process — ${profileType.label}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitles(ProfileType profileType) {
    final String heading = switch (profileType) {
      ProfileType.businessCompany => 'Business & Company Details',
      ProfileType.employeeJobSeeker => 'Professional Experience',
      ProfileType.serviceEngineer => 'Engineering Specialization',
      ProfileType.traderSupplier => 'Trade & Supply Profile',
      ProfileType.contractorJobWorker => 'Job Work & Contractor Profile',
    };

    final String subtitle = switch (profileType) {
      ProfileType.businessCompany =>
        'Enter your registered corporate details and capabilities.',
      ProfileType.employeeJobSeeker =>
        'Share your career background and employment interests.',
      ProfileType.serviceEngineer =>
        'Specify your technical skills and machinery coverage.',
      ProfileType.traderSupplier =>
        'Define the materials and goods your firm distributes.',
      ProfileType.contractorJobWorker =>
        'Specify your manufacturing, fabrication, or machining capacity.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(heading, style: AppTextStyles.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm(ProfileType profileType) {
    return switch (profileType) {
      ProfileType.businessCompany => _buildBusinessForm(),
      ProfileType.employeeJobSeeker => _buildEmployeeForm(),
      ProfileType.serviceEngineer => _buildServiceEngineerForm(),
      ProfileType.traderSupplier => _buildTraderForm(),
      ProfileType.contractorJobWorker => _buildContractorForm(),
    };
  }

  // --- FORM 1: BUSINESS / COMPANY ---
  Widget _buildBusinessForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          title: 'Company Information',
          subtitle: 'Enter your business name and operational role.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                key: const Key('companyNameField'),
                controller: _companyNameController,
                label: 'Company / Business Name *',
                hintText: 'e.g., Apex Precision Technologies Pvt. Ltd.',
                prefixIcon: const Icon(
                  Icons.corporate_fare_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                validator: (String? val) {
                  if ((val ?? '').trim().isEmpty) {
                    return 'Please enter your company/business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Business Type * (Select all that apply)',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: BusinessCapability.values.map((
                  BusinessCapability cap,
                ) {
                  final bool isSelected = _selectedBusinessCapabilities
                      .contains(cap);
                  return FilterChip(
                    label: Text(cap.label),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedBusinessCapabilities.add(cap);
                        } else {
                          _selectedBusinessCapabilities.remove(cap);
                        }
                        if (_selectedBusinessCapabilities.isNotEmpty) {
                          _businessCapabilityError = null;
                        }
                      });
                    },
                    selectedColor: AppColors.secondaryContainer,
                    checkmarkColor: AppColors.onSecondaryContainer,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.onSecondaryContainer
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
              if (_businessCapabilityError != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _businessCapabilityError!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                key: const Key('businessDescriptionField'),
                controller: _businessDescController,
                label: 'Business Description (Optional)',
                hintText:
                    'Describe your core products, services, and market specializations...',
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        IndustryHierarchySelector(
          roleName: 'Business / Company',
          errorMessage: _industryRequirementMessage,
        ),
      ],
    );
  }

  // --- FORM 2: EMPLOYEE / JOB SEEKER ---
  Widget _buildEmployeeForm() {
    return AppCard(
      title: 'Professional Profile',
      subtitle: 'Specify your current job role, skills, and preferences.',
      child: Column(
        children: <Widget>[
          AppTextField(
            key: const Key('jobTitleField'),
            controller: _jobTitleController,
            label: 'Current Profession / Job Title *',
            hintText: 'e.g., Senior Quality Engineer',
            prefixIcon: const Icon(
              Icons.work_outline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            validator: (String? val) {
              if ((val ?? '').trim().isEmpty) {
                return 'Please enter your profession or job title';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('skillsField'),
            controller: _skillsController,
            label: 'Skills (Optional)',
            hintText: 'e.g., CNC Programming, Lean Six Sigma, CAD/CAM',
            prefixIcon: const Icon(
              Icons.star_outline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('experienceField'),
            controller: _experienceController,
            label: 'Experience (Optional)',
            hintText: 'e.g., 6 years in Automotive Die Casting',
            prefixIcon: const Icon(
              Icons.timeline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('jobTypeField'),
            controller: _jobTypeController,
            label: 'Preferred Job Type (Optional)',
            hintText: 'e.g., Full-Time, Consulting, Contract',
            prefixIcon: const Icon(
              Icons.business_center_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM 3: SERVICE ENGINEER / TECHNICIAN ---
  Widget _buildServiceEngineerForm() {
    return AppCard(
      title: 'Technical Specialization',
      subtitle: 'Outline the machinery and maintenance services you provide.',
      child: Column(
        children: <Widget>[
          AppTextField(
            key: const Key('specializationField'),
            controller: _specializationController,
            label: 'Technical Specialization *',
            hintText: 'e.g., Hydraulic Press Maintenance & PLC Troubleshooting',
            prefixIcon: const Icon(
              Icons.build_circle_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            validator: (String? val) {
              if ((val ?? '').trim().isEmpty) {
                return 'Please enter your technical specialization';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('equipmentField'),
            controller: _equipmentController,
            label: 'Supported Machines / Equipment (Optional)',
            hintText: 'e.g., CNC Milling, Injection Molding, Laser Cutters',
            prefixIcon: const Icon(
              Icons.precision_manufacturing_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('yearsExpField'),
            controller: _yearsExpController,
            label: 'Years of Experience (Optional)',
            hintText: 'e.g., 8 years',
            prefixIcon: const Icon(
              Icons.history_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('serviceCoverageField'),
            controller: _serviceCoverageController,
            label: 'Service Coverage (Optional)',
            hintText: 'e.g., Regional (Gujarat & Maharashtra) or Pan-India',
            prefixIcon: const Icon(
              Icons.map_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM 4: TRADER / SUPPLIER ---
  Widget _buildTraderForm() {
    return AppCard(
      title: 'Trading & Supply Information',
      subtitle:
          'Identify the goods, materials, and capabilities of your trading firm.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: const Key('tradingNameField'),
            controller: _tradingNameController,
            label: 'Business / Trading Name *',
            hintText: 'e.g., Bharat Metals & Industrial Supplies',
            prefixIcon: const Icon(
              Icons.storefront_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            validator: (String? val) {
              if ((val ?? '').trim().isEmpty) {
                return 'Please enter your business or trading name';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Supplier Type / Capabilities * (Select all that apply)',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: BusinessCapability.values.map((BusinessCapability cap) {
              final bool isSelected = _selectedTraderCapabilities.contains(cap);
              return FilterChip(
                label: Text(cap.label),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedTraderCapabilities.add(cap);
                    } else {
                      _selectedTraderCapabilities.remove(cap);
                    }
                    if (_selectedTraderCapabilities.isNotEmpty) {
                      _traderCapabilityError = null;
                    }
                  });
                },
                selectedColor: AppColors.secondaryContainer,
                checkmarkColor: AppColors.onSecondaryContainer,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.onSecondaryContainer
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          if (_traderCapabilityError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _traderCapabilityError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            key: const Key('productsSuppliedField'),
            controller: _productsSuppliedController,
            label: 'Products / Materials Supplied (Optional)',
            hintText:
                'e.g., Stainless Steel Bars, Fasteners, Industrial Bearings',
            prefixIcon: const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            key: const Key('traderCoverageField'),
            controller: _traderCoverageController,
            label: 'Service Coverage (Optional)',
            hintText: 'e.g., National Supply Chain, Export Ready',
            prefixIcon: const Icon(
              Icons.local_shipping_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM 5: CONTRACTOR / JOB WORKER ---
  Widget _buildContractorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          title: 'Job Work Capabilities',
          subtitle:
              'Define your industrial machining, tooling, or fabrication capacity.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                key: const Key('workNameField'),
                controller: _workNameController,
                label: 'Business / Work Name *',
                hintText: 'e.g., Om Engineering Job Works',
                prefixIcon: const Icon(
                  Icons.handyman_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                validator: (String? val) {
                  if ((val ?? '').trim().isEmpty) {
                    return 'Please enter your business or work name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Work Type / Capability * (Select all that apply)',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _contractorCapabilityOptions.map((String capability) {
                  final bool isSelected = _selectedContractorCapabilities
                      .contains(capability);
                  return FilterChip(
                    label: Text(capability),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedContractorCapabilities.add(capability);
                        } else {
                          _selectedContractorCapabilities.remove(capability);
                        }
                        if (_selectedContractorCapabilities.isNotEmpty) {
                          _contractorCapabilityError = null;
                        }
                      });
                    },
                    selectedColor: AppColors.secondaryContainer,
                    checkmarkColor: AppColors.onSecondaryContainer,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.onSecondaryContainer
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
              if (_contractorCapabilityError != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _contractorCapabilityError!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                key: const Key('processesField'),
                controller: _processesController,
                label: 'Processes / Machines Supported (Optional)',
                hintText: 'e.g., VMC 4-Axis, Lathe 10ft Bed, TIG Welding',
                prefixIcon: const Icon(
                  Icons.settings_suggest_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                key: const Key('contractorCoverageField'),
                controller: _contractorCoverageController,
                label: 'Work Coverage (Optional)',
                hintText:
                    'e.g., Industrial Zone & Outstation Transport Support',
                prefixIcon: const Icon(
                  Icons.pin_drop_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        IndustryHierarchySelector(
          roleName: 'Contractor / Job Worker',
          errorMessage: _industryRequirementMessage,
        ),
      ],
    );
  }
}
