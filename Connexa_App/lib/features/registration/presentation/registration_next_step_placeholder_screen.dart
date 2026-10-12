import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

/// Next-step placeholder screen confirming that Step 1 draft was saved
/// and subsequent registration modules will be built in future steps.
class RegistrationNextStepPlaceholderScreen extends ConsumerWidget {
  const RegistrationNextStepPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegistrationDraft draft = ref.watch(registrationDraftProvider);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 30,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Step 1 Draft Stored',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Profile-specific details pending Step 5 implementation.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),

                      // Draft Summary Review Box
                      _buildDraftSummary(draft),

                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'The next registration step (business verification, industry taxonomy, or professional credentials) will be constructed in subsequent project milestones.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton.secondary(
                        text: 'Edit Step 1 Details',
                        leadingIcon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => context.go('/registration'),
                      ),
                    ],
                  ),
                ),
              ],
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
            'TEMPORARY IN-MEMORY DRAFT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow(
            'Full Name',
            draft.fullName.isEmpty ? '—' : draft.fullName,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow(
            'Mobile',
            draft.mobileNumber.isEmpty
                ? '—'
                : '${draft.countryCode} ${draft.mobileNumber}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow('Email', draft.email.isEmpty ? '—' : draft.email),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow(
            'Profile Type',
            draft.profileType?.label ?? 'Not selected',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
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
            value,
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
