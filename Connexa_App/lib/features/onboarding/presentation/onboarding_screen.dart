import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/onboarding/providers/onboarding_provider.dart';

/// Data model representing an individual onboarding step.
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final String badgeLabel;
}

/// Production-quality, responsive 3-page onboarding flow for Connexa.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isAnimating = false;

  static const List<OnboardingPageData> _pages = <OnboardingPageData>[
    OnboardingPageData(
      title: 'Connect Businesses',
      description:
          'Build meaningful connections with businesses, suppliers and industry professionals.',
      icon: Icons.hub_rounded,
      badgeLabel: 'VERIFIED NETWORK',
    ),
    OnboardingPageData(
      title: 'Discover Opportunities',
      description:
          'Explore products, services, job opportunities and business collaborations.',
      icon: Icons.explore_rounded,
      badgeLabel: 'MARKETPLACE & LEADS',
    ),
    OnboardingPageData(
      title: 'Collaborate and Grow',
      description:
          'Turn professional connections into partnerships and long-term growth.',
      icon: Icons.trending_up_rounded,
      badgeLabel: 'STRATEGIC PARTNERSHIPS',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _handleNext() async {
    if (_isAnimating || _isLastPage) return;
    _isAnimating = true;
    try {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _isAnimating = false;
    }
  }

  Future<void> _handleSkip() async {
    if (_isAnimating || _isLastPage) return;
    _isAnimating = true;
    try {
      await _pageController.animateToPage(
        _pages.length - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _isAnimating = false;
    }
  }

  void _handleGetStarted() {
    ref.read(onboardingCompletedProvider.notifier).state = true;
    context.go('/registration');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Connexa'),
        actions: <Widget>[
          if (!_isLastPage)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: AppButton.text(text: 'Skip', onPressed: _handleSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenterBox(
          padding: AppSpacing.screenPaddingMobile,
          maxTabletWidth: AppSpacing.maxContentWidthTablet,
          maxDesktopWidth: AppSpacing.maxContentWidthDesktop,
          child: Column(
            children: <Widget>[
              // Interactive Page Content Area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (BuildContext context, int index) {
                    final OnboardingPageData page = _pages[index];
                    return _buildPageContent(page);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bottom Navigation Section
              _buildBottomControls(),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPageData page) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: AppSpacing.lg),

            // Visual Icon Feature Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.borderRadiusXl,
                border: Border.all(
                  color: AppColors.secondaryContainer,
                  width: 2.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  page.icon,
                  size: 56,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Text(
                page.badgeLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Page Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Page Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                page.description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Page Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_pages.length, (int index) {
            final bool isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              height: 8,
              width: isActive ? 24 : 8,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondary
                    : AppColors.outlineVariant,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Action Buttons
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _isLastPage
              ? AppButton.primary(
                  text: 'Get Started',
                  isFullWidth: true,
                  trailingIcon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  onPressed: _handleGetStarted,
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton.secondary(
                        text: 'Skip',
                        onPressed: _handleSkip,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Next',
                        trailingIcon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onPressed: _handleNext,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
