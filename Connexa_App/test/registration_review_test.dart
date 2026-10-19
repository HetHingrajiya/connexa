import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/presentation/phone_verification_placeholder_screen.dart';
import 'package:connexa/features/registration/presentation/profile_details_screen.dart';
import 'package:connexa/features/registration/presentation/registration_review_screen.dart';
import 'package:connexa/features/registration/presentation/registration_screen.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';

Widget createReviewTestApp({
  required RegistrationDraft initialDraft,
  String initialLocation = '/registration/review',
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
        path: '/registration/profile-details',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileDetailsScreen(),
      ),
      GoRoute(
        path: '/registration/review',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationReviewScreen(),
      ),
      GoRoute(
        path: '/registration/phone-verification',
        builder: (BuildContext context, GoRouterState state) =>
            const PhoneVerificationPlaceholderScreen(),
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
          routerConfig: testRouter,
          theme: AppTheme.lightTheme,
        );
      },
    ),
  );
}

void main() {
  group('CONNEXA STEP 8 — Registration Review Screen Tests', () {
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

    testWidgets(
      'Displays actual draft basic details and Business / Company profile fields',
      (WidgetTester tester) async {
        final RegistrationDraft draft = RegistrationDraft(
          fullName: 'Aarav Patel',
          countryCode: '+91',
          mobileNumber: '9876543210',
          email: 'aarav@apexind.com',
          profileType: ProfileType.businessCompany,
          businessDetails: BusinessProfileDetails(
            companyName: 'Apex Industrial Solutions Pvt Ltd',
            businessCapabilities: <BusinessCapability>{
              BusinessCapability.manufacturer,
              BusinessCapability.supplier,
            },
            businessDescription:
                'Leading manufacturer of high-pressure compressors.',
            industrySelection: sampleIndustrySelection,
          ),
        );

        await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
        await tester.pumpAndSettle();

        // Header and Step Indicator
        expect(find.text('Review Your Registration'), findsOneWidget);
        expect(
          find.text('Step 3 of the registration process — Review & Confirm'),
          findsOneWidget,
        );

        // Basic Details
        expect(find.text('Aarav Patel'), findsOneWidget);
        expect(find.text('+91 9876543210'), findsOneWidget);
        expect(find.text('aarav@apexind.com'), findsOneWidget);
        expect(find.text('Business / Company'), findsWidgets);

        // Business Profile Details
        expect(find.text('Apex Industrial Solutions Pvt Ltd'), findsOneWidget);
        expect(find.text('Manufacturer, Supplier'), findsOneWidget);
        expect(
          find.text('Leading manufacturer of high-pressure compressors.'),
          findsOneWidget,
        );

        // 4-Tier Industry Hierarchy Path & Real IDs
        expect(find.text('Manufacturing & Heavy Engineering'), findsOneWidget);
        expect(find.text('[ID: 4]'), findsOneWidget);
        expect(find.text('Machinery & Equipment'), findsOneWidget);
        expect(find.text('[ID: 3]'), findsOneWidget);
        expect(find.text('Industrial Machinery'), findsOneWidget);
        expect(find.text('[ID: 5]'), findsOneWidget);
        expect(find.text('Air Compressors & Vacuum Systems'), findsOneWidget);
        expect(find.text('[ID: 13]'), findsOneWidget);
        expect(find.text('4 TIERS COMPLETE'), findsOneWidget);

        // Edit Actions present
        expect(find.byKey(const Key('editBasicDetailsButton')), findsOneWidget);
        expect(
          find.byKey(const Key('editProfileDetailsButton')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Displays Employee / Job Seeker profile fields', (
      WidgetTester tester,
    ) async {
      final RegistrationDraft draft = const RegistrationDraft(
        fullName: 'Pooja Sharma',
        countryCode: '+91',
        mobileNumber: '9123456789',
        email: 'pooja.sharma@example.com',
        profileType: ProfileType.employeeJobSeeker,
        employeeDetails: EmployeeProfileDetails(
          jobTitle: 'Senior Mechanical Design Engineer',
          skills: 'SolidWorks, AutoCAD, GD&T, FEA',
          experience: '7 years in tooling & fixture design',
          preferredJobType: 'Full-Time / Hybrid',
        ),
      );

      await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Pooja Sharma'), findsOneWidget);
      expect(find.text('Senior Mechanical Design Engineer'), findsOneWidget);
      expect(find.text('SolidWorks, AutoCAD, GD&T, FEA'), findsOneWidget);
      expect(find.text('7 years in tooling & fixture design'), findsOneWidget);
      expect(find.text('Full-Time / Hybrid'), findsOneWidget);
      // Ensure other profile specific cards are not rendered
      expect(find.text('Technical Specialization'), findsNothing);
    });

    testWidgets('Displays Service Engineer profile fields', (
      WidgetTester tester,
    ) async {
      final RegistrationDraft draft = const RegistrationDraft(
        fullName: 'Ramesh Verma',
        countryCode: '+91',
        mobileNumber: '9811223344',
        email: 'ramesh.verma@techservice.in',
        profileType: ProfileType.serviceEngineer,
        serviceEngineerDetails: ServiceEngineerProfileDetails(
          specialization: 'CNC Controller Calibration & Spindle Repair',
          supportedEquipment: 'Fanuc, Siemens Sinumerik, Haas VMC',
          yearsOfExperience: '10 years',
          serviceCoverage: 'North India & Gujarat Industrial Corridors',
        ),
      );

      await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Verma'), findsOneWidget);
      expect(
        find.text('CNC Controller Calibration & Spindle Repair'),
        findsOneWidget,
      );
      expect(find.text('Fanuc, Siemens Sinumerik, Haas VMC'), findsOneWidget);
      expect(find.text('10 years'), findsOneWidget);
      expect(
        find.text('North India & Gujarat Industrial Corridors'),
        findsOneWidget,
      );
    });

    testWidgets('Displays Trader / Supplier profile fields', (
      WidgetTester tester,
    ) async {
      final RegistrationDraft draft = const RegistrationDraft(
        fullName: 'Vikram Mehta',
        countryCode: '+91',
        mobileNumber: '9845012345',
        email: 'vikram@mehtasteels.com',
        profileType: ProfileType.traderSupplier,
        traderDetails: TraderProfileDetails(
          tradingName: 'Mehta Steels & Fasteners Corp',
          capabilities: <BusinessCapability>{
            BusinessCapability.trader,
            BusinessCapability.distributor,
          },
          productsSupplied: 'SS 304/316 Rods, High-Tensile Bolts, Flanges',
          serviceCoverage: 'Pan-India',
        ),
      );

      await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Mehta Steels & Fasteners Corp'), findsOneWidget);
      expect(find.text('Trader, Distributor'), findsOneWidget);
      expect(
        find.text('SS 304/316 Rods, High-Tensile Bolts, Flanges'),
        findsOneWidget,
      );
      expect(find.text('Pan-India'), findsOneWidget);
    });

    testWidgets(
      'Displays Contractor / Job Worker profile fields and 4-tier hierarchy',
      (WidgetTester tester) async {
        final RegistrationDraft draft = RegistrationDraft(
          fullName: 'Sanjay Prajapati',
          countryCode: '+91',
          mobileNumber: '9988776655',
          email: 'sanjay@omprecision.in',
          profileType: ProfileType.contractorJobWorker,
          contractorDetails: ContractorProfileDetails(
            workName: 'Om Precision Job Works',
            workCapabilities: const <String>{
              'Machining',
              'Fabrication',
              'Assembly',
            },
            processesSupported:
                '4-Axis VMC Milling, Lathe Turn-Mill, TIG Welding',
            workCoverage: 'Sanand & Vatva GIDC zones',
            industrySelection: sampleIndustrySelection,
          ),
        );

        await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
        await tester.pumpAndSettle();

        expect(find.text('Sanjay Prajapati'), findsOneWidget);
        expect(find.text('Om Precision Job Works'), findsOneWidget);
        expect(find.text('Machining, Fabrication, Assembly'), findsOneWidget);
        expect(
          find.text('4-Axis VMC Milling, Lathe Turn-Mill, TIG Welding'),
          findsOneWidget,
        );
        expect(find.text('Sanand & Vatva GIDC zones'), findsOneWidget);
        expect(find.text('[ID: 4]'), findsOneWidget);
      },
    );

    testWidgets('Handles missing draft gracefully with recovery view', (
      WidgetTester tester,
    ) async {
      const RegistrationDraft emptyDraft = RegistrationDraft();

      await tester.pumpWidget(createReviewTestApp(initialDraft: emptyDraft));
      await tester.pumpAndSettle();

      expect(find.text('No Registration Draft Found'), findsOneWidget);
      expect(find.byKey(const Key('returnToStep1Button')), findsOneWidget);
    });

    testWidgets(
      'Consent is initially unchecked and required; invalid form does not navigate',
      (WidgetTester tester) async {
        final RegistrationDraft draft = RegistrationDraft(
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

        await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
        await tester.pumpAndSettle();

        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        expect(consentCheckbox, findsOneWidget);
        final Checkbox checkboxWidget = tester.widget<Checkbox>(
          consentCheckbox,
        );
        expect(checkboxWidget.value, isFalse);

        // Try to continue without checking consent
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Remains on review screen and displays consent error
        expect(find.text('Review Your Registration'), findsOneWidget);
        expect(
          find.text('You must confirm your details and agree to continue'),
          findsOneWidget,
        );
        expect(find.text('Phone Verification Pending'), findsNothing);
      },
    );

    testWidgets(
      'Valid draft and consent navigates to PhoneVerificationPlaceholderScreen',
      (WidgetTester tester) async {
        final RegistrationDraft draft = RegistrationDraft(
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

        await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
        await tester.pumpAndSettle();

        // Check consent checkbox
        final Finder consentCheckbox = find.byKey(const Key('consentCheckbox'));
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        // Tap continue
        final Finder continueBtn = find.byKey(
          const Key('continueToVerificationButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Navigates to PhoneVerificationPlaceholderScreen
        expect(find.text('Phone Verification Pending'), findsOneWidget);
        expect(
          find.text(
            'Step 4 — Phone verification and SMS OTP service are not yet implemented.',
          ),
          findsOneWidget,
        );
        expect(find.text('+91 9876543210'), findsOneWidget);
        expect(
          find.text('Development Notice: Verification Incomplete'),
          findsOneWidget,
        );
        expect(
          find.textContaining('No SMS or OTP has been sent'),
          findsOneWidget,
        );
        expect(
          find.textContaining('No user account has been created'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Edit navigation returns to Basic Details and preserves draft values',
      (WidgetTester tester) async {
        ProviderContainer? capturedContainer;

        final RegistrationDraft draft = RegistrationDraft(
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

        await tester.pumpWidget(
          createReviewTestApp(
            initialDraft: draft,
            onContainerAvailable: (ProviderContainer c) =>
                capturedContainer = c,
          ),
        );
        await tester.pumpAndSettle();

        // Tap Edit Basic Details
        final Finder editBasicBtn = find.byKey(
          const Key('editBasicDetailsButton'),
        );
        await tester.ensureVisible(editBasicBtn);
        await tester.tap(editBasicBtn);
        await tester.pumpAndSettle();

        // Reached RegistrationScreen
        expect(find.text('Create Your Connexa Account'), findsOneWidget);
        expect(find.text('Aarav Patel'), findsOneWidget);
        expect(find.text('9876543210'), findsOneWidget);
        expect(find.text('aarav@apexind.com'), findsOneWidget);

        // Edit the name
        final Finder nameField = find.byKey(const Key('fullNameField'));
        await tester.enterText(nameField, 'Aarav Kumar Patel');

        // Tap Continue in RegistrationScreen
        final Finder continueBtn = find.byKey(const Key('continueButton'));
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Navigates to ProfileDetailsScreen while preserving business details
        expect(find.text('Business & Company Details'), findsOneWidget);
        final RegistrationDraft updatedDraft = capturedContainer!.read(
          registrationDraftProvider,
        );
        expect(updatedDraft.fullName, 'Aarav Kumar Patel');
        expect(
          updatedDraft.businessDetails?.companyName,
          'Apex Industrial Solutions Pvt Ltd',
        );
      },
    );

    testWidgets(
      'Mobile (360x640) and Desktop (1280x800) layouts do not overflow',
      (WidgetTester tester) async {
        final RegistrationDraft draft = RegistrationDraft(
          fullName: 'Aarav Patel',
          countryCode: '+91',
          mobileNumber: '9876543210',
          email: 'aarav@apexind.com',
          profileType: ProfileType.businessCompany,
          businessDetails: BusinessProfileDetails(
            companyName: 'Apex Industrial Solutions Pvt Ltd',
            businessCapabilities: <BusinessCapability>{
              BusinessCapability.manufacturer,
              BusinessCapability.supplier,
            },
            businessDescription:
                'Leading manufacturer of high-pressure compressors.',
            industrySelection: sampleIndustrySelection,
          ),
        );

        // Test Mobile
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Review Your Registration'), findsOneWidget);

        // Test Desktop
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createReviewTestApp(initialDraft: draft));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Review Your Registration'), findsOneWidget);
      },
    );
  });
}
