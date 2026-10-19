import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Destination screen for Step 8: Clearly indicates that Phone Verification / OTP
/// delivery is pending backend service integration and has NOT been executed.
class PhoneVerificationPlaceholderScreen extends ConsumerWidget {
  const PhoneVerificationPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/registration/review');
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

                // Main Placeholder Card
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Status Badge Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phonelink_lock_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const Text(
                        'Phone Verification Pending',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Step 4 — Phone verification and SMS OTP service are not yet implemented.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),

                      // Draft Contact Info Box
                      _buildContactInfoBox(draft),
                      const SizedBox(height: AppSpacing.xl),

                      // Explicit System Notice Banner
                      _buildSystemNoticeBanner(draft),
                      const SizedBox(height: AppSpacing.xxl),

                      // Navigation Actions
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          AppButton.secondary(
                            key: const Key('returnToReviewButton'),
                            text: 'Return to Review',
                            leadingIcon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            onPressed: () => context.go('/registration/review'),
                          ),
                          AppButton.text(
                            key: const Key('returnToOnboardingButton'),
                            text: 'Back to Onboarding',
                            onPressed: () => context.go('/onboarding'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Step 4 of the registration process — Phone Verification (Planned)',
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

  Widget _buildContactInfoBox(RegistrationDraft draft) {
    final String formattedPhone = draft.mobileNumber.isNotEmpty
        ? '${draft.countryCode} ${draft.mobileNumber}'
        : 'No phone number provided';

    return Container(
      width: double.infinity,
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
            'TARGET VERIFICATION IDENTITY',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Full Name', draft.fullName),
          const SizedBox(height: AppSpacing.xs),
          _buildInfoRow('Mobile Number', formattedPhone),
          const SizedBox(height: AppSpacing.xs),
          _buildInfoRow('Email Address', draft.email),
          const SizedBox(height: AppSpacing.xs),
          _buildInfoRow('Profile Role', draft.profileType?.label ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
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

  Widget _buildSystemNoticeBanner(RegistrationDraft draft) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Development Notice: Verification Incomplete',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• OTP delivery and phone verification are not yet implemented.\n'
            '• No SMS or OTP has been sent to ${draft.countryCode} ${draft.mobileNumber}.\n'
            '• This phone number has NOT been marked as verified.\n'
            '• No user account has been created or committed to Microsoft SQL Server.\n'
            '• Your registration draft remains preserved in memory for subsequent implementation milestones.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
