import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/network/auth_interceptor.dart';
import 'package:connexa/core/storage/auth_storage.dart';
import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/presentation/login_screen.dart';
import 'package:connexa/features/auth/presentation/setup_password_screen.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/auth/services/auth_service.dart';
import 'package:connexa/features/dashboard/presentation/dashboard_screen.dart';

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

ResponseBody jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// Fake implementation of AuthService for testing UI states.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.shouldSucceed = true,
    this.customErrorMessage,
    this.memberProfile,
  });

  final bool shouldSucceed;
  final String? customErrorMessage;
  final MemberProfile? memberProfile;

  int loginCallCount = 0;
  int setupPasswordCallCount = 0;
  int logoutCallCount = 0;
  int getMeCallCount = 0;

  @override
  Future<AuthResponse> login(String identifier, String password) async {
    loginCallCount++;
    if (!shouldSucceed) {
      throw AuthException(
        customErrorMessage ?? 'Invalid identifier or password.',
        statusCode: 401,
      );
    }
    return const AuthResponse(
      accessToken: 'fake-access-token-jwt-12345',
      refreshToken: 'fake-refresh-token-xyz6789',
      tokenType: 'Bearer',
      expiresIn: 900,
      member: AuthenticatedMember(
        memberId: 6,
        fullName: 'Het Patel',
        email: 'hetpatel8517@gmail.com',
        phoneNumber: '+917069267376',
        role: 'Member',
        primaryProfileType: 'Business / Company',
      ),
    );
  }

  @override
  Future<AuthResponse> setupPassword({
    String? credentialSetupToken,
    String? verificationGrant,
    String? destination,
    required String password,
    required String confirmPassword,
  }) async {
    setupPasswordCallCount++;
    if (!shouldSucceed) {
      throw AuthException(
        customErrorMessage ?? 'Invalid or expired setup token.',
        statusCode: 400,
      );
    }
    return const AuthResponse(
      accessToken: 'fake-access-token-jwt-setup-123',
      refreshToken: 'fake-refresh-token-setup-456',
      tokenType: 'Bearer',
      expiresIn: 900,
      member: AuthenticatedMember(
        memberId: 6,
        fullName: 'Het Patel',
        email: 'hetpatel8517@gmail.com',
        phoneNumber: '+917069267376',
        role: 'Member',
        primaryProfileType: 'Business / Company',
      ),
    );
  }

  @override
  Future<MemberProfile> getMe() async {
    getMeCallCount++;
    if (!shouldSucceed) {
      throw AuthException(
        customErrorMessage ?? 'Session expired.',
        statusCode: 401,
      );
    }
    return memberProfile ??
        MemberProfile(
          memberId: 6,
          fullName: 'Het Patel',
          countryCode: '+91',
          phoneNumber: '7069267376',
          email: 'hetpatel8517@gmail.com',
          primaryProfileType: 'Business / Company',
          verifiedMethod: 'whatsapp',
          verifiedDestination: '+917069267376',
          role: 'Member',
          isActive: true,
          createdAtUtc: DateTime.utc(2026, 10, 19, 10, 0, 0),
          profileDetails: const <String, dynamic>{
            'companyName': 'Connexa Enterprise Solutions',
          },
        );
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  int requestSetupOtpCallCount = 0;
  int verifySetupOtpCallCount = 0;

  @override
  Future<RequestSetupOtpResult> requestSetupOtp({
    required String identifier,
    required String channel,
  }) async {
    requestSetupOtpCallCount++;
    if (!shouldSucceed) {
      throw AuthException(
        customErrorMessage ?? 'No registered account found.',
        statusCode: 404,
      );
    }
    return const RequestSetupOtpResult(
      challengeId: 101,
      destination: 'hetpatel8517@gmail.com',
      maskedDestination: 'h***@gmail.com',
      channel: 'Email',
      flowId: 'setup_flow_12345',
      message: 'Verification code sent.',
    );
  }

  @override
  Future<VerifySetupOtpResult> verifySetupOtp({
    required int challengeId,
    required String flowId,
    required String otpCode,
    required String channel,
  }) async {
    verifySetupOtpCallCount++;
    if (!shouldSucceed) {
      throw AuthException(
        customErrorMessage ?? 'Invalid verification code.',
        statusCode: 400,
      );
    }
    return VerifySetupOtpResult(
      credentialSetupToken:
          'fresh-mock-credential-setup-token-1234567890abcdef1234567890abcdef',
      expiresAtUtc: DateTime.now().add(const Duration(minutes: 30)),
      destination: 'hetpatel8517@gmail.com',
      message: 'Verification successful.',
    );
  }

  int updateProfileCallCount = 0;

  @override
  Future<MemberProfile> updateProfile(Map<String, dynamic> updateData) async {
    updateProfileCallCount++;
    if (!shouldSucceed) {
      throw AuthException(
        customErrorMessage ?? 'Profile update failed.',
        statusCode: 400,
      );
    }
    return memberProfile ??
        MemberProfile(
          memberId: 6,
          fullName: updateData['fullName']?.toString() ?? 'Het Patel',
          countryCode: '+91',
          phoneNumber: '7069267376',
          email: 'hetpatel8517@gmail.com',
          primaryProfileType: 'Business / Company',
          verifiedMethod: 'whatsapp',
          verifiedDestination: '+917069267376',
          role: 'Member',
          isActive: true,
          createdAtUtc: DateTime.utc(2026, 10, 19, 10, 0, 0),
          profileDetails: const <String, dynamic>{
            'companyName': 'Connexa Enterprise Solutions',
          },
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('CONNEXA STEP 14 — Storage & Token Service Unit Tests', () {
    test(
      'AuthStorage caches tokens and retrieves without platform hang',
      () async {
        final AuthStorage storage = AuthStorage(const FlutterSecureStorage());

        await storage.saveTokens(
          accessToken: 'test-access-token-123',
          refreshToken: 'test-refresh-token-456',
          memberId: 6,
          memberName: 'Het Patel',
          memberEmail: 'hetpatel8517@gmail.com',
        );

        expect(storage.cachedAccessToken, 'test-access-token-123');
        expect(storage.cachedRefreshToken, 'test-refresh-token-456');

        final String? token = await storage.getAccessToken();
        expect(token, 'test-access-token-123');

        final bool hasToken = await storage.hasToken();
        expect(hasToken, isTrue);

        await storage.clear();
        expect(storage.cachedAccessToken, isNull);
        expect(storage.cachedRefreshToken, isNull);
      },
    );

    test(
      'AuthResponse and MemberProfile JSON deserialization matches server contract',
      () {
        final Map<String, dynamic> authJson = <String, dynamic>{
          'accessToken': 'sample-jwt-token',
          'refreshToken': 'sample-refresh-token',
          'tokenType': 'Bearer',
          'expiresIn': 900,
          'member': <String, dynamic>{
            'memberId': 6,
            'fullName': 'Het Patel',
            'email': 'hetpatel8517@gmail.com',
            'phoneNumber': '+917069267376',
            'role': 'Member',
            'primaryProfileType': 'Business / Company',
          },
        };

        final AuthResponse response = AuthResponse.fromJson(authJson);
        expect(response.accessToken, 'sample-jwt-token');
        expect(response.refreshToken, 'sample-refresh-token');
        expect(response.expiresIn, 900);
        expect(response.member.memberId, 6);
        expect(response.member.fullName, 'Het Patel');
        expect(response.member.role, 'Member');

        final Map<String, dynamic> profileJson = <String, dynamic>{
          'memberId': 6,
          'fullName': 'Het Patel',
          'countryCode': '+91',
          'phoneNumber': '7069267376',
          'email': 'hetpatel8517@gmail.com',
          'primaryProfileType': 'Business / Company',
          'verifiedMethod': 'whatsapp',
          'verifiedDestination': '+917069267376',
          'role': 'Member',
          'isActive': true,
          'createdAtUtc': '2026-10-19T10:00:00Z',
          'profileDetails': <String, dynamic>{
            'companyName': 'Connexa Enterprise Solutions',
          },
        };

        final MemberProfile profile = MemberProfile.fromJson(profileJson);
        expect(profile.memberId, 6);
        expect(profile.fullName, 'Het Patel');
        expect(profile.role, 'Member');
        expect(profile.isActive, isTrue);
        expect(
          profile.profileDetails?['companyName'],
          'Connexa Enterprise Solutions',
        );
      },
    );
  });

  group('CONNEXA STEP 14 — AuthInterceptor Network Tests', () {
    test(
      'AuthInterceptor injects Bearer token on protected endpoints',
      () async {
        final AuthStorage storage = AuthStorage(const FlutterSecureStorage());
        await storage.saveTokens(
          accessToken: 'valid-test-bearer-token',
          refreshToken: 'valid-test-refresh-token',
        );

        final Dio dio = Dio(BaseOptions(baseUrl: 'http://test'));
        dio.interceptors.add(AuthInterceptor(authStorage: storage, dio: dio));

        RequestOptions? interceptedOptions;
        dio.httpClientAdapter = MockHttpClientAdapter((
          RequestOptions options,
        ) async {
          interceptedOptions = options;
          return jsonResponse(<String, dynamic>{
            'success': true,
            'data': <String, dynamic>{},
          });
        });

        await dio.get('/api/v1/members/me');

        expect(interceptedOptions, isNotNull);
        expect(
          interceptedOptions!.headers['Authorization'],
          'Bearer valid-test-bearer-token',
        );
      },
    );

    test(
      'AuthInterceptor does NOT inject token on public login or setup endpoints',
      () async {
        final AuthStorage storage = AuthStorage(const FlutterSecureStorage());
        await storage.saveTokens(
          accessToken: 'valid-test-bearer-token',
          refreshToken: 'valid-test-refresh-token',
        );

        final Dio dio = Dio(BaseOptions(baseUrl: 'http://test'));
        dio.interceptors.add(AuthInterceptor(authStorage: storage, dio: dio));

        RequestOptions? loginOptions;
        dio.httpClientAdapter = MockHttpClientAdapter((
          RequestOptions options,
        ) async {
          loginOptions = options;
          return jsonResponse(<String, dynamic>{
            'success': true,
            'data': <String, dynamic>{},
          });
        });

        await dio.post(
          '/api/v1/auth/login',
          data: <String, dynamic>{'identifier': 'test', 'password': 'pass'},
        );

        expect(loginOptions, isNotNull);
        expect(loginOptions!.headers.containsKey('Authorization'), isFalse);
      },
    );
  });

  group('CONNEXA STEP 14 — LoginScreen UI & State Tests', () {
    testWidgets(
      'LoginScreen renders fields, validates inputs, and triggers submit',
      (WidgetTester tester) async {
        final FakeAuthService fakeAuth = FakeAuthService();
        final AuthStorage fakeStorage = AuthStorage(
          const FlutterSecureStorage(),
        );

        final GoRouter router = GoRouter(
          initialLocation: '/login',
          routes: <RouteBase>[
            GoRoute(
              path: '/login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Dashboard Loaded')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authServiceProvider.overrideWithValue(fakeAuth),
              authStorageProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome Back to Connexa'), findsOneWidget);
        expect(find.byKey(const Key('loginIdentifierField')), findsOneWidget);
        expect(find.byKey(const Key('loginPasswordField')), findsOneWidget);
        expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

        // Attempt empty submission -> field validation
        await tester.tap(find.byKey(const Key('loginSubmitButton')));
        await tester.pumpAndSettle();

        expect(find.text('Email or phone number is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        expect(fakeAuth.loginCallCount, 0);

        // Enter valid credentials
        await tester.enterText(
          find.byKey(const Key('loginIdentifierField')),
          'hetpatel8517@gmail.com',
        );
        await tester.enterText(
          find.byKey(const Key('loginPasswordField')),
          'SecurePass123!',
        );
        await tester.pumpAndSettle();

        // Submit form
        await tester.tap(find.byKey(const Key('loginSubmitButton')));
        await tester.pumpAndSettle();

        expect(fakeAuth.loginCallCount, 1);
        expect(find.text('Dashboard Loaded'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen renders error banner on invalid login credentials',
      (WidgetTester tester) async {
        final FakeAuthService fakeAuth = FakeAuthService(
          shouldSucceed: false,
          customErrorMessage:
              'Invalid credentials. 4 attempts remaining before lockout.',
        );
        final AuthStorage fakeStorage = AuthStorage(
          const FlutterSecureStorage(),
        );

        final GoRouter router = GoRouter(
          initialLocation: '/login',
          routes: <RouteBase>[
            GoRoute(
              path: '/login',
              builder: (BuildContext context, GoRouterState state) =>
                  const LoginScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authServiceProvider.overrideWithValue(fakeAuth),
              authStorageProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('loginIdentifierField')),
          'wrong@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('loginPasswordField')),
          'WrongPass123!',
        );
        await tester.tap(find.byKey(const Key('loginSubmitButton')));
        await tester.pumpAndSettle();

        expect(fakeAuth.loginCallCount, 1);
        expect(find.byKey(const Key('loginErrorMessage')), findsOneWidget);
        expect(
          find.text(
            'Invalid credentials. 4 attempts remaining before lockout.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('CONNEXA STEP 14 — SetupPasswordScreen & DashboardScreen UI Tests', () {
    testWidgets(
      'SetupPasswordScreen enforces policy and submits password setup',
      (WidgetTester tester) async {
        final FakeAuthService fakeAuth = FakeAuthService();
        final AuthStorage fakeStorage = AuthStorage(
          const FlutterSecureStorage(),
        );

        final GoRouter router = GoRouter(
          initialLocation: '/setup-password',
          routes: <RouteBase>[
            GoRoute(
              path: '/setup-password',
              builder: (BuildContext context, GoRouterState state) =>
                  const SetupPasswordScreen(
                    initialCredentialSetupToken:
                        'valid-64-character-credential-setup-token-abc1234567890',
                  ),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Dashboard Loaded')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authServiceProvider.overrideWithValue(fakeAuth),
              authStorageProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Your Password'), findsOneWidget);
        expect(find.text('Password Requirements'), findsOneWidget);

        // Enter weak password
        final Finder submitBtn = find.byKey(
          const Key('setupPasswordSubmitButton'),
        );
        await tester.enterText(
          find.byKey(const Key('setupPasswordField')),
          'short',
        );
        await tester.enterText(
          find.byKey(const Key('setupConfirmPasswordField')),
          'short',
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Password does not satisfy security policy'),
          findsOneWidget,
        );
        expect(fakeAuth.setupPasswordCallCount, 0);

        // Enter valid policy-compliant password
        await tester.enterText(
          find.byKey(const Key('setupPasswordField')),
          'SecureConnexa2026!',
        );
        await tester.enterText(
          find.byKey(const Key('setupConfirmPasswordField')),
          'SecureConnexa2026!',
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(fakeAuth.setupPasswordCallCount, 1);
        expect(find.text('Dashboard Loaded'), findsOneWidget);
      },
    );

    testWidgets(
      'SetupPasswordScreen without initial token renders account recovery and unlocks password setup after OTP verification',
      (WidgetTester tester) async {
        final FakeAuthService fakeAuth = FakeAuthService();
        final AuthStorage fakeStorage = AuthStorage(
          const FlutterSecureStorage(),
        );

        final GoRouter router = GoRouter(
          initialLocation: '/setup-password',
          routes: <RouteBase>[
            GoRoute(
              path: '/setup-password',
              builder: (BuildContext context, GoRouterState state) =>
                  const SetupPasswordScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Dashboard Loaded After OTP')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authServiceProvider.overrideWithValue(fakeAuth),
              authStorageProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify user is NOT asked to enter a raw 64-character token manually
        expect(find.byKey(const Key('setupTokenField')), findsNothing);
        expect(find.text('Verify Your Registered Account'), findsOneWidget);
        expect(find.byKey(const Key('setupRecoveryCard')), findsOneWidget);
        expect(find.byKey(const Key('setupIdentifierField')), findsOneWidget);

        // 2. Request OTP
        await tester.enterText(
          find.byKey(const Key('setupIdentifierField')),
          'hetpatel8517@gmail.com',
        );
        final Finder reqBtn = find.byKey(const Key('requestSetupOtpButton'));
        await tester.ensureVisible(reqBtn);
        await tester.tap(reqBtn);
        await tester.pumpAndSettle();

        expect(fakeAuth.requestSetupOtpCallCount, 1);
        expect(find.byKey(const Key('setupOtpCodeField')), findsOneWidget);
        expect(find.byKey(const Key('verifySetupOtpButton')), findsOneWidget);

        // 3. Enter 6-digit OTP and verify
        await tester.enterText(
          find.byKey(const Key('setupOtpCodeField')),
          '123456',
        );
        final Finder verifyBtn = find.byKey(const Key('verifySetupOtpButton'));
        await tester.ensureVisible(verifyBtn);
        await tester.tap(verifyBtn);
        await tester.pumpAndSettle();

        expect(fakeAuth.verifySetupOtpCallCount, 1);

        // 4. Form should now transition to password creation
        expect(find.text('Create Your Password'), findsOneWidget);
        expect(find.byKey(const Key('setupPasswordField')), findsOneWidget);

        // 5. Enter strong password and submit
        await tester.enterText(
          find.byKey(const Key('setupPasswordField')),
          'SecureConnexa2026!',
        );
        await tester.enterText(
          find.byKey(const Key('setupConfirmPasswordField')),
          'SecureConnexa2026!',
        );

        final Finder submitBtn = find.byKey(
          const Key('setupPasswordSubmitButton'),
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(fakeAuth.setupPasswordCallCount, 1);
        expect(find.text('Dashboard Loaded After OTP'), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardScreen renders authentic profile information and handles logout',
      (WidgetTester tester) async {
        final FakeAuthService fakeAuth = FakeAuthService();
        final AuthStorage fakeStorage = AuthStorage(
          const FlutterSecureStorage(),
        );
        await fakeStorage.saveTokens(
          accessToken: 'valid-test-access-token',
          refreshToken: 'valid-test-refresh-token',
        );

        final GoRouter router = GoRouter(
          initialLocation: '/dashboard',
          routes: <RouteBase>[
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Login Screen Loaded')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              authServiceProvider.overrideWithValue(fakeAuth),
              authStorageProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert profile card details
        expect(find.byKey(const Key('dashboardMemberName')), findsOneWidget);
        expect(find.text('Het Patel'), findsOneWidget);
        expect(find.byKey(const Key('dashboardMemberId')), findsOneWidget);
        expect(find.text('Member #6'), findsOneWidget);
        expect(find.text('BUSINESS / COMPANY'), findsOneWidget);

        // Assert security details
        expect(find.text('Active (Strict Member Role)'), findsOneWidget);
        expect(
          find.text('Short-lived JWT (15 min) with Refresh Token Rotation'),
          findsOneWidget,
        );

        // Tap Logout button
        final Finder logoutBtn = find.byKey(const Key('dashboardLogoutButton'));
        await tester.tap(logoutBtn);
        await tester.pumpAndSettle();

        // Assert confirmation dialog
        expect(find.text('Confirm Logout'), findsOneWidget);
        expect(find.text('Log Out'), findsOneWidget);

        // Confirm logout
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();

        expect(fakeAuth.logoutCallCount, 1);
        expect(find.text('Login Screen Loaded'), findsOneWidget);
      },
    );
  });

  group('CONNEXA STEP 14 — Session Restoration & Protected Route Tests', () {
    test(
      'Session restoration with stored token fetches profile and authenticates session',
      () async {
        final FakeAuthService fakeAuth = FakeAuthService();
        final AuthStorage storage = AuthStorage(const FlutterSecureStorage());
        await storage.saveTokens(
          accessToken: 'initial-stored-access-token',
          refreshToken: 'initial-stored-refresh-token',
        );

        final AuthNotifier notifier = AuthNotifier(fakeAuth, storage);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.isAuthenticated, isTrue);
        expect(notifier.state.user?.memberId, 6);
        expect(notifier.state.user?.fullName, 'Het Patel');
        expect(notifier.state.profile?.verifiedMethod, 'whatsapp');
        expect(fakeAuth.getMeCallCount, 1);
      },
    );

    test(
      'Session restoration with invalid token clears storage and remains unauthenticated',
      () async {
        final FakeAuthService fakeAuth = FakeAuthService(
          shouldSucceed: false,
          customErrorMessage: 'Session expired.',
        );
        final AuthStorage storage = AuthStorage(const FlutterSecureStorage());
        await storage.saveTokens(
          accessToken: 'expired-access-token',
          refreshToken: 'expired-refresh-token',
        );

        final AuthNotifier notifier = AuthNotifier(fakeAuth, storage);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.isAuthenticated, isFalse);
        expect(notifier.state.user, isNull);
        expect(await storage.hasToken(), isFalse);
      },
    );

    testWidgets(
      'Protected route redirect sends unauthenticated visitors to /login',
      (WidgetTester tester) async {
        final FakeAuthService fakeAuth = FakeAuthService();
        final AuthStorage storage = AuthStorage(const FlutterSecureStorage());
        await storage.clear();

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            authServiceProvider.overrideWithValue(fakeAuth),
            authStorageProvider.overrideWithValue(storage),
          ],
        );
        addTearDown(container.dispose);

        // Force initial unauthenticated state
        container.read(authProvider.notifier).state = const AuthState(
          isAuthenticated: false,
          isRestoringSession: false,
        );

        final GoRouter router = GoRouter(
          initialLocation: '/dashboard',
          redirect: (BuildContext context, GoRouterState state) {
            final AuthState auth = container.read(authProvider);
            if (!auth.isAuthenticated &&
                state.matchedLocation == '/dashboard') {
              return '/login';
            }
            return null;
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/login',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Login Screen')),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const Scaffold(body: Text('Dashboard Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Login Screen'), findsOneWidget);
        expect(find.text('Dashboard Screen'), findsNothing);
      },
    );
  });
}
