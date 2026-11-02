import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/models/security_models.dart';
import 'package:connexa/features/auth/services/security_service.dart';

// ==========================================
// 1. ACTIVE SESSIONS STATE & NOTIFIER
// ==========================================

@immutable
class ActiveSessionsState {
  const ActiveSessionsState({
    this.sessions = const <ActiveSession>[],
    this.isLoading = false,
    this.isRevoking = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<ActiveSession> sessions;
  final bool isLoading;
  final bool isRevoking;
  final String? errorMessage;
  final String? successMessage;

  ActiveSessionsState copyWith({
    List<ActiveSession>? sessions,
    bool? isLoading,
    bool? isRevoking,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ActiveSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isRevoking: isRevoking ?? this.isRevoking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ActiveSessionsNotifier extends StateNotifier<ActiveSessionsState> {
  ActiveSessionsNotifier(this._securityService)
      : super(const ActiveSessionsState()) {
    loadSessions();
  }

  final SecurityService _securityService;

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final List<ActiveSession> sessions =
          await _securityService.getActiveSessions();
      state = state.copyWith(
        sessions: sessions,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load active sessions.',
      );
    }
  }

  Future<bool> revokeSession(int sessionId) async {
    state = state.copyWith(isRevoking: true, clearError: true, clearSuccess: true);
    try {
      final bool success = await _securityService.revokeSession(sessionId);
      if (success) {
        final List<ActiveSession> updated = state.sessions
            .where((ActiveSession s) => s.id != sessionId)
            .toList();
        state = state.copyWith(
          sessions: updated,
          isRevoking: false,
          successMessage: 'Session revoked successfully.',
        );
        return true;
      }
      state = state.copyWith(
        isRevoking: false,
        errorMessage: 'Unable to revoke session.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isRevoking: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isRevoking: false,
        errorMessage: 'An error occurred while revoking session.',
      );
      return false;
    }
  }

  Future<bool> revokeAllOtherSessions() async {
    state = state.copyWith(isRevoking: true, clearError: true, clearSuccess: true);
    try {
      final bool success = await _securityService.revokeAllOtherSessions();
      if (success) {
        final List<ActiveSession> currentOnly = state.sessions
            .where((ActiveSession s) => s.isCurrent)
            .toList();
        state = state.copyWith(
          sessions: currentOnly,
          isRevoking: false,
          successMessage: 'All other sessions have been signed out.',
        );
        return true;
      }
      state = state.copyWith(
        isRevoking: false,
        errorMessage: 'Failed to revoke other sessions.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isRevoking: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isRevoking: false,
        errorMessage: 'An error occurred while revoking other sessions.',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final AutoDisposeStateNotifierProvider<ActiveSessionsNotifier, ActiveSessionsState>
    activeSessionsProvider = StateNotifierProvider.autoDispose<
        ActiveSessionsNotifier, ActiveSessionsState>((Ref ref) {
  final SecurityService service = ref.watch(securityServiceProvider);
  return ActiveSessionsNotifier(service);
});

// ==========================================
// 2. ACCOUNT SETTINGS & STATUS
// ==========================================

@immutable
class AccountSettingsState {
  const AccountSettingsState({
    this.status,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final AccountStatus? status;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  AccountSettingsState copyWith({
    AccountStatus? status,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AccountSettingsState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AccountSettingsNotifier extends StateNotifier<AccountSettingsState> {
  AccountSettingsNotifier(this._securityService)
      : super(const AccountSettingsState()) {
    loadAccountStatus();
  }

  final SecurityService _securityService;

  Future<void> loadAccountStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final AccountStatus status = await _securityService.getAccountStatus();
      state = state.copyWith(
        status: status,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to retrieve account status.',
      );
    }
  }

  Future<bool> deactivateAccount({
    required String password,
    String? reason,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final bool success = await _securityService.deactivateAccount(
        DeactivateAccountRequest(password: password, reason: reason),
      );
      if (success) {
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Account successfully deactivated.',
        );
        return true;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Unable to deactivate account.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'An unexpected error occurred during deactivation.',
      );
      return false;
    }
  }

  Future<bool> requestAccountDeletion({
    required String password,
    required String reason,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final bool success = await _securityService.requestAccountDeletion(
        DeleteAccountRequest(password: password, reason: reason),
      );
      if (success) {
        state = state.copyWith(
          isSubmitting: false,
          successMessage:
              'Account deletion request submitted. An admin will review your request.',
        );
        await loadAccountStatus();
        return true;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit account deletion request.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'An unexpected error occurred while requesting deletion.',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final AutoDisposeStateNotifierProvider<AccountSettingsNotifier,
        AccountSettingsState> accountSettingsProvider =
    StateNotifierProvider.autoDispose<AccountSettingsNotifier,
        AccountSettingsState>((Ref ref) {
  final SecurityService service = ref.watch(securityServiceProvider);
  return AccountSettingsNotifier(service);
});

// ==========================================
// 3. FORGOT PASSWORD
// ==========================================

@immutable
class ForgotPasswordState {
  const ForgotPasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.response,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final ForgotPasswordResponse? response;
  final String? errorMessage;

  ForgotPasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    ForgotPasswordResponse? response,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      response: response ?? this.response,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier(this._securityService)
      : super(const ForgotPasswordState());

  final SecurityService _securityService;

  Future<ForgotPasswordResponse?> sendResetOtp({
    required String identifier,
    String? preferredChannel,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ForgotPasswordResponse response =
          await _securityService.forgotPassword(
        ForgotPasswordRequest(
          identifier: identifier,
          preferredChannel: preferredChannel,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        response: response,
      );
      return response;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to initiate password reset.',
      );
      return null;
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final AutoDisposeStateNotifierProvider<ForgotPasswordNotifier,
        ForgotPasswordState> forgotPasswordProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordNotifier,
        ForgotPasswordState>((Ref ref) {
  final SecurityService service = ref.watch(securityServiceProvider);
  return ForgotPasswordNotifier(service);
});

// ==========================================
// 4. RESET PASSWORD
// ==========================================

@immutable
class ResetPasswordState {
  const ResetPasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  ResetPasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  ResetPasswordNotifier(this._securityService)
      : super(const ResetPasswordState());

  final SecurityService _securityService;

  Future<bool> resetPassword({
    required String identifier,
    required String otpCode,
    required String flowId,
    required int challengeId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bool success = await _securityService.resetPassword(
        ResetPasswordRequest(
          identifier: identifier,
          otpCode: otpCode,
          flowId: flowId,
          challengeId: challengeId,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: success,
      );
      return success;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset failed. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const ResetPasswordState();
  }
}

final AutoDisposeStateNotifierProvider<ResetPasswordNotifier,
        ResetPasswordState> resetPasswordProvider =
    StateNotifierProvider.autoDispose<ResetPasswordNotifier,
        ResetPasswordState>((Ref ref) {
  final SecurityService service = ref.watch(securityServiceProvider);
  return ResetPasswordNotifier(service);
});

// ==========================================
// 5. CHANGE PASSWORD
// ==========================================

@immutable
class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  ChangePasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  ChangePasswordNotifier(this._securityService)
      : super(const ChangePasswordState());

  final SecurityService _securityService;

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    bool revokeOtherSessions = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bool success = await _securityService.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
          revokeOtherSessions: revokeOtherSessions,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: success,
      );
      return success;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update password.',
      );
      return false;
    }
  }

  void reset() {
    state = const ChangePasswordState();
  }
}

final AutoDisposeStateNotifierProvider<ChangePasswordNotifier,
        ChangePasswordState> changePasswordProvider =
    StateNotifierProvider.autoDispose<ChangePasswordNotifier,
        ChangePasswordState>((Ref ref) {
  final SecurityService service = ref.watch(securityServiceProvider);
  return ChangePasswordNotifier(service);
});

