import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Next-step placeholder screen reached when Step 2 profile details are completed.
class RegistrationStep3PlaceholderScreen extends ConsumerWidget {
  const RegistrationStep3PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration - Step 3'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/registration/step-2-placeholder');
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
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.successContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 32,
                      color: AppColors.onSuccessContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Profile Details Saved to Draft',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Step 2 successfully recorded in temporary in-memory session.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),

                  _buildDraftSummary(draft),

                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Subsequent registration steps (address verification, compliance, and final account creation) will be implemented in future milestones.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      AppButton.secondary(
                        text: 'Edit Profile Details',
                        leadingIcon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            context.go('/registration/step-2-placeholder'),
                      ),
                      AppButton.text(
                        text: 'Back to Basic Details',
                        onPressed: () => context.go('/registration'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftSummary(RegistrationDraft draft) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ACTIVE REGISTRATION DRAFT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRow('Full Name', draft.fullName),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            'Contact',
            '${draft.countryCode} ${draft.mobileNumber} (${draft.email})',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow('Profile Role', draft.profileType?.label ?? 'None'),
          const SizedBox(height: AppSpacing.sm),
          _buildProfileDetailsSummary(draft),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsSummary(RegistrationDraft draft) {
    if (draft.employeeDetails != null) {
      return _buildRow('Job Title', draft.employeeDetails!.jobTitle);
    } else if (draft.serviceEngineerDetails != null) {
      return _buildRow(
        'Specialization',
        draft.serviceEngineerDetails!.specialization,
      );
    } else if (draft.traderDetails != null) {
      return _buildRow(
        'Trading Name',
        '${draft.traderDetails!.tradingName} (${draft.traderDetails!.capabilities.map((c) => c.label).join(', ')})',
      );
    } else if (draft.businessDetails != null) {
      return _buildRow('Business Name', draft.businessDetails!.companyName);
    } else if (draft.contractorDetails != null) {
      return _buildRow('Work Name', draft.contractorDetails!.workName);
    }
    return const SizedBox.shrink();
  }

  Widget _buildRow(String label, String value) {
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
          child: Text(
            value.isEmpty ? '—' : value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
