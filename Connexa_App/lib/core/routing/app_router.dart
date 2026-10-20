import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/presentation/login_screen.dart';
import 'package:connexa/features/auth/presentation/setup_password_screen.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/dashboard/presentation/dashboard_screen.dart';
import 'package:connexa/features/onboarding/presentation/onboarding_screen.dart';
import 'package:connexa/features/registration/presentation/email_verification_screen.dart';
import 'package:connexa/features/registration/presentation/phone_verification_screen.dart';
import 'package:connexa/features/registration/presentation/profile_details_screen.dart';
import 'package:connexa/features/registration/presentation/registration_review_screen.dart';
import 'package:connexa/features/registration/presentation/registration_screen.dart';
import 'package:connexa/features/connections/presentation/network_screen.dart';
import 'package:connexa/features/directory/presentation/directory_screen.dart';
import 'package:connexa/features/profile/presentation/edit_profile_screen.dart';
import 'package:connexa/features/profile/presentation/profile_screen.dart';
import 'package:connexa/features/registration/presentation/registration_success_screen.dart';
import 'package:connexa/features/splash/presentation/splash_screen.dart';

/// Listenable notifier bridging Riverpod auth state updates to GoRouter redirection.
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (AuthState? previous, AuthState next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isRestoringSession != next.isRestoringSession) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

/// Riverpod provider exposing the application router configuration.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final AuthRouterNotifier authNotifier = AuthRouterNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState authState = ref.read(authProvider);
      final bool isAuthenticated = authState.isAuthenticated;
      final String loc = state.matchedLocation;

      // When restoring active session at boot, defer redirect decisions until completed
      if (authState.isRestoringSession) {
        return null;
      }

      final bool isProtectedRoute =
          loc == '/dashboard' ||
          loc == '/profile' ||
          loc == '/profile/edit' ||
          loc == '/directory' ||
          loc == '/network';
      final bool isAuthRoute = loc == '/login';

      if (!isAuthenticated && isProtectedRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const SplashScreen(),
            ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const OnboardingScreen(),
            ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const LoginScreen(),
            ),
      ),
      GoRoute(
        path: '/setup-password',
        name: 'setup-password',
        pageBuilder: (BuildContext context, GoRouterState state) {
          String? token;
          String? destination;
          if (state.extra is Map<String, dynamic>) {
            final Map<String, dynamic> extra =
                state.extra! as Map<String, dynamic>;
            token = extra['token'] as String?;
            destination = extra['destination'] as String?;
          } else if (state.extra is String) {
            token = state.extra as String;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: SetupPasswordScreen(
              initialCredentialSetupToken: token,
              initialDestination: destination,
            ),
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profile-edit',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const EditProfileScreen(),
            ),
      ),
      GoRoute(
        path: '/directory',
        name: 'directory',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const BusinessDirectoryScreen(),
            ),
      ),
      GoRoute(
        path: '/network',
        name: 'network',
        pageBuilder: (BuildContext context, GoRouterState state) {
          int initialTab = 0;
          if (state.extra is int) {
            initialTab = state.extra as int;
          } else if (state.uri.queryParameters.containsKey('tab')) {
            initialTab = int.tryParse(state.uri.queryParameters['tab']!) ?? 0;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: NetworkScreen(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        path: '/registration',
        name: 'registration',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const RegistrationScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/step-2-placeholder',
        name: 'registration-step-2-placeholder',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ProfileDetailsScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/profile-details',
        name: 'registration-profile-details',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ProfileDetailsScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/step-3-placeholder',
        name: 'registration-step-3-placeholder',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const RegistrationReviewScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/review',
        name: 'registration-review',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const RegistrationReviewScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/phone-verification',
        name: 'registration-phone-verification',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const PhoneVerificationScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/email-verification',
        name: 'registration-email-verification',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const EmailVerificationScreen(),
            ),
      ),
      GoRoute(
        path: '/registration/success',
        name: 'registration-success',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const RegistrationSuccessScreen(),
            ),
      ),
      GoRoute(
        path: '/design-preview',
        name: 'design-preview',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const _InitializationScreen(),
            ),
      ),
    ],
  );
});

/// Responsive developer design system preview screen for the Connexa application shell.
class _InitializationScreen extends StatefulWidget {
  const _InitializationScreen();

  @override
  State<_InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<_InitializationScreen> {
  String? _selectedIndustry = 'tech';
  bool _isLoadingExample = false;

  final List<AppDropdownItem<String>> _industryOptions =
      const <AppDropdownItem<String>>[
        AppDropdownItem<String>(
          value: 'tech',
          label: 'Technology & Software',
          icon: Icon(
            Icons.computer_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
        ),
        AppDropdownItem<String>(
          value: 'mfg',
          label: 'Manufacturing & Industrial',
          icon: Icon(
            Icons.precision_manufacturing_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
        ),
        AppDropdownItem<String>(
          value: 'logistics',
          label: 'Logistics & Supply Chain',
          icon: Icon(
            Icons.local_shipping_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexa'),
        centerTitle: false,
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppColors.secondary,
            ),
          ),
        ],
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
                // Header / Hero Section
                _buildHeroSection(),
                const SizedBox(height: AppSpacing.xxl),

                // Button Components Showcase
                _buildSectionHeader('Buttons & Actions'),
                const SizedBox(height: AppSpacing.md),
                _buildButtonsShowcase(),
                const SizedBox(height: AppSpacing.xxl),

                // Form Controls Showcase
                _buildSectionHeader('Form Controls & Inputs'),
                const SizedBox(height: AppSpacing.md),
                _buildFormControlsShowcase(),
                const SizedBox(height: AppSpacing.xxl),

                // Card Showcase
                _buildSectionHeader('Information Card Container'),
                const SizedBox(height: AppSpacing.md),
                _buildCardShowcase(),
                const SizedBox(height: AppSpacing.xxl),

                // Feedback States Showcase
                _buildSectionHeader('Feedback & System States'),
                const SizedBox(height: AppSpacing.md),
                _buildFeedbackStatesShowcase(),
                const SizedBox(height: AppSpacing.massive),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        const Divider(),
      ],
    );
  }

  Widget _buildHeroSection() {
    return ResponsiveBuilder(
      builder:
          (
            BuildContext context,
            DeviceType deviceType,
            BoxConstraints constraints,
          ) {
            return AppCard(
              backgroundColor: AppColors.surface,
              padding: EdgeInsets.all(
                deviceType == DeviceType.mobile
                    ? AppSpacing.xl
                    : AppSpacing.xxxl,
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Connexa',
                    textAlign: TextAlign.center,
                    style: deviceType == DeviceType.mobile
                        ? AppTextStyles.displaySmall
                        : AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'One Network for Every Business',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Chip(
                    avatar: Icon(
                      switch (deviceType) {
                        DeviceType.mobile => Icons.phone_android_rounded,
                        DeviceType.tablet => Icons.tablet_android_rounded,
                        DeviceType.desktop => Icons.desktop_windows_rounded,
                      },
                      size: 16,
                      color: AppColors.onSecondaryContainer,
                    ),
                    label: Text(
                      '${deviceType.name.toUpperCase()} LAYOUT (${constraints.maxWidth.toStringAsFixed(0)}px)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.secondaryContainer,
                    side: BorderSide.none,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildButtonsShowcase() {
    return AppCard(
      title: 'Action Button Variants',
      subtitle: 'Primary, secondary outlined, loading, and disabled states.',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          AppButton.primary(
            text: 'Primary Action',
            leadingIcon: const Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
            ),
            onPressed: () {},
          ),
          AppButton.secondary(
            text: 'Secondary Action',
            leadingIcon: const Icon(Icons.business_center_outlined, size: 18),
            onPressed: () {},
          ),
          AppButton.primary(
            text: 'Loading State',
            isLoading: _isLoadingExample,
            onPressed: () {
              setState(() => _isLoadingExample = !_isLoadingExample);
            },
          ),
          const AppButton.primary(text: 'Disabled Button', onPressed: null),
          AppButton.text(text: 'Text Button', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFormControlsShowcase() {
    return AppCard(
      title: 'Input & Selection Controls',
      subtitle: 'Standardized text fields, search bar, and dropdown controls.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AppSearchField(),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(
            label: 'Organization Name',
            hintText: 'e.g., Acme Industrial Solutions Ltd.',
            prefixIcon: Icon(
              Icons.corporate_fare_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppDropdown<String>(
            label: 'Industry Classification',
            hintText: 'Select your core industry sector',
            value: _selectedIndustry,
            items: _industryOptions,
            onChanged: (String? val) {
              setState(() => _selectedIndustry = val);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(
            label: 'Work Email Address',
            hintText: 'name@company.com',
            errorText: 'Please enter a valid business email address',
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardShowcase() {
    return AppCard(
      title: 'Enterprise Partner Profile',
      subtitle:
          'Sample structured B2B informational card with header actions and footer.',
      headerAction: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
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
      footer: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'Member since 2026',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          AppButton.secondary(
            text: 'View Network Profile',
            height: 38,
            onPressed: () {},
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Global Logistics & Freight Services Corp.',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Specializing in cross-border freight forwarding, automated supply chain routing, and bonded warehousing.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackStatesShowcase() {
    return Column(
      children: <Widget>[
        const AppCard(
          title: 'System Loading Indicator',
          subtitle:
              'Clean circular progress indicator with informative status caption.',
          child: AppLoadingIndicator(
            message: 'Synchronizing network catalog...',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          title: 'Empty State Display',
          subtitle: 'Clean empty container with action slot.',
          child: AppEmptyState(
            icon: Icons.hub_outlined,
            title: 'No Network Connections Found',
            description:
                'Start connecting with verified industry partners to build your B2B supply network.',
            actionLabel: 'Explore Directory',
            onAction: () {},
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          title: 'Error State Display',
          subtitle: 'Informative error card with a retry action.',
          child: AppErrorState(
            title: 'Network Communication Timeout',
            description:
                'Unable to reach the B2B catalog directory service. Please check your connection.',
            retryLabel: 'Retry Connection',
            onRetry: () {},
          ),
        ),
      ],
    );
  }
}
