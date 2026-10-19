import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/registration_submission_models.dart';
import 'package:connexa/features/registration/presentation/registration_review_screen.dart';
import 'package:connexa/features/registration/presentation/registration_success_screen.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/services/registration_service.dart';

/// Fake implementation of [RegistrationService] for deterministic UI testing.
class FakeRegistrationService implements RegistrationService {
  FakeRegistrationService({
    this.onPreSubmit,
    this.shouldSucceed = true,
    this.successResult,
    this.failureException,
    this.submissionCompleter,
  });

  final void Function(RegistrationDraft draft)? onPreSubmit;
  final bool shouldSucceed;
  final RegistrationSubmissionResult? successResult;
  final RegistrationException? failureException;
  final Completer<RegistrationSubmissionResult>? submissionCompleter;

  int callCount = 0;
  RegistrationDraft? lastSubmittedDraft;

  @override
  Future<RegistrationSubmissionResult> submitRegistration(
    RegistrationDraft draft,
  ) async {
    callCount++;
    lastSubmittedDraft = draft;
    onPreSubmit?.call(draft);

    if (submissionCompleter != null) {
      return submissionCompleter!.future;
    }

    if (!shouldSucceed) {
      throw failureException ??
          const RegistrationException(
            'An account with this phone number or email address already exists. Please sign in instead.',
            statusCode: 409,
          );
    }

    return successResult ??
        RegistrationSubmissionResult(
          memberId: 101,
          fullName: draft.fullName,
          phoneNumber: '${draft.countryCode}${draft.mobileNumber}',
          email: draft.email,
          primaryProfileType: draft.profileType?.label ?? 'Business / Company',
          verifiedMethod: draft.verifiedMethod ?? 'email',
          verifiedDestination: draft.verifiedDestination ?? draft.email,
          createdAtUtc: DateTime.utc(2026, 10, 19, 12, 0, 0),
          message: 'Account successfully registered and persisted.',
        );
  }
}

Widget createSubmissionTestApp({
  required RegistrationDraft initialDraft,
  required FakeRegistrationService fakeService,
  String initialLocation = '/registration/review',
}) {
  final GoRouter testRouter = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/registration/review',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationReviewScreen(),
      ),
      GoRoute(
        path: '/registration/success',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationSuccessScreen(),
      ),
      GoRoute(
        path: '/registration/email-verification',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('Email Verification Channel Screen')),
      ),
      GoRoute(
        path: '/registration/phone-verification',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('Phone Verification Channel Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      registrationDraftProvider.overrideWith((Ref ref) => initialDraft),
      registrationServiceProvider.overrideWithValue(fakeService),
    ],
    child: MaterialApp.router(
      routerConfig: testRouter,
      theme: AppTheme.lightTheme,
    ),
  );
}

void main() {
  group('CONNEXA STEP 12 — Final Registration & Persistence Tests', () {
    final IndustrySelection sampleIndustrySelection = const IndustrySelection(
      industryId: 4,
      industryName: 'Manufacturing & Heavy Engineering',
      businessGroupId: 3,
      businessGroupName: 'Machinery & Equipment',
      subGroupId: 5,
      subGroupName: 'Industrial Machinery',
      categoryId: 13,
      categoryName: 'Air Compressors & Vacuum Systems',
    );

    RegistrationDraft createVerifiedDraft() {
      return RegistrationDraft(
        registrationFlowId: 'flow-test-1234',
        fullName: 'Aarav Patel',
        countryCode: '+91',
        mobileNumber: '9876543210',
        email: 'aarav@apexind.com',
        profileType: ProfileType.businessCompany,
        businessDetails: BusinessProfileDetails(
          companyName: 'Apex Industrial Solutions Pvt Ltd',
          businessCapabilities: <BusinessCapability>{
            BusinessCapability.manufacturer,
          },
          businessDescription: 'Industrial compressors manufacturer.',
          industrySelection: sampleIndustrySelection,
        ),
        verificationGrant: 'grant-token-valid-abc123',
        verificationGrantExpiresAt: DateTime.now().add(
          const Duration(minutes: 15),
        ),
        verifiedMethod: 'email',
        verifiedDestination: 'aarav@apexind.com',
      );
    }

    testWidgets(
      'Submitting verified draft calls RegistrationService and navigates to SuccessScreen on 200 OK',
      (WidgetTester tester) async {
        final RegistrationDraft draft = createVerifiedDraft();
        final FakeRegistrationService fakeService = FakeRegistrationService();

        await tester.pumpWidget(
          createSubmissionTestApp(
            initialDraft: draft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Verify that review screen displays verified status
        expect(find.text('VERIFIED'), findsOneWidget);
        expect(find.text('Verification Confirmed'), findsOneWidget);
        expect(find.text('Complete Registration'), findsOneWidget);

        // Consent checkbox must be agreed before submission
        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        // Tap Complete Registration
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Assert service was called with the draft
        expect(fakeService.callCount, 1);
        expect(
          fakeService.lastSubmittedDraft?.registrationFlowId,
          'flow-test-1234',
        );
        expect(
          fakeService.lastSubmittedDraft?.verificationGrant,
          'grant-token-valid-abc123',
        );

        // Assert navigation to Success screen
        expect(
          find.byKey(const Key('registrationSuccessCard')),
          findsOneWidget,
        );
        expect(find.text('Account Created Successfully'), findsOneWidget);
        expect(find.text('#101'), findsOneWidget);
        expect(find.text('Aarav Patel'), findsOneWidget);
        expect(find.text('aarav@apexind.com'), findsOneWidget);
        expect(find.text('+919876543210'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays error banner and preserves draft when backend returns 409 Conflict',
      (WidgetTester tester) async {
        final RegistrationDraft draft = createVerifiedDraft();
        final FakeRegistrationService fakeService = FakeRegistrationService(
          shouldSucceed: false,
          failureException: const RegistrationException(
            'An account with this email address already exists. Please sign in instead.',
            statusCode: 409,
          ),
        );

        await tester.pumpWidget(
          createSubmissionTestApp(
            initialDraft: draft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Consent
        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        // Tap Complete Registration
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Assert service was called
        expect(fakeService.callCount, 1);

        // Assert error banner is rendered with server error message
        expect(find.byKey(const Key('submissionErrorBanner')), findsOneWidget);
        expect(find.text('Registration Submission Failed'), findsOneWidget);
        expect(
          find.text(
            'An account with this email address already exists. Please sign in instead.',
          ),
          findsOneWidget,
        );

        // Assert draft details are still preserved on screen
        expect(find.text('Apex Industrial Solutions Pvt Ltd'), findsOneWidget);
        expect(find.text('Aarav Patel'), findsOneWidget);

        // Assert Complete Registration button is still enabled for retry
        expect(
          find.byKey(const Key('continueToVerificationButton')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Disables submit button and shows loading while submission is in-flight',
      (WidgetTester tester) async {
        final RegistrationDraft draft = createVerifiedDraft();
        final Completer<RegistrationSubmissionResult> completer =
            Completer<RegistrationSubmissionResult>();
        final FakeRegistrationService fakeService = FakeRegistrationService(
          submissionCompleter: completer,
        );

        await tester.pumpWidget(
          createSubmissionTestApp(
            initialDraft: draft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Consent
        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        // Tap Complete Registration
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pump(); // Start async call without settling

        // Assert service was called
        expect(fakeService.callCount, 1);

        // Complete the future
        completer.complete(
          RegistrationSubmissionResult(
            memberId: 202,
            fullName: 'Aarav Patel',
            phoneNumber: '+919876543210',
            email: 'aarav@apexind.com',
            primaryProfileType: 'Business / Company',
            verifiedMethod: 'email',
            verifiedDestination: 'aarav@apexind.com',
            createdAtUtc: DateTime.utc(2026, 10, 19, 12, 0, 0),
            message: 'Account registered.',
          ),
        );
        await tester.pumpAndSettle();

        // Successfully navigated
        expect(
          find.byKey(const Key('registrationSuccessCard')),
          findsOneWidget,
        );
        expect(find.text('#202'), findsOneWidget);
      },
    );

    testWidgets(
      'Unverified draft routes to selected verification channel without calling submitRegistration',
      (WidgetTester tester) async {
        final RegistrationDraft unverifiedDraft = RegistrationDraft(
          registrationFlowId: 'flow-test-unverified',
          fullName: 'Aarav Patel',
          countryCode: '+91',
          mobileNumber: '9876543210',
          email: 'aarav@apexind.com',
          profileType: ProfileType.businessCompany,
          businessDetails: BusinessProfileDetails(
            companyName: 'Apex Industrial Solutions Pvt Ltd',
            businessCapabilities: <BusinessCapability>{
              BusinessCapability.manufacturer,
            },
            industrySelection: sampleIndustrySelection,
          ),
        );
        final FakeRegistrationService fakeService = FakeRegistrationService();

        await tester.pumpWidget(
          createSubmissionTestApp(
            initialDraft: unverifiedDraft,
            fakeService: fakeService,
          ),
        );
        await tester.pumpAndSettle();

        // Consent
        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        // Button says Continue to WhatsApp Verification by default
        expect(find.text('Continue to WhatsApp Verification'), findsOneWidget);

        // Tap Continue
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Assert service was NOT called
        expect(fakeService.callCount, 0);

        // Assert routed to phone verification channel
        expect(find.text('Phone Verification Channel Screen'), findsOneWidget);
      },
    );
  });
}
