import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/verification_models.dart';
import 'package:connexa/features/registration/presentation/phone_verification_screen.dart';
import 'package:connexa/features/registration/presentation/registration_review_screen.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/services/phone_verification_service.dart';

class FakePhoneVerificationService implements PhoneVerificationService {
  bool sendShouldFail = false;
  bool verifyShouldFail = false;
  String sendErrorMessage = 'Failed to dispatch WhatsApp OTP.';
  String verifyErrorMessage =
      'Incorrect verification code. Attempts remaining: 4.';
  int sendCallCount = 0;
  int resendCallCount = 0;
  int verifyCallCount = 0;
  String? lastVerifiedCode;

  @override
  Future<SendOtpResult> sendOtp(SendOtpRequest request) async {
    sendCallCount++;
    if (sendShouldFail) {
      throw VerificationException(sendErrorMessage, statusCode: 502);
    }
    return SendOtpResult(
      challengeId: 101,
      maskedPhoneNumber: '+91 ••••• ••210',
      expiresAtUtc: DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: 60,
      accepted: true,
      status: 'Pending',
      message: 'OTP dispatched via WhatsApp.',
    );
  }

  @override
  Future<ResendOtpResult> resendOtp(ResendOtpRequest request) async {
    resendCallCount++;
    if (sendShouldFail) {
      throw VerificationException(sendErrorMessage, statusCode: 502);
    }
    return ResendOtpResult(
      challengeId: 101,
      maskedPhoneNumber: '+91 ••••• ••210',
      expiresAtUtc: DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: 60,
      accepted: true,
      status: 'Pending',
      message: 'OTP resent via WhatsApp.',
    );
  }

  @override
  Future<VerifyOtpResult> verifyOtp(VerifyOtpRequest request) async {
    verifyCallCount++;
    lastVerifiedCode = request.otpCode;
    if (verifyShouldFail) {
      throw VerificationException(verifyErrorMessage, statusCode: 400);
    }
    return VerifyOtpResult(
      verified: true,
      maskedPhoneNumber: '+91 ••••• ••210',
      verificationGrant:
          'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
      verificationGrantExpiresAtUtc: DateTime.now().add(
        const Duration(hours: 1),
      ),
      message: 'Phone number successfully verified.',
    );
  }

  @override
  Future<String?> getStoredVerificationGrant() async => null;

  @override
  Future<void> clearStoredVerificationGrant() async {}
}

Widget createVerificationTestApp({
  required RegistrationDraft initialDraft,
  required FakePhoneVerificationService fakeService,
  void Function(ProviderContainer container)? onContainerAvailable,
}) {
  final GoRouter testRouter = GoRouter(
    initialLocation: '/registration/phone-verification',
    routes: <RouteBase>[
      GoRoute(
        path: '/registration/review',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationReviewScreen(),
      ),
      GoRoute(
        path: '/registration/phone-verification',
        builder: (BuildContext context, GoRouterState state) =>
            const PhoneVerificationScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      registrationDraftProvider.overrideWith((Ref ref) => initialDraft),
      phoneVerificationServiceProvider.overrideWithValue(fakeService),
    ],
    child: Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        if (onContainerAvailable != null) {
          onContainerAvailable(ProviderScope.containerOf(context));
        }
        return MaterialApp.router(
          routerConfig: testRouter,
          theme: AppTheme.lightTheme,
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final RegistrationDraft sampleDraft = RegistrationDraft(
    fullName: 'Aarav Patel',
    countryCode: '+91',
    mobileNumber: '9876543210',
    email: 'aarav@apexind.com',
    profileType: ProfileType.businessCompany,
    businessDetails: const BusinessProfileDetails(
      companyName: 'Apex Industrial Solutions Pvt Ltd',
      businessCapabilities: <BusinessCapability>{
        BusinessCapability.manufacturer,
      },
    ),
  );

  group('PhoneVerificationScreen Widget Tests', () {
    testWidgets('Initiates WhatsApp verification and displays masked phone', (
      WidgetTester tester,
    ) async {
      final FakePhoneVerificationService fakeService =
          FakePhoneVerificationService();

      await tester.pumpWidget(
        createVerificationTestApp(
          initialDraft: sampleDraft,
          fakeService: fakeService,
        ),
      );
      await tester.pumpAndSettle();

      // Verified service was called
      expect(fakeService.sendCallCount, 1);

      // Check UI elements
      expect(find.text('Verify Your Phone Number'), findsOneWidget);
      expect(find.byKey(const Key('maskedPhoneNumberDisplay')), findsOneWidget);
      expect(find.text('+91 ••••• ••210'), findsOneWidget);
      expect(find.byKey(const Key('otpInputField')), findsOneWidget);
      expect(find.byKey(const Key('verifyOtpButton')), findsOneWidget);
      expect(find.byKey(const Key('resendOtpButton')), findsOneWidget);
    });

    testWidgets(
      'Resend button shows active countdown and prevents resend while cooling down',
      (WidgetTester tester) async {
        final FakePhoneVerificationService fakeService =
            FakePhoneVerificationService();

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Initial state has 60s cooldown
        expect(find.textContaining('Resend in'), findsOneWidget);

        // Attempting to tap disabled button does not increment resend call count
        final Finder resendBtn = find.byKey(const Key('resendOtpButton'));
        await tester.tap(resendBtn, warnIfMissed: false);
        await tester.pump();
        expect(fakeService.resendCallCount, 0);
      },
    );

    testWidgets(
      'Displays error banner when provider fails and does not show false success',
      (WidgetTester tester) async {
        final FakePhoneVerificationService fakeService =
            FakePhoneVerificationService();
        fakeService.sendShouldFail = true;
        fakeService.sendErrorMessage =
            'WhatsApp Cloud API gateway error: Destination unreachable.';

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Displays error banner
        expect(
          find.byKey(const Key('verificationErrorMessage')),
          findsOneWidget,
        );
        expect(
          find.text(
            'WhatsApp Cloud API gateway error: Destination unreachable.',
          ),
          findsOneWidget,
        );

        // Does NOT display verified state
        expect(find.text('Phone Number Verified'), findsNothing);
        expect(find.text('VERIFIED VIA WHATSAPP'), findsNothing);
      },
    );

    testWidgets(
      'Entering 6-digit code triggers verification and displays error on incorrect code',
      (WidgetTester tester) async {
        final FakePhoneVerificationService fakeService =
            FakePhoneVerificationService();
        fakeService.verifyShouldFail = true;
        fakeService.verifyErrorMessage =
            'Incorrect verification code. Attempts remaining: 4.';

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Enter 6-digit incorrect code
        final Finder otpField = find.byKey(const Key('otpInputField'));
        await tester.enterText(otpField, '112233');
        await tester.pumpAndSettle();

        expect(fakeService.verifyCallCount, 1);
        expect(fakeService.lastVerifiedCode, '112233');

        // Error message is presented
        expect(
          find.byKey(const Key('verificationErrorMessage')),
          findsOneWidget,
        );
        expect(
          find.text('Incorrect verification code. Attempts remaining: 4.'),
          findsOneWidget,
        );

        // Still in unverified state
        expect(find.text('Phone Number Verified'), findsNothing);
      },
    );

    testWidgets(
      'Successful server verification transitions to verified badge and retains grant',
      (WidgetTester tester) async {
        final FakePhoneVerificationService fakeService =
            FakePhoneVerificationService();
        ProviderContainer? container;

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
            onContainerAvailable: (ProviderContainer c) => container = c,
          ),
        );
        await tester.pumpAndSettle();

        // Enter correct 6-digit code
        final Finder otpField = find.byKey(const Key('otpInputField'));
        await tester.enterText(otpField, '654321');
        await tester.pumpAndSettle();

        expect(fakeService.verifyCallCount, 1);

        // Verified screen UI is displayed
        expect(find.text('Phone Number Verified'), findsOneWidget);
        expect(find.text('VERIFIED VIA WHATSAPP'), findsOneWidget);
        expect(
          find.byKey(const Key('returnToReviewFromVerifiedButton')),
          findsOneWidget,
        );

        // In-memory draft was updated with server-issued verification grant
        final RegistrationDraft updatedDraft = container!.read(
          registrationDraftProvider,
        );
        expect(updatedDraft.isPhoneVerified, isTrue);
        expect(
          updatedDraft.verificationGrant,
          'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
        );
      },
    );

    testWidgets(
      'Draft preservation: back navigation preserves registration draft',
      (WidgetTester tester) async {
        final FakePhoneVerificationService fakeService =
            FakePhoneVerificationService();
        ProviderContainer? container;

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
            onContainerAvailable: (ProviderContainer c) => container = c,
          ),
        );
        await tester.pumpAndSettle();

        // Tap back button
        final Finder backBtn = find.byKey(const Key('backButton'));
        await tester.tap(backBtn);
        await tester.pumpAndSettle();

        // Preserved draft in review screen
        expect(find.text('Review Your Registration'), findsOneWidget);
        expect(find.text('Aarav Patel'), findsOneWidget);

        final RegistrationDraft retainedDraft = container!.read(
          registrationDraftProvider,
        );
        expect(retainedDraft.fullName, 'Aarav Patel');
        expect(retainedDraft.mobileNumber, '9876543210');
        expect(
          retainedDraft.businessDetails?.companyName,
          'Apex Industrial Solutions Pvt Ltd',
        );
      },
    );

    testWidgets(
      'Mobile (360x640) and Desktop (1280x800) responsive layouts render without overflow',
      (WidgetTester tester) async {
        final FakePhoneVerificationService fakeService =
            FakePhoneVerificationService();

        // 1. Mobile layout
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Verify Your Phone Number'), findsOneWidget);

        // 2. Desktop layout
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createVerificationTestApp(
            initialDraft: sampleDraft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Verify Your Phone Number'), findsOneWidget);
      },
    );
  });
}
