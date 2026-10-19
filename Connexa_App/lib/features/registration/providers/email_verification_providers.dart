import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/verification_models.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/providers/verification_providers.dart';
import 'package:connexa/features/registration/services/email_verification_service.dart';

class EmailVerificationState {
  const EmailVerificationState({
    this.status = VerificationStatus.initial,
    this.challengeId,
    this.maskedEmail,
    this.expiresAt,
    this.cooldownSeconds = 60,
    this.cooldownRemaining = 0,
    this.errorMessage,
    this.verificationGrant,
    this.isSubmitting = false,
    this.isLiveDelivery = true,
  });

  final VerificationStatus status;
  final int? challengeId;
  final String? maskedEmail;
  final DateTime? expiresAt;
  final int cooldownSeconds;
  final int cooldownRemaining;
  final String? errorMessage;
  final String? verificationGrant;
  final bool isSubmitting;
  final bool isLiveDelivery;

  bool get canResend => cooldownRemaining <= 0 && !isSubmitting;
  bool get isVerified => status == VerificationStatus.verified;

  EmailVerificationState copyWith({
    VerificationStatus? status,
    int? challengeId,
    String? maskedEmail,
    DateTime? expiresAt,
    int? cooldownSeconds,
    int? cooldownRemaining,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? verificationGrant,
    bool? isSubmitting,
    bool? isLiveDelivery,
  }) {
    return EmailVerificationState(
      status: status ?? this.status,
      challengeId: challengeId ?? this.challengeId,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      expiresAt: expiresAt ?? this.expiresAt,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      verificationGrant: verificationGrant ?? this.verificationGrant,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLiveDelivery: isLiveDelivery ?? this.isLiveDelivery,
    );
  }
}

class EmailVerificationNotifier extends StateNotifier<EmailVerificationState> {
  EmailVerificationNotifier(this._service, this._ref)
    : super(const EmailVerificationState());

  final EmailVerificationService _service;
  final Ref _ref;
  Timer? _cooldownTimer;

  String? _registrationFlowId;
  String? _rawEmail;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer(int seconds) {
    _cooldownTimer?.cancel();
    state = state.copyWith(cooldownRemaining: seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (state.cooldownRemaining <= 1) {
        timer.cancel();
        state = state.copyWith(cooldownRemaining: 0);
      } else {
        state = state.copyWith(cooldownRemaining: state.cooldownRemaining - 1);
      }
    });
  }

  /// Sends a Gmail SMTP email OTP to the target email.
  Future<void> sendOtp({
    required String email,
    required String registrationFlowId,
  }) async {
    if (state.isSubmitting) return;

    _rawEmail = email;
    _registrationFlowId = registrationFlowId;

    state = state.copyWith(
      status: VerificationStatus.sendingOtp,
      isSubmitting: true,
      clearErrorMessage: true,
    );

    try {
      final SendEmailOtpResult result = await _service.sendOtp(
        SendEmailOtpRequest(
          email: email,
          registrationFlowId: registrationFlowId,
        ),
      );

      state = state.copyWith(
        status: VerificationStatus.otpSent,
        challengeId: result.challengeId,
        maskedEmail: result.maskedEmail,
        expiresAt: result.expiresAtUtc,
        cooldownSeconds: result.cooldownSeconds,
        isLiveDelivery: result.isLiveDelivery,
        isSubmitting: false,
      );

      _startCooldownTimer(result.cooldownSeconds);
    } on VerificationException catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        errorMessage: e.message,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        errorMessage:
            'An unexpected error occurred while requesting email OTP: $e',
        isSubmitting: false,
      );
    }
  }

  /// Resends a fresh OTP code for the active email challenge subject to cooldown limits.
  Future<void> resendOtp() async {
    final int? challengeId = state.challengeId;
    final String? flowId = _registrationFlowId;

    if (challengeId == null ||
        challengeId <= 0 ||
        flowId == null ||
        !state.canResend) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final ResendEmailOtpResult result = await _service.resendOtp(
        ResendEmailOtpRequest(
          challengeId: challengeId,
          registrationFlowId: flowId,
        ),
      );

      state = state.copyWith(
        status: VerificationStatus.otpSent,
        challengeId: result.challengeId,
        maskedEmail: result.maskedEmail,
        expiresAt: result.expiresAtUtc,
        cooldownSeconds: result.cooldownSeconds,
        isLiveDelivery: result.isLiveDelivery,
        isSubmitting: false,
      );

      _startCooldownTimer(result.cooldownSeconds);
    } on VerificationException catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        errorMessage: e.message,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        errorMessage: 'Failed to resend email verification code: $e',
        isSubmitting: false,
      );
    }
  }

  /// Submits the 6-digit code for server-side verification.
  Future<bool> verifyOtp(String otpCode) async {
    final String trimmedCode = otpCode.trim();
    if (trimmedCode.length != 6 || int.tryParse(trimmedCode) == null) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 6-digit numeric verification code',
      );
      return false;
    }

    final int? challengeId = state.challengeId;
    final String? flowId = _registrationFlowId;

    if (challengeId == null || challengeId <= 0 || flowId == null) {
      state = state.copyWith(
        errorMessage:
            'Email verification session expired or invalid. Please request a new code.',
      );
      return false;
    }

    state = state.copyWith(
      status: VerificationStatus.verifying,
      isSubmitting: true,
      clearErrorMessage: true,
    );

    try {
      final VerifyEmailOtpResult result = await _service.verifyOtp(
        VerifyEmailOtpRequest(
          challengeId: challengeId,
          registrationFlowId: flowId,
          otpCode: trimmedCode,
        ),
      );

      _cooldownTimer?.cancel();

      state = state.copyWith(
        status: VerificationStatus.verified,
        verificationGrant: result.verificationGrant,
        maskedEmail: result.maskedEmail,
        isSubmitting: false,
      );

      // Securely update in-memory registration draft with server-issued verification grant
      final RegistrationDraft currentDraft = _ref.read(
        registrationDraftProvider,
      );
      _ref.read(registrationDraftProvider.notifier).state = currentDraft
          .copyWith(
            registrationFlowId: flowId,
            verificationGrant: result.verificationGrant,
            verificationGrantExpiresAt: result.verificationGrantExpiresAtUtc,
            verifiedMethod: 'email',
            verifiedDestination: result.maskedEmail,
          );

      return true;
    } on VerificationException catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        errorMessage: e.message,
        isSubmitting: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: VerificationStatus.error,
        errorMessage: 'Email verification failed: $e',
        isSubmitting: false,
      );
      return false;
    }
  }

  /// Retries sending OTP after an initial failure.
  Future<void> retryInitialSend() async {
    if (_rawEmail != null && _registrationFlowId != null) {
      await sendOtp(
        email: _rawEmail!,
        registrationFlowId: _registrationFlowId!,
      );
    }
  }
}

final StateNotifierProvider<EmailVerificationNotifier, EmailVerificationState>
emailVerificationProvider =
    StateNotifierProvider<EmailVerificationNotifier, EmailVerificationState>((
      Ref ref,
    ) {
      final EmailVerificationService service = ref.watch(
        emailVerificationServiceProvider,
      );
      return EmailVerificationNotifier(service, ref);
    });
