import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/security_models.dart';
import 'package:connexa/features/auth/presentation/forgot_password_screen.dart';
import 'package:connexa/features/auth/presentation/reset_password_screen.dart';
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
import 'package:connexa/features/products/models/product_models.dart';
import 'package:connexa/features/products/presentation/inquiries_screen.dart';
import 'package:connexa/features/products/presentation/inquiry_details_screen.dart';
import 'package:connexa/features/products/presentation/product_details_screen.dart';
import 'package:connexa/features/products/presentation/products_screen.dart';
import 'package:connexa/features/profile/presentation/account_settings_screen.dart';
import 'package:connexa/features/profile/presentation/active_sessions_screen.dart';
import 'package:connexa/features/profile/presentation/admin_verification_screen.dart';
import 'package:connexa/features/profile/presentation/business_verification_screen.dart';
import 'package:connexa/features/profile/presentation/change_password_screen.dart';
import 'package:connexa/features/profile/presentation/edit_profile_screen.dart';
import 'package:connexa/features/profile/presentation/profile_screen.dart';
import 'package:connexa/features/notifications/presentation/notifications_screen.dart';
import 'package:connexa/features/registration/presentation/registration_success_screen.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';
import 'package:connexa/features/rfq/presentation/rfqs_screen.dart';
import 'package:connexa/features/rfq/presentation/rfq_details_screen.dart';
import 'package:connexa/features/orders/presentation/orders_screen.dart';
import 'package:connexa/features/orders/presentation/order_details_screen.dart';
import 'package:connexa/features/job_work/presentation/job_work_marketplace_screen.dart';
import 'package:connexa/features/job_work/presentation/post_job_work_screen.dart';
import 'package:connexa/features/job_work/presentation/job_work_details_screen.dart';
import 'package:connexa/features/job_work/presentation/job_work_orders_screen.dart';
import 'package:connexa/features/job_work/presentation/job_work_order_details_screen.dart';
import 'package:connexa/features/services/presentation/services_marketplace_screen.dart';
import 'package:connexa/features/services/presentation/post_service_screen.dart';
import 'package:connexa/features/services/presentation/service_details_screen.dart';
import 'package:connexa/features/services/presentation/service_inquiry_details_screen.dart';
import 'package:connexa/features/recruitment/presentation/job_listings_screen.dart';
import 'package:connexa/features/recruitment/presentation/post_job_screen.dart';
import 'package:connexa/features/recruitment/presentation/job_details_screen.dart';
import 'package:connexa/features/recruitment/presentation/job_applicants_screen.dart';
import 'package:connexa/features/recruitment/presentation/job_application_details_screen.dart';
import 'package:connexa/features/feed/presentation/business_feed_screen.dart';
import 'package:connexa/features/feed/presentation/create_post_screen.dart';
import 'package:connexa/features/feed/presentation/post_details_screen.dart';
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

/// Global root navigator key for deep-link push notification handling outside widget context.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

/// Riverpod provider exposing the application router configuration.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final AuthRouterNotifier authNotifier = AuthRouterNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
          loc.startsWith('/profile/') ||
          loc == '/account-settings' ||
          loc == '/change-password' ||
          loc == '/active-sessions' ||
          loc.startsWith('/admin/') ||
          loc == '/directory' ||
          loc == '/network' ||
          loc == '/products' ||
          loc.startsWith('/products/') ||
          loc == '/inquiries' ||
          loc.startsWith('/inquiries/') ||
          loc == '/rfqs' ||
          loc.startsWith('/rfqs/') ||
          loc == '/orders' ||
          loc.startsWith('/orders/') ||
          loc == '/job-works' ||
          loc.startsWith('/job-works/') ||
          loc == '/job-work-orders' ||
          loc.startsWith('/job-work-orders/') ||
          loc == '/services' ||
          loc.startsWith('/services/') ||
          loc.startsWith('/service-inquiries/') ||
          loc == '/jobs' ||
          loc.startsWith('/jobs/') ||
          loc.startsWith('/job-applications/') ||
          loc == '/feed' ||
          loc.startsWith('/feed/') ||
          loc == '/notifications';
      final bool isAuthRoute =
          loc == '/login' ||
          loc == '/forgot-password' ||
          loc == '/reset-password';

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
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
            ),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        pageBuilder: (BuildContext context, GoRouterState state) {
          String identifier = '';
          ForgotPasswordResponse initialResponse = const ForgotPasswordResponse(
            success: true,
            message: '',
            maskedDestination: '',
            channel: 'Email',
            flowId: '',
            challengeId: 0,
            expirySeconds: 600,
          );
          if (state.extra is Map<String, dynamic>) {
            final Map<String, dynamic> extra =
                state.extra! as Map<String, dynamic>;
            identifier = extra['identifier'] as String? ?? '';
            if (extra['response'] is ForgotPasswordResponse) {
              initialResponse = extra['response'] as ForgotPasswordResponse;
            }
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: ResetPasswordScreen(
              identifier: identifier,
              initialResponse: initialResponse,
            ),
          );
        },
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
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const NotificationsScreen(),
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
        path: '/profile/verification',
        name: 'profile-verification',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const BusinessVerificationScreen(),
            ),
      ),
      GoRoute(
        path: '/account-settings',
        name: 'account-settings',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const AccountSettingsScreen(),
            ),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ChangePasswordScreen(),
            ),
      ),
      GoRoute(
        path: '/active-sessions',
        name: 'active-sessions',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ActiveSessionsScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/verifications',
        name: 'admin-verifications',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const AdminVerificationScreen(),
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
        path: '/products',
        name: 'products',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ProductsScreen(),
            ),
      ),
      GoRoute(
        path: '/products/:id',
        name: 'product-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int productId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final Product? initialProduct = state.extra is Product
              ? state.extra as Product
              : null;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: ProductDetailsScreen(
              productId: productId,
              initialProduct: initialProduct,
            ),
          );
        },
      ),
      GoRoute(
        path: '/inquiries',
        name: 'inquiries',
        pageBuilder: (BuildContext context, GoRouterState state) {
          int initialTab = 0;
          if (state.extra is int) {
            initialTab = state.extra as int;
          } else if (state.uri.queryParameters.containsKey('tab')) {
            initialTab = int.tryParse(state.uri.queryParameters['tab']!) ?? 0;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: InquiriesScreen(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        path: '/inquiries/:id',
        name: 'inquiry-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int inquiryId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final ProductInquiry? initialInquiry = state.extra is ProductInquiry
              ? state.extra as ProductInquiry
              : null;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: InquiryDetailsScreen(
              inquiryId: inquiryId,
              initialInquiry: initialInquiry,
            ),
          );
        },
      ),
      GoRoute(
        path: '/rfqs',
        name: 'rfqs',
        pageBuilder: (BuildContext context, GoRouterState state) {
          int initialTab = 0;
          if (state.extra is int) {
            initialTab = state.extra as int;
          } else if (state.uri.queryParameters.containsKey('tab')) {
            initialTab = int.tryParse(state.uri.queryParameters['tab']!) ?? 0;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: RfqsScreen(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        path: '/rfqs/:id',
        name: 'rfq-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int rfqId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final Rfq? initialRfq =
              state.extra is Rfq ? state.extra as Rfq : null;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: RfqDetailsScreen(
              rfqId: rfqId,
              initialRfq: initialRfq,
            ),
          );
        },
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        pageBuilder: (BuildContext context, GoRouterState state) {
          int initialTab = 0;
          if (state.extra is int) {
            initialTab = state.extra as int;
          } else if (state.uri.queryParameters.containsKey('tab')) {
            initialTab = int.tryParse(state.uri.queryParameters['tab']!) ?? 0;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: OrdersScreen(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'order-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int orderId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: OrderDetailsScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/job-works',
        name: 'job-works',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
          key: state.pageKey,
          child: const JobWorkMarketplaceScreen(),
        ),
      ),
      GoRoute(
        path: '/job-works/create',
        name: 'job-work-create',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
          key: state.pageKey,
          child: const PostJobWorkScreen(),
        ),
      ),
      GoRoute(
        path: '/job-works/:id',
        name: 'job-work-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int reqId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobWorkDetailsScreen(requirementId: reqId),
          );
        },
      ),
      GoRoute(
        path: '/job-work-orders',
        name: 'job-work-orders',
        pageBuilder: (BuildContext context, GoRouterState state) {
          int initialTab = 0;
          if (state.extra is int) {
            initialTab = state.extra as int;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobWorkOrdersScreen(initialTab: initialTab),
          );
        },
      ),
      GoRoute(
        path: '/job-work-orders/:id',
        name: 'job-work-order-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int orderId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobWorkOrderDetailsScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/services',
        name: 'services',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const ServicesMarketplaceScreen(),
            ),
      ),
      GoRoute(
        path: '/services/post',
        name: 'services-post',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const PostServiceScreen(),
            ),
      ),
      GoRoute(
        path: '/services/edit/:id',
        name: 'services-edit',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int? serviceId =
              int.tryParse(state.pathParameters['id'] ?? '');
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: PostServiceScreen(serviceId: serviceId),
          );
        },
      ),
      GoRoute(
        path: '/services/:id',
        name: 'service-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int serviceId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: ServiceDetailsScreen(serviceId: serviceId),
          );
        },
      ),
      GoRoute(
        path: '/service-inquiries/:id',
        name: 'service-inquiry-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int inquiryId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: ServiceInquiryDetailsScreen(inquiryId: inquiryId),
          );
        },
      ),
      GoRoute(
        path: '/jobs',
        name: 'jobs',
        pageBuilder: (BuildContext context, GoRouterState state) {
          int initialTab = 0;
          if (state.extra is int) {
            initialTab = state.extra as int;
          } else if (state.uri.queryParameters.containsKey('tab')) {
            initialTab = int.tryParse(state.uri.queryParameters['tab']!) ?? 0;
          }
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobListingsScreen(initialTabIndex: initialTab),
          );
        },
      ),
      GoRoute(
        path: '/jobs/post',
        name: 'jobs-post',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const PostJobScreen(),
            ),
      ),
      GoRoute(
        path: '/jobs/edit/:id',
        name: 'jobs-edit',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int? jobId = int.tryParse(state.pathParameters['id'] ?? '');
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: PostJobScreen(jobId: jobId),
          );
        },
      ),
      GoRoute(
        path: '/jobs/:id',
        name: 'job-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int jobId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobDetailsScreen(jobId: jobId),
          );
        },
      ),
      GoRoute(
        path: '/jobs/:id/applicants',
        name: 'job-applicants',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int jobId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobApplicantsScreen(jobId: jobId),
          );
        },
      ),
      GoRoute(
        path: '/job-applications/:id',
        name: 'job-application-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int applicationId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: JobApplicationDetailsScreen(applicationId: applicationId),
          );
        },
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const BusinessFeedScreen(),
            ),
      ),
      GoRoute(
        path: '/feed/create',
        name: 'feed-create',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            AppAnimations.buildPageTransition(
              key: state.pageKey,
              child: const CreatePostScreen(),
            ),
      ),
      GoRoute(
        path: '/feed/edit/:id',
        name: 'feed-edit',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int? editPostId = int.tryParse(state.pathParameters['id'] ?? '');
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: CreatePostScreen(editPostId: editPostId),
          );
        },
      ),
      GoRoute(
        path: '/feed/posts/:id',
        name: 'feed-post-details',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int postId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppAnimations.buildPageTransition(
            key: state.pageKey,
            child: PostDetailsScreen(postId: postId),
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
