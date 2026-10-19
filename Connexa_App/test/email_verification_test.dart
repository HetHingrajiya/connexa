import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/verification_models.dart';
import 'package:connexa/features/registration/presentation/email_verification_screen.dart';
import 'package:connexa/features/registration/presentation/phone_verification_screen.dart';
import 'package:connexa/features/registration/presentation/registration_review_screen.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/services/email_verification_service.dart';

class FakeEmailVerificationService implements EmailVerificationService {
  bool sendShouldFail = false;
  bool verifyShouldFail = false;
  String sendErrorMessage = 'Failed to dispatch Gmail SMTP OTP.';
  String verifyErrorMessage =
      'Incorrect verification code. Attempts remaining: 4.';
  int sendCallCount = 0;
  int resendCallCount = 0;
  int verifyCallCount = 0;
  String? lastVerifiedCode;

  @override
  Future<SendEmailOtpResult> sendOtp(SendEmailOtpRequest request) async {
    sendCallCount++;
    if (sendShouldFail) {
      throw VerificationException(sendErrorMessage, statusCode: 502);
    }
    return SendEmailOtpResult(
      challengeId: 202,
      maskedEmail: 'h•••a@gmail.com',
      expiresAtUtc: DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: 60,
      accepted: true,
      status: 'Pending',
      message: 'OTP dispatched via Gmail SMTP.',
    );
  }

  @override
  Future<ResendEmailOtpResult> resendOtp(ResendEmailOtpRequest request) async {
    resendCallCount++;
    if (sendShouldFail) {
      throw VerificationException(sendErrorMessage, statusCode: 502);
    }
    return ResendEmailOtpResult(
      challengeId: 202,
      maskedEmail: 'h•••a@gmail.com',
      expiresAtUtc: DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: 60,
      accepted: true,
      status: 'Pending',
      message: 'OTP resent via Gmail SMTP.',
    );
  }

  @override
  Future<VerifyEmailOtpResult> verifyOtp(VerifyEmailOtpRequest request) async {
    verifyCallCount++;
    lastVerifiedCode = request.otpCode;
    if (verifyShouldFail) {
      throw VerificationException(verifyErrorMessage, statusCode: 400);
    }
    return VerifyEmailOtpResult(
      verified: true,
      maskedEmail: 'h•••a@gmail.com',
      verificationGrant: 'grant_email_opaque_secret_test_token_12345',
      verificationGrantExpiresAtUtc: DateTime.now().add(
        const Duration(hours: 1),
      ),
      message: 'Email address verified.',
    );
  }

  @override
  Future<String?> getStoredVerificationGrant() async => null;

  @override
  Future<void> clearStoredVerificationGrant() async {}
}

Widget createEmailVerificationTestApp({
  required FakeEmailVerificationService fakeService,
  RegistrationDraft? initialDraft,
}) {
  final GoRouter testRouter = GoRouter(
    initialLocation: '/registration/email-verification',
    routes: <RouteBase>[
      GoRoute(
        path: '/registration/review',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationReviewScreen(),
      ),
      GoRoute(
        path: '/registration/email-verification',
        builder: (BuildContext context, GoRouterState state) =>
            const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/registration/phone-verification',
        builder: (BuildContext context, GoRouterState state) =>
            const PhoneVerificationScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('Onboarding Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      emailVerificationServiceProvider.overrideWithValue(fakeService),
      if (initialDraft != null)
        registrationDraftProvider.overrideWith((Ref ref) => initialDraft),
    ],
    child: MaterialApp.router(
      theme: AppTheme.darkTheme,
      routerConfig: testRouter,
    ),
  );
}

void main() {
  group('CONNEXA STEP 11 — Email OTP Verification Widget Tests', () {
    late FakeEmailVerificationService fakeService;

    setUp(() {
      fakeService = FakeEmailVerificationService();
    });

    testWidgets(
      'EmailVerificationScreen requests OTP on mount and renders masked email',
      (WidgetTester tester) async {
        final RegistrationDraft draft = const RegistrationDraft(
          fullName: 'Het Hingrajiya',
          email: 'hethingrajiya@gmail.com',
          countryCode: '+91',
          mobileNumber: '9876543210',
          profileType: ProfileType.businessCompany,
        );

        await tester.pumpWidget(
          createEmailVerificationTestApp(
            fakeService: fakeService,
            initialDraft: draft,
          ),
        );
        await tester.pumpAndSettle();

        expect(fakeService.sendCallCount, 1);
        expect(find.text('Verify Your Email Address'), findsOneWidget);
        expect(
          find.byKey(const Key('maskedEmailAddressDisplay')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('emailOtpInputField')), findsOneWidget);
        expect(find.byKey(const Key('verifyEmailOtpButton')), findsOneWidget);
        expect(find.byKey(const Key('resendEmailOtpButton')), findsOneWidget);
      },
    );

    testWidgets(
      'Entering correct 6-digit OTP verifies email and displays success banner',
      (WidgetTester tester) async {
        final RegistrationDraft draft = const RegistrationDraft(
          fullName: 'Het Hingrajiya',
          email: 'hethingrajiya@gmail.com',
          profileType: ProfileType.businessCompany,
        );

        await tester.pumpWidget(
          createEmailVerificationTestApp(
            fakeService: fakeService,
            initialDraft: draft,
          ),
        );
        await tester.pumpAndSettle();

        // Enter 6 digits
        await tester.enterText(
          find.byKey(const Key('emailOtpInputField')),
          '889900',
        );
        await tester.pumpAndSettle();

        expect(fakeService.verifyCallCount, 1);
        expect(fakeService.lastVerifiedCode, '889900');
        expect(find.text('VERIFIED VIA EMAIL'), findsOneWidget);
        expect(find.text('Email Address Verified'), findsOneWidget);
        expect(
          find.byKey(const Key('returnToReviewFromEmailVerifiedButton')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Incorrect OTP code displays server error banner without clearing challenge',
      (WidgetTester tester) async {
        fakeService.verifyShouldFail = true;
        fakeService.verifyErrorMessage =
            'Incorrect verification code. Attempts remaining: 3.';

        final RegistrationDraft draft = const RegistrationDraft(
          fullName: 'Het Hingrajiya',
          email: 'hethingrajiya@gmail.com',
          profileType: ProfileType.businessCompany,
        );

        await tester.pumpWidget(
          createEmailVerificationTestApp(
            fakeService: fakeService,
            initialDraft: draft,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('emailOtpInputField')),
          '112233',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('emailVerificationErrorMessage')),
          findsOneWidget,
        );
        expect(
          find.text('Incorrect verification code. Attempts remaining: 3.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('SMTP provider dispatch failure renders error message safely', (
      WidgetTester tester,
    ) async {
      fakeService.sendShouldFail = true;
      fakeService.sendErrorMessage =
          'Gmail SMTP credentials are not configured on the server.';

      final RegistrationDraft draft = const RegistrationDraft(
        fullName: 'Het Hingrajiya',
        email: 'hethingrajiya@gmail.com',
        profileType: ProfileType.businessCompany,
      );

      await tester.pumpWidget(
        createEmailVerificationTestApp(
          fakeService: fakeService,
          initialDraft: draft,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('emailVerificationErrorMessage')),
        findsOneWidget,
      );
      expect(
        find.text('Gmail SMTP credentials are not configured on the server.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'RegistrationReviewScreen allows switching between WhatsApp and Email verification',
      (WidgetTester tester) async {
        final GoRouter reviewRouter = GoRouter(
          initialLocation: '/registration/review',
          routes: <RouteBase>[
            GoRoute(
              path: '/registration/review',
              builder: (BuildContext context, GoRouterState state) =>
                  const RegistrationReviewScreen(),
            ),
            GoRoute(
              path: '/registration/email-verification',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(
                    body: Text('Email Verification Destination Screen'),
                  ),
            ),
            GoRoute(
              path: '/registration/phone-verification',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(
                    body: Text('WhatsApp Verification Destination Screen'),
                  ),
            ),
          ],
        );

        final RegistrationDraft draft = const RegistrationDraft(
          fullName: 'Het Hingrajiya',
          email: 'hethingrajiya@gmail.com',
          countryCode: '+91',
          mobileNumber: '9876543210',
          profileType: ProfileType.businessCompany,
          businessDetails: BusinessProfileDetails(
            companyName: 'Connexa Enterprise Ltd',
            businessCapabilities: <BusinessCapability>{
              BusinessCapability.manufacturer,
            },
            industrySelection: IndustrySelection(
              industryId: 1,
              industryName: 'Manufacturing',
              businessGroupId: 2,
              businessGroupName: 'Machinery',
              subGroupId: 3,
              subGroupName: 'Tools',
              categoryId: 4,
              categoryName: 'Standard Tools',
            ),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              emailVerificationServiceProvider.overrideWithValue(fakeService),
              registrationDraftProvider.overrideWith((Ref ref) => draft),
            ],
            child: MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: reviewRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check verification options exist
        expect(
          find.byKey(const Key('whatsappVerificationOption')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('emailVerificationOption')),
          findsOneWidget,
        );

        // Select Email Verification
        final Finder emailOption = find.byKey(
          const Key('emailVerificationOption'),
        );
        await tester.ensureVisible(emailOption);
        await tester.tap(emailOption);
        await tester.pumpAndSettle();

        // Agree to consent checkbox
        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        // Continue button should show Email
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        expect(find.text('Continue to Email Verification'), findsOneWidget);

        // Tap continue -> should navigate to email verification
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Email Verification Destination Screen'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Either Email OR Phone verified grant satisfies registration review policy',
      (WidgetTester tester) async {
        final GoRouter reviewRouter = GoRouter(
          initialLocation: '/registration/review',
          routes: <RouteBase>[
            GoRoute(
              path: '/registration/review',
              builder: (BuildContext context, GoRouterState state) =>
                  const RegistrationReviewScreen(),
            ),
          ],
        );

        // Pre-verified via Email grant
        final RegistrationDraft verifiedDraft = const RegistrationDraft(
          fullName: 'Het Hingrajiya',
          email: 'hethingrajiya@gmail.com',
          countryCode: '+91',
          mobileNumber: '9876543210',
          profileType: ProfileType.businessCompany,
          verificationGrant: 'grant_valid_server_token_xyz',
          verifiedMethod: 'email',
          verifiedDestination: 'h•••a@gmail.com',
          businessDetails: BusinessProfileDetails(
            companyName: 'Connexa Enterprise Ltd',
            businessCapabilities: <BusinessCapability>{
              BusinessCapability.manufacturer,
            },
            industrySelection: IndustrySelection(
              industryId: 1,
              industryName: 'Manufacturing',
              businessGroupId: 2,
              businessGroupName: 'Machinery',
              subGroupId: 3,
              subGroupName: 'Tools',
              categoryId: 4,
              categoryName: 'Standard Tools',
            ),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              emailVerificationServiceProvider.overrideWithValue(fakeService),
              registrationDraftProvider.overrideWith(
                (Ref ref) => verifiedDraft,
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: reviewRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Status card should show verified
        expect(find.byKey(const Key('verifiedStatusCard')), findsOneWidget);
        expect(
          find.text('Identity Verified via Email (h•••a@gmail.com)'),
          findsOneWidget,
        );
        expect(find.text('Verification Confirmed'), findsOneWidget);
      },
    );
  });
}
