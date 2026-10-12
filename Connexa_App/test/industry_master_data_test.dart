import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/errors/app_exceptions.dart';
import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/core/theme/app_theme.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/presentation/profile_details_screen.dart';
import 'package:connexa/features/registration/presentation/registration_screen.dart';
import 'package:connexa/features/registration/presentation/registration_step_3_placeholder_screen.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/services/industry_master_data_service.dart';

/// In-memory mock adapter for deterministic HTTP test responses.
class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(String jsonString, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonString,
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

Dio createMockDio(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.connexa.test',
      connectTimeout: const Duration(seconds: 5),
    ),
  );
  dio.httpClientAdapter = MockHttpClientAdapter(handler);
  return dio;
}

Widget createTestAppWithOverrides({
  required RegistrationDraft initialDraft,
  required Dio dio,
  void Function(ProviderContainer)? onContainerAvailable,
}) {
  final GoRouter testRouter = GoRouter(
    initialLocation: '/registration/profile-details',
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
        path: '/registration/step-3-placeholder',
        builder: (BuildContext context, GoRouterState state) =>
            const RegistrationStep3PlaceholderScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      registrationDraftProvider.overrideWith((Ref ref) => initialDraft),
      dioProvider.overrideWithValue(dio),
    ],
    child: Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        if (onContainerAvailable != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onContainerAvailable(
              ProviderScope.containerOf(context, listen: false),
            );
          });
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
  group('IndustryMasterDataService Unit Tests', () {
    test('getIndustries parses successful list envelope', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        expect(options.path, '/api/v1/master/industries');
        return jsonResponse('''
          {
            "data": [
              {"id": "ind_101", "name": "Automotive & Mobility", "code": "AUTO"},
              {"id": "ind_102", "name": "Heavy Engineering", "code": "ENGG"}
            ]
          }
        ''');
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      final List<Industry> list = await service.getIndustries();

      expect(list.length, 2);
      expect(list[0].id, 'ind_101');
      expect(list[0].name, 'Automotive & Mobility');
      expect(list[0].code, 'AUTO');
      expect(list[1].id, 'ind_102');
    });

    test('getBusinessGroups parses nested groups by industryId', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        expect(
          options.path,
          '/api/v1/master/industries/ind_101/business-groups',
        );
        return jsonResponse('''
          [
            {"id": "bg_201", "industryId": "ind_101", "name": "OEM Components"},
            {"id": "bg_202", "industryId": "ind_101", "name": "Aftermarket Spares"}
          ]
        ''');
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      final List<BusinessGroup> groups = await service.getBusinessGroups(
        'ind_101',
      );

      expect(groups.length, 2);
      expect(groups[0].id, 'bg_201');
      expect(groups[0].name, 'OEM Components');
      expect(groups[0].industryId, 'ind_101');
    });

    test('getSubGroups parses sub-groups by businessGroupId', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        expect(
          options.path,
          '/api/v1/master/business-groups/bg_201/sub-groups',
        );
        return jsonResponse('''
          {
            "data": [
              {"id": "sg_301", "businessGroupId": "bg_201", "name": "Powertrain & Engine Parts"}
            ]
          }
        ''');
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      final List<SubGroup> subGroups = await service.getSubGroups('bg_201');

      expect(subGroups.length, 1);
      expect(subGroups[0].id, 'sg_301');
      expect(subGroups[0].name, 'Powertrain & Engine Parts');
      expect(subGroups[0].businessGroupId, 'bg_201');
    });

    test('getCategories parses categories by subGroupId', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        expect(options.path, '/api/v1/master/sub-groups/sg_301/categories');
        return jsonResponse('''
          {
            "data": [
              {"id": "cat_401", "subGroupId": "sg_301", "name": "Piston Rings & Cylinders"}
            ]
          }
        ''');
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      final List<Category> categories = await service.getCategories('sg_301');

      expect(categories.length, 1);
      expect(categories[0].id, 'cat_401');
      expect(categories[0].name, 'Piston Rings & Cylinders');
      expect(categories[0].subGroupId, 'sg_301');
    });

    test('Empty responses return empty lists without crashing', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        return jsonResponse('{"data": []}');
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      final List<Industry> list = await service.getIndustries();
      expect(list, isEmpty);
    });

    test('API 500 error throws ApiException with server details', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        return jsonResponse(
          '{"message": "Database unavailable"}',
          statusCode: 500,
        );
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      expect(() => service.getIndustries(), throwsA(isA<ApiException>()));
    });

    test('Malformed payload throws DataParsingException', () async {
      final Dio dio = createMockDio((RequestOptions options) async {
        return jsonResponse('{"data": "invalid string not a list"}');
      });

      final IndustryMasterDataService service = IndustryMasterDataService(dio);
      expect(
        () => service.getIndustries(),
        throwsA(isA<DataParsingException>()),
      );
    });
  });

  group('IndustryHierarchyNotifier Cascading State Tests', () {
    test('Cascading reset clears child selections when ancestor changes', () {
      final IndustryHierarchyNotifier notifier = IndustryHierarchyNotifier();

      const Industry ind1 = Industry(id: '1', name: 'Tech');
      const BusinessGroup bg1 = BusinessGroup(
        id: '10',
        industryId: '1',
        name: 'Software',
      );
      const SubGroup sg1 = SubGroup(
        id: '100',
        businessGroupId: '10',
        name: 'Mobile',
      );
      const Category cat1 = Category(
        id: '1000',
        subGroupId: '100',
        name: 'Flutter Dev',
      );

      notifier.selectIndustry(ind1);
      notifier.selectBusinessGroup(bg1);
      notifier.selectSubGroup(sg1);
      notifier.selectCategory(cat1);

      expect(notifier.state.isComplete, isTrue);
      expect(notifier.state.toSelection()?.industryId, '1');
      expect(notifier.state.toSelection()?.categoryId, '1000');

      // Change Business Group -> SubGroup and Category should be cleared!
      const BusinessGroup bg2 = BusinessGroup(
        id: '20',
        industryId: '1',
        name: 'Hardware',
      );
      notifier.selectBusinessGroup(bg2);

      expect(notifier.state.selectedBusinessGroup?.id, '20');
      expect(notifier.state.selectedSubGroup, isNull);
      expect(notifier.state.selectedCategory, isNull);
      expect(notifier.state.isComplete, isFalse);

      // Change Industry -> Everything below resets!
      const Industry ind2 = Industry(id: '2', name: 'Healthcare');
      notifier.selectIndustry(ind2);

      expect(notifier.state.selectedIndustry?.id, '2');
      expect(notifier.state.selectedBusinessGroup, isNull);
      expect(notifier.state.selectedSubGroup, isNull);
      expect(notifier.state.selectedCategory, isNull);
    });
  });

  group('Widget & Integration Tests for Industry Hierarchy', () {
    testWidgets(
      'IndustryHierarchySelector displays API error and Retry button when backend is offline',
      (WidgetTester tester) async {
        final Dio failingDio = createMockDio((RequestOptions options) async {
          return jsonResponse('Server offline', statusCode: 503);
        });

        await tester.pumpWidget(
          createTestAppWithOverrides(
            initialDraft: const RegistrationDraft(
              fullName: 'Aarav Mehta',
              mobileNumber: '9876543210',
              email: 'aarav@apex.com',
              profileType: ProfileType.businessCompany,
            ),
            dio: failingDio,
          ),
        );
        await tester.pumpAndSettle();

        // Level 1 should show error state
        expect(find.text('1. Core Industry *'), findsOneWidget);
        expect(find.text('Master data unavailable'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Lower tiers remain disabled
        expect(find.text('2. Business Group *'), findsOneWidget);
        expect(find.text('Select an industry first'), findsOneWidget);

        // Attempt submit -> blocked with validation error
        final Finder continueBtn = find.byKey(
          const Key('profileDetailsContinueButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('industryValidationErrorBanner')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Successful 4-tier selection saves real database IDs into draft and navigates to Step 3',
      (WidgetTester tester) async {
        late ProviderContainer container;

        final Dio workingDio = createMockDio((RequestOptions options) async {
          if (options.path.contains('/industries') &&
              !options.path.contains('/business-groups')) {
            return jsonResponse('''
              [{"id": "ind_auto", "name": "Automotive Engineering"}]
            ''');
          }
          if (options.path.contains('/business-groups') &&
              !options.path.contains('/sub-groups')) {
            return jsonResponse('''
              [{"id": "bg_oem", "industryId": "ind_auto", "name": "Component Manufacturing"}]
            ''');
          }
          if (options.path.contains('/sub-groups') &&
              !options.path.contains('/categories')) {
            return jsonResponse('''
              [{"id": "sg_chassis", "businessGroupId": "bg_oem", "name": "Chassis & Suspension"}]
            ''');
          }
          if (options.path.contains('/categories')) {
            return jsonResponse('''
              [{"id": "cat_bushings", "subGroupId": "sg_chassis", "name": "Heavy Duty Bushings"}]
            ''');
          }
          return jsonResponse('[]', statusCode: 404);
        });

        await tester.pumpWidget(
          createTestAppWithOverrides(
            initialDraft: const RegistrationDraft(
              fullName: 'Aarav Mehta',
              mobileNumber: '9876543210',
              email: 'aarav@apex.com',
              profileType: ProfileType.businessCompany,
            ),
            dio: workingDio,
            onContainerAvailable: (ProviderContainer c) => container = c,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Fill company name and business capability
        await tester.ensureVisible(find.byKey(const Key('companyNameField')));
        await tester.enterText(
          find.byKey(const Key('companyNameField')),
          'Apex Precision Wheels Ltd.',
        );
        await tester.ensureVisible(find.text('Manufacturer'));
        await tester.tap(find.text('Manufacturer'));
        await tester.pumpAndSettle();

        // 2. Select Level 1: Industry
        await tester.ensureVisible(find.byKey(const Key('industryDropdown')));
        await tester.tap(find.byKey(const Key('industryDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Automotive Engineering').last);
        await tester.pumpAndSettle();

        // 3. Select Level 2: Business Group
        await tester.ensureVisible(
          find.byKey(const Key('businessGroupDropdown')),
        );
        await tester.tap(find.byKey(const Key('businessGroupDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Component Manufacturing').last);
        await tester.pumpAndSettle();

        // 4. Select Level 3: SubGroup
        await tester.ensureVisible(find.byKey(const Key('subGroupDropdown')));
        await tester.tap(find.byKey(const Key('subGroupDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chassis & Suspension').last);
        await tester.pumpAndSettle();

        // 5. Select Level 4: Category
        await tester.ensureVisible(find.byKey(const Key('categoryDropdown')));
        await tester.tap(find.byKey(const Key('categoryDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Heavy Duty Bushings').last);
        await tester.pumpAndSettle();

        // Hierarchy display path banner should now be visible
        expect(
          find.textContaining(
            'Classification Path: Automotive Engineering > Component Manufacturing > Chassis & Suspension > Heavy Duty Bushings',
          ),
          findsOneWidget,
        );

        // 6. Submit form
        final Finder continueBtn = find.byKey(
          const Key('profileDetailsContinueButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Verify navigation to Step 3 Placeholder
        expect(find.text('Registration - Step 3'), findsOneWidget);
        expect(find.text('Apex Precision Wheels Ltd.'), findsOneWidget);

        // Verify draft state in Riverpod
        final RegistrationDraft draft = container.read(
          registrationDraftProvider,
        );
        expect(
          draft.businessDetails?.companyName,
          'Apex Precision Wheels Ltd.',
        );
        expect(
          draft.businessDetails?.industrySelection?.industryId,
          'ind_auto',
        );
        expect(
          draft.businessDetails?.industrySelection?.businessGroupId,
          'bg_oem',
        );
        expect(
          draft.businessDetails?.industrySelection?.subGroupId,
          'sg_chassis',
        );
        expect(
          draft.businessDetails?.industrySelection?.categoryId,
          'cat_bushings',
        );
        expect(draft.businessDetails?.industrySelection?.isComplete, isTrue);
      },
    );

    testWidgets(
      'Contractor / Job Worker form enforces 4-tier industry master data and saves IDs',
      (WidgetTester tester) async {
        late ProviderContainer container;

        final Dio workingDio = createMockDio((RequestOptions options) async {
          if (options.path.contains('/industries') &&
              !options.path.contains('/business-groups')) {
            return jsonResponse('''
              [{"id": "ind_met", "name": "Metals & Fabrication"}]
            ''');
          }
          if (options.path.contains('/business-groups') &&
              !options.path.contains('/sub-groups')) {
            return jsonResponse('''
              [{"id": "bg_jobwork", "industryId": "ind_met", "name": "Contract Job Work"}]
            ''');
          }
          if (options.path.contains('/sub-groups') &&
              !options.path.contains('/categories')) {
            return jsonResponse('''
              [{"id": "sg_cnc", "businessGroupId": "bg_jobwork", "name": "Precision CNC Milling"}]
            ''');
          }
          if (options.path.contains('/categories')) {
            return jsonResponse('''
              [{"id": "cat_5axis", "subGroupId": "sg_cnc", "name": "5-Axis Machine Center"}]
            ''');
          }
          return jsonResponse('[]', statusCode: 404);
        });

        await tester.pumpWidget(
          createTestAppWithOverrides(
            initialDraft: const RegistrationDraft(
              fullName: 'Ramesh Varma',
              mobileNumber: '9765432100',
              email: 'ramesh@works.com',
              profileType: ProfileType.contractorJobWorker,
            ),
            dio: workingDio,
            onContainerAvailable: (ProviderContainer c) => container = c,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Fill work name and work capability
        await tester.ensureVisible(find.byKey(const Key('workNameField')));
        await tester.enterText(
          find.byKey(const Key('workNameField')),
          'Varma CNC Job Works',
        );
        await tester.ensureVisible(find.text('Machining'));
        await tester.tap(find.text('Machining'));
        await tester.pumpAndSettle();

        // 2. Select 4 tiers
        await tester.ensureVisible(find.byKey(const Key('industryDropdown')));
        await tester.tap(find.byKey(const Key('industryDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Metals & Fabrication').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('businessGroupDropdown')),
        );
        await tester.tap(find.byKey(const Key('businessGroupDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Contract Job Work').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('subGroupDropdown')));
        await tester.tap(find.byKey(const Key('subGroupDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Precision CNC Milling').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('categoryDropdown')));
        await tester.tap(find.byKey(const Key('categoryDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5-Axis Machine Center').last);
        await tester.pumpAndSettle();

        // 3. Submit
        final Finder continueBtn = find.byKey(
          const Key('profileDetailsContinueButton'),
        );
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(find.text('Registration - Step 3'), findsOneWidget);
        expect(find.text('Varma CNC Job Works'), findsOneWidget);

        final RegistrationDraft draft = container.read(
          registrationDraftProvider,
        );
        expect(
          draft.contractorDetails?.industrySelection?.categoryId,
          'cat_5axis',
        );
        expect(
          draft.contractorDetails?.industrySelection?.displayPath,
          'Metals & Fabrication > Contract Job Work > Precision CNC Milling > 5-Axis Machine Center',
        );
      },
    );
  });
}
