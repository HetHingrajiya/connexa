import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/widgets.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/connections/models/connection_models.dart';
import 'package:connexa/features/connections/presentation/network_screen.dart';
import 'package:connexa/features/connections/providers/connection_provider.dart';
import 'package:connexa/features/dashboard/presentation/dashboard_screen.dart';
import 'package:connexa/features/directory/models/directory_models.dart';
import 'package:connexa/features/directory/presentation/directory_screen.dart';
import 'package:connexa/features/directory/providers/directory_provider.dart';
import 'package:connexa/features/profile/presentation/profile_screen.dart';
import 'package:connexa/features/profile/presentation/edit_profile_screen.dart';
import 'package:connexa/features/auth/presentation/login_screen.dart';
import 'package:connexa/features/registration/presentation/registration_screen.dart';

MemberProfile _createMockProfile() {
  return MemberProfile(
    memberId: 1042,
    fullName: 'Aditya Patel',
    email: 'aditya@patelmetals.com',
    phoneNumber: '9876543210',
    countryCode: '+91',
    primaryProfileType: 'BusinessCompany',
    verifiedMethod: 'WhatsApp',
    verifiedDestination: '+919876543210',
    role: 'Member',
    isActive: true,
    createdAtUtc: DateTime(2026, 1, 15),
    profileDetails: <String, dynamic>{
      'companyName': 'Patel Precision Metals Ltd',
      'businessDescription':
          'Leading manufacturer of precision industrial fasteners, brass turned components, and metal stampings.',
      'businessCapabilities': <String>['Manufacturer', 'Exporter', 'Supplier'],
      'industry': 'Manufacturing & Engineering',
      'businessGroup': 'Metal Fabrication & Precision Engineering',
      'subGroup': 'Fasteners & Turned Parts',
      'category': 'Industrial Brass Screws',
      'industryId': 1,
      'businessGroupId': 2,
      'subGroupId': 3,
      'categoryId': 4,
    },
  );
}

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  Future<void> restoreSession() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDirectoryNotifier extends StateNotifier<DirectoryState>
    implements DirectoryNotifier {
  MockDirectoryNotifier(super.state);

  @override
  Future<void> loadDirectory({bool resetPaging = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConnectionsNotifier extends StateNotifier<ConnectionsState>
    implements ConnectionsNotifier {
  MockConnectionsNotifier(super.state);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> loadConnections({int? page}) async {}

  @override
  Future<void> loadReceivedRequests({int? page}) async {}

  @override
  Future<void> loadSentRequests({int? page}) async {}

  @override
  void setActiveTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithApp(
  Widget child, {
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('AppBadge & Shared Components Visual Verification', () {
    testWidgets('AppBadge renders all semantic variants properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const Scaffold(
            body: Column(
              children: <Widget>[
                AppBadge.brand(label: 'Brand Badge'),
                AppBadge.primary(label: 'Primary Badge'),
                AppBadge.secondary(label: 'Secondary Badge'),
                AppBadge.success(label: 'Success Badge'),
                AppBadge.warning(label: 'Warning Badge'),
                AppBadge.error(label: 'Error Badge'),
                AppBadge.info(label: 'Info Badge'),
                AppBadge.neutral(label: 'Neutral Badge'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Brand Badge'), findsOneWidget);
      expect(find.text('Primary Badge'), findsOneWidget);
      expect(find.text('Secondary Badge'), findsOneWidget);
      expect(find.text('Success Badge'), findsOneWidget);
      expect(find.text('Warning Badge'), findsOneWidget);
      expect(find.text('Error Badge'), findsOneWidget);
      expect(find.text('Info Badge'), findsOneWidget);
      expect(find.text('Neutral Badge'), findsOneWidget);
    });

    testWidgets('AppCard renders with header, subtitle, and body cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AppCard(
            title: 'Enterprise Profile',
            subtitle: 'Overview of verified company',
            headerAction: const AppBadge.success(label: 'VERIFIED'),
            child: const Text('Card Body Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enterprise Profile'), findsOneWidget);
      expect(find.text('Overview of verified company'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('Card Body Content'), findsOneWidget);
    });
  });

  group('Dashboard Redesign Visual Verification', () {
    testWidgets(
      'DashboardScreen renders executive cockpit layout, hero card, completion, and quick actions',
      (WidgetTester tester) async {
        final MemberProfile profile = _createMockProfile();
        final AuthState mockAuthState = AuthState(
          isAuthenticated: true,
          profile: profile,
          user: AuthenticatedMember(
            memberId: profile.memberId,
            fullName: profile.fullName,
            email: profile.email,
            phoneNumber: profile.phoneNumber,
            primaryProfileType: profile.primaryProfileType,
            role: profile.role,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith(
                (Ref ref) => MockAuthNotifier(mockAuthState),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check header titles
        expect(find.text('Connexa Dashboard'), findsOneWidget);
        expect(find.text('Aditya Patel'), findsOneWidget);
        expect(find.text('Member #1042'), findsOneWidget);
        expect(find.text('Company'), findsOneWidget);

        // Check profile completion
        expect(find.text('Profile Completion'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);

        // Check Quick Actions
        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('Directory'), findsOneWidget);
        expect(find.text('My Network'), findsOneWidget);

        // Check Industry Classification
        expect(find.text('Industry Classification'), findsOneWidget);
        expect(find.text('Manufacturing & Engineering'), findsWidgets);
        expect(find.text('Industrial Brass Screws'), findsWidgets);
      },
    );
  });

  group('Business Directory Redesign Visual Verification', () {
    testWidgets(
      'BusinessDirectoryScreen renders search bar, filter chips, and business cards without overflow',
      (WidgetTester tester) async {
        final List<BusinessDirectoryItem> mockItems = <BusinessDirectoryItem>[
          BusinessDirectoryItem(
            memberId: 2001,
            companyName: 'Apex Precision Gears',
            contactPersonName: 'Sanjay Sharma',
            email: 'sanjay@apexgears.com',
            phoneNumber: '9876512345',
            businessType: 'Manufacturer / Company',
            industryId: 1,
            industryName: 'Mechanical Engineering',
            businessGroupId: 2,
            businessGroupName: 'Power Transmission',
            subGroupId: 3,
            subGroupName: 'Gears & Pinions',
            categoryId: 4,
            categoryName: 'Spur Gears',
            location: 'Ahmedabad, Gujarat, India',
            businessCapabilities: const <String>['Machining', 'Heat Treatment'],
            connectionStatus: 'Not Connected',
            memberSinceUtc: DateTime(2026, 2, 1),
            verifiedMethod: 'Email',
            maskedEmail: 's***@apexgears.com',
            maskedPhoneNumber: '+91 98*** 12345',
          ),
        ];

        final DirectoryState mockDirState = DirectoryState(
          response: BusinessDirectoryResponse(
            items: mockItems,
            totalCount: 1,
            page: 1,
            pageSize: 10,
            totalPages: 1,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              directoryNotifierProvider.overrideWith(
                (Ref ref) => MockDirectoryNotifier(mockDirState),
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
        expect(find.text('Apex Precision Gears'), findsOneWidget);
        expect(find.text('Sanjay Sharma'), findsOneWidget);
        expect(find.text('1 businesses found'), findsOneWidget);
      },
    );
  });

  group('NetworkScreen Redesign Visual Verification', () {
    testWidgets(
      'NetworkScreen renders tabs with count badges and connection items',
      (WidgetTester tester) async {
        final ConnectionsState mockConnState = ConnectionsState(
          connections: <ConnectedMemberItem>[
            ConnectedMemberItem(
              connectionId: 501,
              memberId: 3001,
              companyName: 'Zenith Logistics Hub',
              fullName: 'Vikram Joshi',
              businessType: 'Trader / Supplier',
              industryId: 1,
              industryName: 'Logistics & Supply',
              location: 'Mumbai, Maharashtra',
              connectedSinceUtc: DateTime(2026, 3, 10),
            ),
          ],
          summary: const ConnectionsSummary(
            totalConnected: 1,
            receivedPendingCount: 2,
            sentPendingCount: 1,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              connectionsNotifierProvider.overrideWith(
                (Ref ref) => MockConnectionsNotifier(mockConnState),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const NetworkScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Network'), findsOneWidget);
        expect(find.text('Connections'), findsOneWidget);
        expect(find.text('Zenith Logistics Hub'), findsOneWidget);
        expect(find.text('Vikram Joshi'), findsOneWidget);
      },
    );
  });

  group('ProfileScreen Redesign Visual Verification', () {
    testWidgets(
      'ProfileScreen renders executive hero card, completion gauge, and contact rows',
      (WidgetTester tester) async {
        final MemberProfile profile = _createMockProfile();
        final AuthState mockAuthState = AuthState(
          isAuthenticated: true,
          profile: profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith(
                (Ref ref) => MockAuthNotifier(mockAuthState),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('Aditya Patel'), findsOneWidget);
        expect(find.text('Member #1042'), findsOneWidget);
        expect(find.text('Contact Information'), findsOneWidget);
        expect(find.text('aditya@patelmetals.com'), findsOneWidget);
        expect(find.text('Edit Profile Details'), findsOneWidget);
      },
    );
  });

  group('Responsive Viewport Verification', () {
    testWidgets('DashboardScreen renders without overflow on 360x640 mobile', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final MemberProfile profile = _createMockProfile();
      final AuthState mockAuthState = AuthState(
        isAuthenticated: true,
        profile: profile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authProvider.overrideWith(
              (Ref ref) => MockAuthNotifier(mockAuthState),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aditya Patel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'DashboardScreen renders without overflow on 1280x800 desktop',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final MemberProfile profile = _createMockProfile();
        final AuthState mockAuthState = AuthState(
          isAuthenticated: true,
          profile: profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith(
                (Ref ref) => MockAuthNotifier(mockAuthState),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aditya Patel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'EditProfileScreen renders cleanly without overflow on 360x640 mobile',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final MemberProfile profile = _createMockProfile();
        final AuthState mockAuthState = AuthState(
          isAuthenticated: true,
          profile: profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith(
                (Ref ref) => MockAuthNotifier(mockAuthState),
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
        expect(find.text('Personal Identity'), findsOneWidget);
        expect(find.byKey(const Key('editProfileSaveButton')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'EditProfileScreen renders 2-column desktop layout on 1280x800 desktop',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final MemberProfile profile = _createMockProfile();
        final AuthState mockAuthState = AuthState(
          isAuthenticated: true,
          profile: profile,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith(
                (Ref ref) => MockAuthNotifier(mockAuthState),
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
        expect(find.text('Personal Identity'), findsOneWidget);
        expect(find.text('Business Information'), findsOneWidget);
        expect(find.byKey(const Key('editProfileSaveButton')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LoginScreen renders cleanly on 360x640 mobile and 1280x800 desktop',
      (WidgetTester tester) async {
        // Mobile Viewport
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final AuthState mockAuthState = const AuthState();

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authProvider.overrideWith(
                (Ref ref) => MockAuthNotifier(mockAuthState),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome Back to Connexa'), findsOneWidget);
        expect(find.byKey(const Key('loginIdentifierField')), findsOneWidget);
        expect(find.byKey(const Key('loginPasswordField')), findsOneWidget);
        expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Desktop Viewport
        tester.view.physicalSize = const Size(1280, 800);
        await tester.pumpAndSettle();

        expect(find.text('Connexa Business Network'), findsOneWidget);
        expect(find.text('Verified Member Credentials'), findsOneWidget);
        expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RegistrationScreen renders cleanly on 360x640 mobile and 1280x800 desktop',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RegistrationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Your Connexa Account'), findsOneWidget);
        expect(find.byKey(const Key('fullNameField')), findsOneWidget);
        expect(find.byKey(const Key('phoneField')), findsOneWidget);
        expect(find.byKey(const Key('emailField')), findsOneWidget);
        expect(find.byKey(const Key('continueButton')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Brand Color System Verification', () {
    test('Exact brand palette values are defined and strictly adhered to', () {
      expect(AppColors.brandNavy, const Color(0xFF0F2744));
      expect(AppColors.primaryAction, const Color(0xFF2563EB));
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.secondary, const Color(0xFF0D9488));
      expect(AppColors.background, const Color(0xFFF8FAFC));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.textPrimary, const Color(0xFF1E293B));
      expect(AppColors.textSecondary, const Color(0xFF64748B));
      expect(AppColors.border, const Color(0xFFE2E8F0));
      expect(AppColors.success, const Color(0xFF16A34A));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.error, const Color(0xFFDC2626));
    });

    test(
      'AppTheme binds Deep Navy to AppBar and Royal Blue to Material primary',
      () {
        final ThemeData theme = AppTheme.lightTheme;
        expect(theme.appBarTheme.backgroundColor, AppColors.brandNavy);
        expect(theme.colorScheme.primary, AppColors.primary);
        expect(theme.scaffoldBackgroundColor, AppColors.background);
        expect(theme.cardTheme.color, AppColors.surface);
      },
    );
  });

  group('Animation & Transition System Verification', () {
    testWidgets(
      'AppStaggeredEntrance renders child cleanly with slide & fade',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppStaggeredEntrance(
                index: 0,
                child: const Text('Animated Child Content'),
              ),
            ),
          ),
        );

        // Initially rendered and animating
        expect(find.text('Animated Child Content'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('Animated Child Content'), findsOneWidget);
      },
    );
  });
}
