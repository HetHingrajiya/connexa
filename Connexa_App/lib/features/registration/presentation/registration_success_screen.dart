import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/registration_submission_models.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Screen displayed only after confirmed server persistence of registration.
/// Does not invent fake auth tokens or fake dashboards.
class RegistrationSuccessScreen extends ConsumerWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegistrationSubmissionState submitState = ref.watch(
      registrationSubmissionProvider,
    );
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);
    final RegistrationSubmissionResult? result = submitState.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Confirmed'),
        automaticallyImplyLeading: false,
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
                const SizedBox(height: AppSpacing.lg),

                // Success Confirmation Card
                AppCard(
                  key: const Key('registrationSuccessCard'),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Success Badge Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.successContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const Text(
                        'Account Created Successfully',
                        key: Key('successTitleText'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Your profile and verification have been persisted in the Connexa SQL Server database.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),

                      // Details rows
                      if (result != null) ...<Widget>[
                        _buildDetailRow(
                          'Member ID',
                          '#${result.memberId}',
                          isAccent: true,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow('Full Name', result.fullName),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow(
                          'Profile Type',
                          draft.profileType?.label ?? result.primaryProfileType,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow('Phone', result.phoneNumber),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow('Email', result.email),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow(
                          'Verified Channel',
                          '${result.verifiedMethod} (${result.verifiedDestination})',
                        ),
                      ] else ...<Widget>[
                        _buildDetailRow('Full Name', draft.fullName),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow(
                          'Profile Type',
                          draft.profileType?.label ?? '—',
                        ),
                        const Divider(height: AppSpacing.lg),
                        _buildDetailRow(
                          'Contact',
                          '${draft.countryCode} ${draft.mobileNumber}',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),

                      // Notice about credential setup
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
                              Icons.verified_user_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                result?.credentialSetupToken != null
                                    ? 'Secure Credential Setup: A server-validated setup token has been authorized for your account. Create your password to sign in to the Connexa dashboard.'
                                    : 'Your registration data and identity verification have been securely committed to the database.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Actions
                      if (result?.credentialSetupToken != null &&
                          result!.credentialSetupToken!.isNotEmpty) ...<Widget>[
                        AppButton.primary(
                          key: const Key('setupPasswordButton'),
                          text: 'Set Up Password & Continue to App',
                          isFullWidth: true,
                          trailingIcon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            ref
                                .read(pendingSetupTokenProvider.notifier)
                                .state = SetupTokenData(
                              token: result.credentialSetupToken!,
                              destination: result.email,
                            );
                            context.go(
                              '/setup-password',
                              extra: <String, dynamic>{
                                'token': result.credentialSetupToken,
                                'destination': result.email,
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton.secondary(
                          key: const Key('goToLoginButton'),
                          text: 'Sign In to Account',
                          isFullWidth: true,
                          leadingIcon: const Icon(
                            Icons.login_rounded,
                            size: 18,
                          ),
                          onPressed: () => context.go('/login'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ] else ...<Widget>[
                        AppButton.primary(
                          key: const Key('recoverSetupPasswordButton'),
                          text: 'Verify Account & Create Password',
                          isFullWidth: true,
                          trailingIcon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            context.go(
                              '/setup-password',
                              extra: <String, dynamic>{
                                'destination': result?.email.isNotEmpty == true
                                    ? result!.email
                                    : draft.email,
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppButton.secondary(
                        key: const Key('returnToOnboardingButton'),
                        text: 'Go to Onboarding Overview',
                        isFullWidth: true,
                        leadingIcon: const Icon(Icons.home_outlined, size: 18),
                        onPressed: () => context.go('/onboarding'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton.secondary(
                        key: const Key('startNewRegistrationButton'),
                        text: 'Register Another Account',
                        isFullWidth: true,
                        onPressed: () {
                          ref.read(registrationDraftProvider.notifier).state =
                              const RegistrationDraft();
                          context.go('/registration');
                        },
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

  Widget _buildDetailRow(String label, String value, {bool isAccent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isAccent ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isAccent ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
