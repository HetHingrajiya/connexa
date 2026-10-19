import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';

/// Placeholder screen indicating that Registration & Authentication will be
/// implemented in subsequent steps.
class RegistrationPlaceholderScreen extends StatelessWidget {
  const RegistrationPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
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
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                    child: const Icon(
                      Icons.app_registration_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Registration Module',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Step 4: Enterprise Identity & Registration',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Registration, business profile creation, and authentication workflows will be implemented in subsequent project milestones.\n\nSplash, onboarding flow, and the responsive design system are fully configured and verified.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      AppButton.secondary(
                        text: 'Replay Onboarding',
                        leadingIcon: const Icon(Icons.replay_rounded, size: 18),
                        onPressed: () => context.go('/onboarding'),
                      ),
                      AppButton.primary(
                        text: 'View Design System',
                        leadingIcon: const Icon(
                          Icons.palette_outlined,
                          size: 18,
                        ),
                        onPressed: () => context.go('/design-preview'),
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
}
