import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/core/routing/app_router.dart';
import 'package:connexa/core/storage/auth_storage.dart';
import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/auth/services/auth_service.dart';
import 'package:connexa/features/dashboard/presentation/dashboard_screen.dart';
import 'package:connexa/features/directory/models/directory_models.dart';
import 'package:connexa/features/directory/presentation/directory_screen.dart';
import 'package:connexa/features/directory/services/directory_service.dart';
import 'package:connexa/features/profile/presentation/edit_profile_screen.dart';
import 'package:connexa/features/profile/presentation/profile_screen.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/providers/industry_master_data_providers.dart';
import 'package:go_router/go_router.dart';

class FakeTestAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTestAuthNotifier extends AuthNotifier {
  FakeTestAuthNotifier(AuthState initialState)
    : super(FakeTestAuthService(), AuthStorage(const FlutterSecureStorage())) {
    state = initialState;
  }
}

class FakeDirectoryService implements DirectoryService {
  FakeDirectoryService({this.items = const <BusinessDirectoryItem>[]});

  final List<BusinessDirectoryItem> items;

  @override
  Future<BusinessDirectoryResponse> searchBusinesses(
    BusinessDirectoryFilter filter, {
    dynamic cancelToken,
  }) async {
    List<BusinessDirectoryItem> filtered = items;
    if (filter.search != null && filter.search!.isNotEmpty) {
      filtered = filtered
          .where(
            (BusinessDirectoryItem i) =>
                i.companyName.toLowerCase().contains(
                  filter.search!.toLowerCase(),
                ) ||
                i.contactPersonName.toLowerCase().contains(
                  filter.search!.toLowerCase(),
                ),
          )
          .toList();
    }
    if (filter.industryId != null) {
      filtered = filtered
          .where((BusinessDirectoryItem i) => i.industryId == filter.industryId)
          .toList();
    }
    return BusinessDirectoryResponse(
      items: filtered,
      totalCount: filtered.length,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: (filtered.length / filter.pageSize).ceil().clamp(1, 999),
    );
  }

  @override
  Future<BusinessDirectoryItem?> getBusinessById(
    int memberId, {
    dynamic cancelToken,
  }) async {
    try {
      return items.firstWhere(
        (BusinessDirectoryItem i) => i.memberId == memberId,
      );
    } catch (_) {
      return null;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  final MemberProfile mockMember6Profile = MemberProfile(
    memberId: 6,
    fullName: 'Het Patel',
    countryCode: '+91',
    phoneNumber: '7069267376',
    email: 'hetpatel8517@gmail.com',
    primaryProfileType: 'BusinessCompany',
    verifiedMethod: 'Email',
    verifiedDestination: 'hetpatel8517@gmail.com',
    role: 'Member',
    isActive: true,
    createdAtUtc: DateTime.utc(2026, 10, 19, 10, 0, 0),
    profileDetails: const <String, dynamic>{
      'companyName': 'mayuri bag',
      'businessCapabilities': <String>['Manufacturer', 'Supplier'],
      'businessDescription': 'Industrial bag manufacturing unit',
      'industryId': 3,
      'industry': 'Electrical, Power & Industrial Electronics',
      'businessGroupId': 4,
      'businessGroup': 'Power Distribution & Switchgear',
      'subGroupId': 5,
      'subGroup': 'Industrial Automation & Controls',
      'categoryId': 17,
      'category': 'Modular PLCs & Remote I/O Units',
    },
  );

  final List<BusinessDirectoryItem> mockDirectoryItems =
      <BusinessDirectoryItem>[
        BusinessDirectoryItem(
          memberId: 6,
          companyName: 'mayuri bag',
          contactPersonName: 'Het Patel',
          email: 'hetpatel8517@gmail.com',
          phoneNumber: '+917069267376',
          businessCapabilities: const <String>['Manufacturer', 'Supplier'],
          businessDescription: 'Industrial bag manufacturing unit',
          industryId: 3,
          industryName: 'Electrical, Power & Industrial Electronics',
          businessGroupId: 4,
          businessGroupName: 'Power Distribution & Switchgear',
          subGroupId: 5,
          subGroupName: 'Industrial Automation & Controls',
          categoryId: 17,
          categoryName: 'Modular PLCs & Remote I/O Units',
          verifiedMethod: 'Email',
          memberSinceUtc: DateTime.utc(2026, 10, 19),
        ),
        BusinessDirectoryItem(
          memberId: 1,
          companyName: 'Precision Dynamics Pvt Ltd',
          contactPersonName: 'Test Persistence Member',
          email: 'test_member_persistence@connexa.com',
          phoneNumber: '+919876500001',
          businessCapabilities: const <String>['Manufacturer', 'Supplier'],
          businessDescription: 'Automotive and precision components',
          industryId: 1,
          industryName: 'Automotive & Mobility Solutions',
          businessGroupId: 1,
          businessGroupName: 'Automotive Components',
          subGroupId: 1,
          subGroupName: 'Engine Systems',
          categoryId: 1,
          categoryName: 'Pistons & Rings',
          verifiedMethod: 'Email',
          memberSinceUtc: DateTime.utc(2026, 10, 15),
        ),
      ];

  group('CONNEXA STEP 16 — DashboardScreen Widget Tests', () {
    testWidgets(
      'DashboardScreen renders Member #6 summary, verification badge, completion and quick actions',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith((Ref ref) {
                return FakeTestAuthNotifier(
                  AuthState(
                    isAuthenticated: true,
                    isLoading: false,
                    profile: mockMember6Profile,
                    user: const AuthenticatedMember(
                      memberId: 6,
                      fullName: 'Het Patel',
                      email: 'hetpatel8517@gmail.com',
                      phoneNumber: '7069267376',
                      role: 'Member',
                      primaryProfileType: 'BusinessCompany',
                    ),
                  ),
                );
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify Member Hero Card
        expect(find.text('Het Patel'), findsWidgets);
        expect(find.byKey(const Key('dashboardMemberId')), findsOneWidget);
        expect(find.text('Member #6'), findsOneWidget);
        expect(find.text('BUSINESSCOMPANY'), findsOneWidget);

        // 2. Verify Verification Channel
        expect(
          find.textContaining('Verified via Email (hetpatel8517@gmail.com)'),
          findsOneWidget,
        );

        // 3. Verify Real Field Profile Completion
        expect(
          find.byKey(const Key('dashboardCompletionPercent')),
          findsOneWidget,
        );
        expect(find.text('100%'), findsOneWidget);

        // 4. Verify 4-Tier Hierarchy Summary
        expect(
          find.text('Electrical, Power & Industrial Electronics'),
          findsWidgets,
        );
        expect(find.text('Modular PLCs & Remote I/O Units'), findsWidgets);

        // 5. Verify Quick Actions
        expect(
          find.byKey(const Key('dashboardQuickActionMyProfile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboardQuickActionEditProfile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboardQuickActionDirectory')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboardQuickActionLogout')),
          findsOneWidget,
        );
      },
    );
  });

  group('CONNEXA STEP 16 — ProfileScreen Widget Tests', () {
    testWidgets(
      'ProfileScreen displays full member credentials and 4-tier hierarchy',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith((Ref ref) {
                return FakeTestAuthNotifier(
                  AuthState(
                    isAuthenticated: true,
                    isLoading: false,
                    profile: mockMember6Profile,
                  ),
                );
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Profile'), findsWidgets);
        expect(find.byKey(const Key('profileFullNameText')), findsOneWidget);
        expect(find.text('Het Patel'), findsWidgets);
        expect(find.byKey(const Key('profileMemberIdBadge')), findsOneWidget);
        expect(find.text('Member #6'), findsOneWidget);
        expect(
          find.byKey(const Key('profileCompletionPercentText')),
          findsOneWidget,
        );
        expect(find.text('100%'), findsOneWidget);
        expect(
          find.byKey(const Key('profileCompanyNameValue')),
          findsOneWidget,
        );
        expect(find.text('mayuri bag'), findsOneWidget);
        expect(find.text('Modular PLCs & Remote I/O Units'), findsWidgets);
        expect(find.byKey(const Key('profileEditButton')), findsOneWidget);
      },
    );
  });

  group('CONNEXA STEP 16 — EditProfileScreen Widget Tests', () {
    testWidgets(
      'EditProfileScreen renders editable fields with prefilled member data',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));

        final List<Industry> mockIndustries = <Industry>[
          const Industry(
            id: 3,
            name: 'Electrical, Power & Industrial Electronics',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith((Ref ref) {
                return FakeTestAuthNotifier(
                  AuthState(
                    isAuthenticated: true,
                    isLoading: false,
                    profile: mockMember6Profile,
                  ),
                );
              }),
              industriesProvider.overrideWith(
                (Ref ref) async => mockIndustries,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const EditProfileScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('Het Patel'), findsOneWidget);
        expect(find.text('mayuri bag'), findsOneWidget);
        expect(find.text('Manufacturer'), findsWidgets);
        expect(find.text('Supplier'), findsWidgets);
        expect(find.byKey(const Key('editProfileSaveButton')), findsOneWidget);
      },
    );
  });

  group('CONNEXA STEP 16 — BusinessDirectoryScreen Widget Tests', () {
    testWidgets(
      'BusinessDirectoryScreen renders search bar, filters, real database items, and count',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              directoryServiceProvider.overrideWithValue(
                FakeDirectoryService(items: mockDirectoryItems),
              ),
              industriesProvider.overrideWith(
                (Ref ref) async => <Industry>[
                  const Industry(
                    id: 3,
                    name: 'Electrical, Power & Industrial Electronics',
                  ),
                  const Industry(
                    id: 1,
                    name: 'Automotive & Mobility Solutions',
                  ),
                ],
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const BusinessDirectoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Business Directory'), findsOneWidget);
        expect(
          find.byKey(const Key('directorySearchTextField')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('directoryResultCountText')),
          findsOneWidget,
        );
        expect(find.text('2 businesses found'), findsOneWidget);

        // Verify business card items
        expect(find.text('mayuri bag'), findsOneWidget);
        expect(find.text('Precision Dynamics Pvt Ltd'), findsOneWidget);
        expect(find.text('Het Patel'), findsOneWidget);
        expect(find.text('Test Persistence Member'), findsOneWidget);
      },
    );

    testWidgets('Search query filters directory results correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            directoryServiceProvider.overrideWithValue(
              FakeDirectoryService(items: mockDirectoryItems),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const BusinessDirectoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('2 businesses found'), findsOneWidget);

      // Enter search text "mayuri"
      await tester.enterText(
        find.byKey(const Key('directorySearchTextField')),
        'mayuri',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('1 businesses found'), findsOneWidget);
      expect(find.text('mayuri bag'), findsOneWidget);
      expect(find.text('Precision Dynamics Pvt Ltd'), findsNothing);
    });
  });
}
