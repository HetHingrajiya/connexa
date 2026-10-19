import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/onboarding/providers/onboarding_provider.dart';

/// Production-quality splash screen for Connexa.
///
/// Features clean text-based brand mark, tagline, subtle loading indicator,
/// and deterministic routing to Onboarding or Registration based on in-memory state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.navigationDelay = const Duration(milliseconds: 750),
  });

  /// Configurable transition duration for deterministic testing.
  final Duration navigationDelay;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNavigation() {
    _timer = Timer(widget.navigationDelay, () {
      if (!mounted) return;
      final bool hasCompletedOnboarding = ref.read(onboardingCompletedProvider);
      if (hasCompletedOnboarding) {
        context.go('/registration');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(flex: 3),

                  // Brand Icon Mark
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppSpacing.borderRadiusLg,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.hub_rounded,
                        size: 40,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Brand Title
                  const Text(
                    'Connexa',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Brand Tagline
                  Text(
                    'One Network for Every Business',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Subtle Loading Indicator
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'INITIALIZING NETWORK',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
