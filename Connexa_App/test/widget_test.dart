import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/presentation/profile_details_screen.dart';
import 'package:connexa/features/registration/presentation/registration_screen.dart';
import 'package:connexa/features/registration/presentation/registration_step_3_placeholder_screen.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

Widget createTestApp({
  required RegistrationDraft initialDraft,
  String initialLocation = '/registration/step-2-placeholder',
  void Function(ProviderContainer container)? onContainerAvailable,
}) {
  final GoRouter testRouter = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/registration',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationScreen(),
      ),
      GoRoute(
        path: '/registration/step-2-placeholder',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileDetailsScreen(),
      ),
      GoRoute(
        path: '/registration/step-3-placeholder',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationStep3PlaceholderScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      registrationDraftProvider.overrideWith((Ref ref) => initialDraft),
    ],
    child: Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        if (onContainerAvailable != null) {
          onContainerAvailable(ProviderScope.containerOf(context));
        }
        return MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: testRouter,
        );
      },
    ),
  );
}

void main() {
  testWidgets(
    'Missing draft or profile type shows recovery screen and return button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(initialDraft: const RegistrationDraft()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Profile Type Selected'), findsOneWidget);
      expect(find.text('Return to Step 1'), findsOneWidget);

      // Tap Return to Step 1
      await tester.tap(find.text('Return to Step 1'));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Connexa Account'), findsOneWidget);
    },
  );

  testWidgets(
    'Business / Company form renders required fields and backend industry requirement',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Aarav Mehta',
            mobileNumber: '9876543210',
            email: 'aarav@apextech.com',
            profileType: ProfileType.businessCompany,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business & Company Details'), findsOneWidget);
      expect(find.text('Company / Business Name *'), findsOneWidget);
      expect(
        find.text('Business Type * (Select all that apply)'),
        findsOneWidget,
      );
      expect(find.text('Manufacturer'), findsOneWidget);
      expect(find.text('Job Worker'), findsOneWidget);
      expect(
        find.text(
          'Industry Classification * (Required for Business / Company)',
        ),
        findsOneWidget,
      );
      expect(find.text('1. Core Industry *'), findsOneWidget);

      // Attempt Continue without entering required company name and capability
      final Finder continueButton = find.byKey(
        const Key('profileDetailsContinueButton'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your company/business name'),
        findsOneWidget,
      );
      expect(
        find.text('Please select at least one business type'),
        findsOneWidget,
      );

      // Enter company name and select capability
      await tester.ensureVisible(find.byKey(const Key('companyNameField')));
      await tester.enterText(
        find.byKey(const Key('companyNameField')),
        'Apex Technologies',
      );
      await tester.ensureVisible(find.text('Manufacturer'));
      await tester.tap(find.text('Manufacturer'));
      await tester.pumpAndSettle();

      // Tap Continue -> Should stay on screen and show honest industry requirement error
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Industry classification is required for Business profiles. Please complete all 4 levels',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Employee / Job Seeker form validates and saves profile details to draft',
    (WidgetTester tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Sneha Rao',
            mobileNumber: '9123456780',
            email: 'sneha@example.com',
            profileType: ProfileType.employeeJobSeeker,
          ),
          onContainerAvailable: (ProviderContainer c) => container = c,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Professional Experience'), findsOneWidget);
      expect(find.text('Current Profession / Job Title *'), findsOneWidget);
      expect(find.text('Skills (Optional)'), findsOneWidget);
      expect(find.text('Experience (Optional)'), findsOneWidget);
      expect(find.text('Preferred Job Type (Optional)'), findsOneWidget);

      // Validate required field
      final Finder continueButton = find.byKey(
        const Key('profileDetailsContinueButton'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your profession or job title'),
        findsOneWidget,
      );

      // Fill valid data
      await tester.ensureVisible(find.byKey(const Key('jobTitleField')));
      await tester.enterText(
        find.byKey(const Key('jobTitleField')),
        'Lead QA Automation Engineer',
      );
      await tester.enterText(
        find.byKey(const Key('skillsField')),
        'Flutter, CI/CD, Dart',
      );
      await tester.enterText(
        find.byKey(const Key('experienceField')),
        '5 years',
      );
      await tester.enterText(
        find.byKey(const Key('jobTypeField')),
        'Full-Time',
      );

      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verify Step 3 Placeholder reached
      expect(find.text('Profile Details Saved to Draft'), findsOneWidget);
      expect(find.text('Registration - Step 3'), findsOneWidget);
      expect(find.text('Sneha Rao'), findsOneWidget);
      expect(find.text('Lead QA Automation Engineer'), findsOneWidget);

      // Verify draft preservation
      final RegistrationDraft draft = container.read(registrationDraftProvider);
      expect(draft.fullName, 'Sneha Rao');
      expect(draft.employeeDetails?.jobTitle, 'Lead QA Automation Engineer');
      expect(draft.employeeDetails?.skills, 'Flutter, CI/CD, Dart');
    },
  );

  testWidgets(
    'Service Engineer form displays specialization and equipment fields',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Karan Patel',
            mobileNumber: '9823456789',
            email: 'karan@service.com',
            profileType: ProfileType.serviceEngineer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineering Specialization'), findsOneWidget);
      expect(find.text('Technical Specialization *'), findsOneWidget);
      expect(
        find.text('Supported Machines / Equipment (Optional)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Trader / Supplier form displays trading name and capability fields',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Deepak Shah',
            mobileNumber: '9811223344',
            email: 'deepak@metals.com',
            profileType: ProfileType.traderSupplier,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trade & Supply Profile'), findsOneWidget);
      expect(find.text('Business / Trading Name *'), findsOneWidget);
      expect(
        find.text('Supplier Type / Capabilities * (Select all that apply)'),
        findsOneWidget,
      );
      expect(
        find.text('Products / Materials Supplied (Optional)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Contractor / Job Worker form renders job work capabilities and industry dependency',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Ramesh Varma',
            mobileNumber: '9765432100',
            email: 'ramesh@works.com',
            profileType: ProfileType.contractorJobWorker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Job Work & Contractor Profile'), findsOneWidget);
      expect(find.text('Business / Work Name *'), findsOneWidget);
      expect(
        find.text('Work Type / Capability * (Select all that apply)'),
        findsOneWidget,
      );
      expect(find.text('Machining'), findsOneWidget);
      expect(find.text('Fabrication'), findsOneWidget);
      expect(
        find.text(
          'Industry Classification * (Required for Contractor / Job Worker)',
        ),
        findsOneWidget,
      );
      expect(find.text('1. Core Industry *'), findsOneWidget);
    },
  );

  testWidgets(
    'ProfileDetailsScreen renders cleanly without overflow on mobile and desktop viewports',
    (WidgetTester tester) async {
      // 1. Mobile viewport
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Test User',
            mobileNumber: '9876543210',
            email: 'test@example.com',
            profileType: ProfileType.businessCompany,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company / Business Name *'), findsOneWidget);

      // 2. Desktop viewport
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        createTestApp(
          initialDraft: const RegistrationDraft(
            fullName: 'Test User',
            mobileNumber: '9876543210',
            email: 'test@example.com',
            profileType: ProfileType.businessCompany,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company / Business Name *'), findsOneWidget);
    },
  );
}
