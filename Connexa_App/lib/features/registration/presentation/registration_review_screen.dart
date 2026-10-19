import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/verification_models.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Screen 3 of Registration: Comprehensive, typed review of the active registration
/// draft across all 5 profile types with section-level editing, validation, and consent.
class RegistrationReviewScreen extends ConsumerStatefulWidget {
  const RegistrationReviewScreen({super.key});

  @override
  ConsumerState<RegistrationReviewScreen> createState() =>
      _RegistrationReviewScreenState();
}

class _RegistrationReviewScreenState
    extends ConsumerState<RegistrationReviewScreen> {
  bool _consentAgreed = false;
  bool _submitted = false;
  String? _consentError;
  List<String> _validationErrors = const <String>[];
  VerificationMethod _selectedMethod = VerificationMethod.whatsapp;

  Future<void> _handleContinue() async {
    setState(() {
      _submitted = true;
    });

    final RegistrationDraft draft = ref.read(registrationDraftProvider);
    final List<String> draftErrors = draft.allValidationErrors;
    final bool consentValid = _consentAgreed;

    setState(() {
      _consentError = consentValid
          ? null
          : 'You must confirm your details and agree to continue';
      _validationErrors = draftErrors;
    });

    // If any validation fails or consent is missing, remain on review screen
    if (!consentValid || draftErrors.isNotEmpty) {
      return;
    }

    if (draft.isVerified) {
      final bool success = await ref
          .read(registrationSubmissionProvider.notifier)
          .submit(draft);

      if (success && mounted) {
        context.go('/registration/success');
      }
      return;
    }

    // Navigate to chosen verification channel
    if (_selectedMethod == VerificationMethod.email) {
      context.go('/registration/email-verification');
    } else {
      context.go('/registration/phone-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);
    final RegistrationSubmissionState submitState = ref.watch(
      registrationSubmissionProvider,
    );

    // Handle missing draft or missing profile role gracefully
    if (draft.profileType == null &&
        draft.fullName.isEmpty &&
        draft.mobileNumber.isEmpty) {
      return _buildEmptyDraftRecovery();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/registration/profile-details');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: AppSpacing.xl),

                // Header Titles
                const Text(
                  'Review Your Registration',
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Please confirm all details before proceeding to phone verification.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Global Validation Error Banner (if validation failed)
                if (_submitted && _validationErrors.isNotEmpty) ...<Widget>[
                  _buildValidationErrorBanner(),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Section 1: Basic Details Card
                _buildBasicDetailsCard(draft),
                const SizedBox(height: AppSpacing.xxl),

                // Section 2: Profile-Specific Details Card
                _buildProfileDetailsCard(draft),
                const SizedBox(height: AppSpacing.xxl),

                // Section 3: Verification Method Selection (WhatsApp vs Gmail SMTP)
                _buildVerificationMethodCard(draft),
                const SizedBox(height: AppSpacing.xxl),

                // Section 4: Consent & Pending Terms Notice
                _buildConsentCard(),
                const SizedBox(height: AppSpacing.xxxl),

                // Submission Error Banner if any
                if (submitState.errorMessage != null) ...<Widget>[
                  _buildSubmissionErrorBanner(submitState.errorMessage!),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Primary Action: Continue to Verification / Complete Registration
                AppButton.primary(
                  key: const Key('continueToVerificationButton'),
                  text: draft.isVerified
                      ? 'Complete Registration'
                      : 'Continue to ${_selectedMethod == VerificationMethod.email ? 'Email' : 'WhatsApp'} Verification',
                  isFullWidth: true,
                  isLoading: submitState.isSubmitting,
                  trailingIcon: Icon(
                    draft.isVerified
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  onPressed: submitState.isSubmitting ? null : _handleContinue,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.fact_check_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Step 3 of the registration process — Review & Confirm',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDraftRecovery() {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Registration')),
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
                    'No Registration Draft Found',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No active registration draft was found in memory. Please start your registration from Step 1.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton.primary(
                    key: const Key('returnToStep1Button'),
                    text: 'Start Registration (Step 1)',
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

  Widget _buildValidationErrorBanner() {
    return Container(
      key: const Key('validationErrorBanner'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Please correct the following before continuing:',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._validationErrors.map((String error) {
            return Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                bottom: AppSpacing.xxs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '• ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      error,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubmissionErrorBanner(String message) {
    return Container(
      key: const Key('submissionErrorBanner'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Registration Submission Failed',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 1: BASIC DETAILS ---
  Widget _buildBasicDetailsCard(RegistrationDraft draft) {
    final bool hasName = draft.fullName.trim().length >= 2;
    final bool hasPhone = draft.mobileNumber.trim().isNotEmpty;
    final bool hasEmail = draft.email.trim().isNotEmpty;
    final bool hasProfileType = draft.profileType != null;

    final String phoneDisplay = hasPhone
        ? '${draft.countryCode} ${draft.mobileNumber}'
        : 'Missing phone number';

    return AppCard(
      title: 'Basic Details',
      subtitle: 'Personal and contact information.',
      headerAction: AppButton.secondary(
        key: const Key('editBasicDetailsButton'),
        text: 'Edit',
        height: 36,
        leadingIcon: const Icon(Icons.edit_outlined, size: 16),
        onPressed: () => context.go('/registration'),
      ),
      child: Column(
        children: <Widget>[
          _buildReviewRow(
            label: 'Full Name',
            value: draft.fullName,
            isMissing: !hasName,
            missingWarning: 'Full name is required (min. 2 characters)',
          ),
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Mobile Number',
            value: phoneDisplay,
            isMissing: !hasPhone,
            missingWarning: 'Mobile number is required',
          ),
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Email Address',
            value: draft.email,
            isMissing: !hasEmail,
            missingWarning: 'Email address is required',
          ),
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Primary Role',
            value: draft.profileType?.label ?? '',
            isMissing: !hasProfileType,
            missingWarning: 'Profile role selection is required',
            badgeIcon: draft.profileType?.icon,
          ),
        ],
      ),
    );
  }

  // --- SECTION 2: PROFILE-SPECIFIC DETAILS ---
  Widget _buildProfileDetailsCard(RegistrationDraft draft) {
    if (draft.profileType == null) {
      return AppCard(
        title: 'Profile Details',
        subtitle: 'Role-specific participation details.',
        headerAction: AppButton.secondary(
          key: const Key('editProfileDetailsButton'),
          text: 'Select Role',
          height: 36,
          leadingIcon: const Icon(Icons.edit_outlined, size: 16),
          onPressed: () => context.go('/registration'),
        ),
        child: _buildMissingWarningBox(
          'No profile role selected. Please return to Step 1 to select what describes you best.',
        ),
      );
    }

    final ProfileType type = draft.profileType!;
    final String cardTitle = switch (type) {
      ProfileType.businessCompany => 'Business & Company Details',
      ProfileType.employeeJobSeeker => 'Employee & Career Profile',
      ProfileType.serviceEngineer => 'Service Engineer Profile',
      ProfileType.traderSupplier => 'Trader & Supplier Profile',
      ProfileType.contractorJobWorker => 'Contractor & Job Work Profile',
    };

    return AppCard(
      title: cardTitle,
      subtitle: type.label,
      headerAction: AppButton.secondary(
        key: const Key('editProfileDetailsButton'),
        text: 'Edit',
        height: 36,
        leadingIcon: const Icon(Icons.edit_outlined, size: 16),
        onPressed: () => context.go('/registration/profile-details'),
      ),
      child: switch (type) {
        ProfileType.businessCompany => _buildBusinessReviewContent(
          draft.businessDetails,
        ),
        ProfileType.employeeJobSeeker => _buildEmployeeReviewContent(
          draft.employeeDetails,
        ),
        ProfileType.serviceEngineer => _buildServiceEngineerReviewContent(
          draft.serviceEngineerDetails,
        ),
        ProfileType.traderSupplier => _buildTraderReviewContent(
          draft.traderDetails,
        ),
        ProfileType.contractorJobWorker => _buildContractorReviewContent(
          draft.contractorDetails,
        ),
      },
    );
  }

  // Profile 1: Business / Company
  Widget _buildBusinessReviewContent(BusinessProfileDetails? details) {
    if (details == null) {
      return _buildMissingWarningBox(
        'Business profile details not yet entered.',
      );
    }

    final bool hasName = details.companyName.trim().isNotEmpty;
    final bool hasCapabilities = details.businessCapabilities.isNotEmpty;
    final IndustrySelection? industrySel = details.industrySelection;
    final bool hasHierarchy = industrySel != null && industrySel.isComplete;

    final String capabilitiesString = details.businessCapabilities
        .map((BusinessCapability c) => c.label)
        .join(', ');

    return Column(
      children: <Widget>[
        _buildReviewRow(
          label: 'Business Name',
          value: details.companyName,
          isMissing: !hasName,
          missingWarning: 'Business / Company name is required',
        ),
        const Divider(height: AppSpacing.lg),
        _buildReviewRow(
          label: 'Capabilities',
          value: capabilitiesString,
          isMissing: !hasCapabilities,
          missingWarning: 'At least one business capability is required',
        ),
        if (details.businessDescription.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Description',
            value: details.businessDescription.trim(),
          ),
        ],
        const Divider(height: AppSpacing.lg),
        _buildHierarchyReviewSection(
          selection: industrySel,
          isMissing: !hasHierarchy,
        ),
      ],
    );
  }

  // Profile 2: Employee / Job Seeker
  Widget _buildEmployeeReviewContent(EmployeeProfileDetails? details) {
    if (details == null) {
      return _buildMissingWarningBox('Employee details not yet entered.');
    }

    final bool hasJobTitle = details.jobTitle.trim().isNotEmpty;

    return Column(
      children: <Widget>[
        _buildReviewRow(
          label: 'Job Title / Profession',
          value: details.jobTitle,
          isMissing: !hasJobTitle,
          missingWarning: 'Current profession or job title is required',
        ),
        if (details.skills.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(label: 'Key Skills', value: details.skills.trim()),
        ],
        if (details.experience.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Experience',
            value: details.experience.trim(),
          ),
        ],
        if (details.preferredJobType.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Preferred Job Type',
            value: details.preferredJobType.trim(),
          ),
        ],
      ],
    );
  }

  // Profile 3: Service Engineer / Technician
  Widget _buildServiceEngineerReviewContent(
    ServiceEngineerProfileDetails? details,
  ) {
    if (details == null) {
      return _buildMissingWarningBox(
        'Service engineer details not yet entered.',
      );
    }

    final bool hasSpec = details.specialization.trim().isNotEmpty;

    return Column(
      children: <Widget>[
        _buildReviewRow(
          label: 'Specialization',
          value: details.specialization,
          isMissing: !hasSpec,
          missingWarning: 'Technical specialization is required',
        ),
        if (details.supportedEquipment.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Supported Equipment',
            value: details.supportedEquipment.trim(),
          ),
        ],
        if (details.yearsOfExperience.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Experience',
            value: details.yearsOfExperience.trim(),
          ),
        ],
        if (details.serviceCoverage.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Service Coverage',
            value: details.serviceCoverage.trim(),
          ),
        ],
      ],
    );
  }

  // Profile 4: Trader / Supplier
  Widget _buildTraderReviewContent(TraderProfileDetails? details) {
    if (details == null) {
      return _buildMissingWarningBox('Trader details not yet entered.');
    }

    final bool hasName = details.tradingName.trim().isNotEmpty;
    final bool hasCaps = details.capabilities.isNotEmpty;
    final String capsString = details.capabilities
        .map((BusinessCapability c) => c.label)
        .join(', ');

    return Column(
      children: <Widget>[
        _buildReviewRow(
          label: 'Trading Name',
          value: details.tradingName,
          isMissing: !hasName,
          missingWarning: 'Business / Trading name is required',
        ),
        const Divider(height: AppSpacing.lg),
        _buildReviewRow(
          label: 'Capabilities',
          value: capsString,
          isMissing: !hasCaps,
          missingWarning: 'At least one supplier capability is required',
        ),
        if (details.productsSupplied.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Products Supplied',
            value: details.productsSupplied.trim(),
          ),
        ],
        if (details.serviceCoverage.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Service Coverage',
            value: details.serviceCoverage.trim(),
          ),
        ],
      ],
    );
  }

  // Profile 5: Contractor / Job Worker
  Widget _buildContractorReviewContent(ContractorProfileDetails? details) {
    if (details == null) {
      return _buildMissingWarningBox('Contractor details not yet entered.');
    }

    final bool hasName = details.workName.trim().isNotEmpty;
    final bool hasCaps = details.workCapabilities.isNotEmpty;
    final IndustrySelection? industrySel = details.industrySelection;
    final bool hasHierarchy = industrySel != null && industrySel.isComplete;
    final String capsString = details.workCapabilities.join(', ');

    return Column(
      children: <Widget>[
        _buildReviewRow(
          label: 'Business / Work Name',
          value: details.workName,
          isMissing: !hasName,
          missingWarning: 'Business / Work name is required',
        ),
        const Divider(height: AppSpacing.lg),
        _buildReviewRow(
          label: 'Work Capabilities',
          value: capsString,
          isMissing: !hasCaps,
          missingWarning: 'At least one work capability is required',
        ),
        if (details.processesSupported.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Processes Supported',
            value: details.processesSupported.trim(),
          ),
        ],
        if (details.workCoverage.trim().isNotEmpty) ...<Widget>[
          const Divider(height: AppSpacing.lg),
          _buildReviewRow(
            label: 'Work Coverage',
            value: details.workCoverage.trim(),
          ),
        ],
        const Divider(height: AppSpacing.lg),
        _buildHierarchyReviewSection(
          selection: industrySel,
          isMissing: !hasHierarchy,
        ),
      ],
    );
  }

  // --- HIERARCHY REVIEW SECTION (Business & Contractor) ---
  Widget _buildHierarchyReviewSection({
    required IndustrySelection? selection,
    required bool isMissing,
  }) {
    if (isMissing || selection == null) {
      return _buildReviewRow(
        label: 'Industry Classification',
        value: '',
        isMissing: true,
        missingWarning:
            'Complete 4-tier industry classification is required (Industry, Group, SubGroup, Category)',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            Text(
              'Industry Classification',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Text(
                '4 TIERS COMPLETE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSuccessContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Hierarchical visual path
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTierRow(
                '1. Industry',
                selection.industryName,
                selection.industryId,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildTierRow(
                '2. Group',
                selection.businessGroupName,
                selection.businessGroupId,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildTierRow(
                '3. SubGroup',
                selection.subGroupName,
                selection.subGroupId,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildTierRow(
                '4. Category',
                selection.categoryName,
                selection.categoryId,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierRow(String level, String name, Object id) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: <Widget>[
              Text(
                level,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '[ID: $id]',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 3: VERIFICATION METHOD SELECTION ---
  Widget _buildVerificationMethodCard(RegistrationDraft draft) {
    if (draft.isVerified) {
      final String methodLabel = draft.verifiedMethod == 'email'
          ? 'Email'
          : 'WhatsApp';
      final String destinationLabel =
          draft.verifiedDestination ??
          (draft.verifiedMethod == 'email' ? draft.email : draft.mobileNumber);

      return AppCard(
        key: const Key('verifiedStatusCard'),
        title: 'Verification Status',
        subtitle: 'Server-issued cryptographic grant active.',
        headerAction: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Text(
            'VERIFIED',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSuccessContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Identity Verified via $methodLabel ($destinationLabel)',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    'Verification Confirmed',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSuccessContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Unified Policy: Either WhatsApp Phone OR Email satisfies registration verification. Your verification requirement is complete.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      title: 'Verification Channel',
      subtitle:
          'Choose your preferred method. Either WhatsApp OR Email satisfies the requirement.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Option 1: WhatsApp
          _buildMethodOptionTile(
            key: const Key('whatsappVerificationOption'),
            method: VerificationMethod.whatsapp,
            title: 'WhatsApp Phone OTP',
            subtitle:
                'Dispatch code to ${draft.countryCode} ${draft.mobileNumber}',
            icon: Icons.chat_bubble_rounded,
            badgeText: 'Meta Cloud API',
            isSelected: _selectedMethod == VerificationMethod.whatsapp,
            onTap: () {
              setState(() {
                _selectedMethod = VerificationMethod.whatsapp;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Option 2: Gmail SMTP Email
          _buildMethodOptionTile(
            key: const Key('emailVerificationOption'),
            method: VerificationMethod.email,
            title: 'Gmail SMTP Email OTP',
            subtitle: draft.email.isNotEmpty
                ? 'Dispatch code to ${draft.email}'
                : 'Enter email in Step 1',
            icon: Icons.mail_outline_rounded,
            badgeText: 'Live SMTP',
            isSelected: _selectedMethod == VerificationMethod.email,
            onTap: () {
              setState(() {
                _selectedMethod = VerificationMethod.email;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOptionTile({
    required Key key,
    required VerificationMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.3)
              : AppColors.surfaceContainer,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: 2,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight.withValues(alpha: 0.2)
                              : AppColors.surface,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          badgeText,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 4: CONSENT CARD ---
  Widget _buildConsentCard() {
    return AppCard(
      title: 'Declaration & Consent',
      subtitle: 'Mandatory confirmation before verification.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Pending Legal Docs Notice Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Terms of Service and Privacy Policy documents are currently pending formal publication. '
                    'Full legal agreements will be accessible prior to production release.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Interactive Consent Checkbox
          InkWell(
            onTap: () {
              setState(() {
                _consentAgreed = !_consentAgreed;
                if (_consentAgreed) {
                  _consentError = null;
                }
              });
            },
            borderRadius: AppSpacing.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox(
                    key: const Key('consentCheckbox'),
                    value: _consentAgreed,
                    onChanged: (bool? val) {
                      setState(() {
                        _consentAgreed = val ?? false;
                        if (_consentAgreed) {
                          _consentError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'I confirm that all entered details are accurate, and I agree to proceed to phone verification for Connexa registration. *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_consentError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                _consentError!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper: Review Row
  Widget _buildReviewRow({
    required String label,
    required String value,
    bool isMissing = false,
    String? missingWarning,
    IconData? badgeIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: isMissing
              ? Row(
                  children: <Widget>[
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        missingWarning ?? 'Missing required information',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    if (badgeIcon != null) ...<Widget>[
                      Icon(badgeIcon, size: 18, color: AppColors.secondary),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        value.trim().isEmpty ? '—' : value.trim(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMissingWarningBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
