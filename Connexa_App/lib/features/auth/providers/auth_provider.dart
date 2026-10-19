import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/storage/auth_storage.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/services/auth_service.dart';

/// State representation for authentication and user session.
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isRestoringSession = false,
    this.user,
    this.profile,
    this.errorMessage,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final bool isRestoringSession;
  final AuthenticatedMember? user;
  final MemberProfile? profile;
  final String? errorMessage;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isRestoringSession,
    AuthenticatedMember? user,
    MemberProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// State notifier managing login, password setup, session restoration, and logout.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService, this._authStorage)
    : super(const AuthState(isRestoringSession: false)) {
    restoreSession();
  }

  final AuthService _authService;
  final AuthStorage _authStorage;

  /// Restores persistent user session on application launch.
  Future<void> restoreSession() async {
    state = state.copyWith(isRestoringSession: true);

    try {
      final bool hasToken = await _authStorage.hasToken();
      if (!hasToken) {
        state = state.copyWith(
          isAuthenticated: false,
          isRestoringSession: false,
        );
        return;
      }

      // Fetch authentic member profile using stored token
      final MemberProfile profile = await _authService.getMe();

      state = state.copyWith(
        isAuthenticated: true,
        isRestoringSession: false,
        profile: profile,
        user: AuthenticatedMember(
          memberId: profile.memberId,
          fullName: profile.fullName,
          email: profile.email,
          phoneNumber: profile.phoneNumber,
          role: profile.role,
          primaryProfileType: profile.primaryProfileType,
        ),
      );
    } catch (_) {
      // Invalidation or network error: gracefully fall back to unauthenticated
      await _authStorage.clear();
      state = state.copyWith(isAuthenticated: false, isRestoringSession: false);
    }
  }

  /// Executes member login with identifier and password.
  Future<bool> login(String identifier, String password) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final AuthResponse response = await _authService.login(
        identifier,
        password,
      );

      // Fetch full profile details
      MemberProfile? profile;
      try {
        profile = await _authService.getMe();
      } catch (_) {
        // Fallback to basic details if me endpoint encounters network glitch
      }

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response.member,
        profile: profile,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'An unexpected error occurred during login. Please retry.',
      );
      return false;
    }
  }

  /// Executes password setup for newly registered or verified member.
  Future<bool> setupPassword({
    String? credentialSetupToken,
    String? verificationGrant,
    String? destination,
    required String password,
    required String confirmPassword,
  }) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final AuthResponse response = await _authService.setupPassword(
        credentialSetupToken: credentialSetupToken,
        verificationGrant: verificationGrant,
        destination: destination,
        password: password,
        confirmPassword: confirmPassword,
      );

      MemberProfile? profile;
      try {
        profile = await _authService.getMe();
      } catch (_) {}

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response.member,
        profile: profile,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during password setup.',
      );
      return false;
    }
  }

  /// Updates current authenticated member profile and refreshes local state.
  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final MemberProfile updated = await _authService.updateProfile(
        updateData,
      );
      state = state.copyWith(
        isLoading: false,
        profile: updated,
        user: AuthenticatedMember(
          memberId: updated.memberId,
          fullName: updated.fullName,
          email: updated.email,
          phoneNumber: updated.phoneNumber,
          role: updated.role,
          primaryProfileType: updated.primaryProfileType,
        ),
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while updating profile.',
      );
      return false;
    }
  }

  /// Refreshes current member profile from /api/v1/members/me.
  Future<void> refreshProfile() async {
    try {
      final MemberProfile profile = await _authService.getMe();
      state = state.copyWith(
        profile: profile,
        user: AuthenticatedMember(
          memberId: profile.memberId,
          fullName: profile.fullName,
          email: profile.email,
          phoneNumber: profile.phoneNumber,
          role: profile.role,
          primaryProfileType: profile.primaryProfileType,
        ),
      );
    } catch (_) {}
  }

  /// Terminates active session and clears tokens.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      isRestoringSession: false,
    );
  }

  /// Clears active error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// Global Riverpod provider exposing authentication state.
final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((Ref ref) {
      final AuthService authService = ref.watch(authServiceProvider);
      final AuthStorage authStorage = ref.watch(authStorageProvider);
      return AuthNotifier(authService, authStorage);
    });

/// In-memory holder for an authorized credential setup token across navigation flows.
class SetupTokenData {
  const SetupTokenData({required this.token, this.destination, this.expiresAt});

  final String token;
  final String? destination;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!);
}

/// Global provider storing pending setup token so it is not lost across screens or router transitions.
final StateProvider<SetupTokenData?> pendingSetupTokenProvider =
    StateProvider<SetupTokenData?>((Ref ref) => null);
