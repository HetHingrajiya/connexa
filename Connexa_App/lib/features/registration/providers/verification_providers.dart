import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/verification_models.dart';
import 'package:connexa/features/registration/providers/registration_provider.dart';
import 'package:connexa/features/registration/services/phone_verification_service.dart';

enum VerificationStatus {
  initial,
  sendingOtp,
  otpSent,
  verifying,
  verified,
  error,
}

class PhoneVerificationState {
  const PhoneVerificationState({
    this.status = VerificationStatus.initial,
    this.challengeId,
    this.maskedPhoneNumber,
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
  final String? maskedPhoneNumber;
  final DateTime? expiresAt;
  final int cooldownSeconds;
  final int cooldownRemaining;
  final String? errorMessage;
  final String? verificationGrant;
  final bool isSubmitting;
  final bool isLiveDelivery;

  bool get canResend => cooldownRemaining <= 0 && !isSubmitting;
  bool get isVerified => status == VerificationStatus.verified;

  PhoneVerificationState copyWith({
    VerificationStatus? status,
    int? challengeId,
    String? maskedPhoneNumber,
    DateTime? expiresAt,
    int? cooldownSeconds,
    int? cooldownRemaining,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? verificationGrant,
    bool? isSubmitting,
    bool? isLiveDelivery,
  }) {
    return PhoneVerificationState(
      status: status ?? this.status,
      challengeId: challengeId ?? this.challengeId,
      maskedPhoneNumber: maskedPhoneNumber ?? this.maskedPhoneNumber,
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

class PhoneVerificationNotifier extends StateNotifier<PhoneVerificationState> {
  PhoneVerificationNotifier(this._service, this._ref)
    : super(const PhoneVerificationState());

  final PhoneVerificationService _service;
  final Ref _ref;
  Timer? _cooldownTimer;

  String? _registrationFlowId;
  String? _rawPhoneNumber;

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

  /// Sends a WhatsApp OTP to the target phone number.
  Future<void> sendOtp({
    required String phoneNumber,
    required String registrationFlowId,
  }) async {
    if (state.isSubmitting) return;

    _rawPhoneNumber = phoneNumber;
    _registrationFlowId = registrationFlowId;

    state = state.copyWith(
      status: VerificationStatus.sendingOtp,
      isSubmitting: true,
      clearErrorMessage: true,
    );

    try {
      final SendOtpResult result = await _service.sendOtp(
        SendOtpRequest(
          phoneNumber: phoneNumber,
          registrationFlowId: registrationFlowId,
        ),
      );

      state = state.copyWith(
        status: VerificationStatus.otpSent,
        challengeId: result.challengeId,
        maskedPhoneNumber: result.maskedPhoneNumber,
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
        errorMessage: 'An unexpected error occurred while requesting OTP: $e',
        isSubmitting: false,
      );
    }
  }

  /// Resends a fresh OTP code for the active challenge subject to cooldown limits.
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
      final ResendOtpResult result = await _service.resendOtp(
        ResendOtpRequest(challengeId: challengeId, registrationFlowId: flowId),
      );

      state = state.copyWith(
        status: VerificationStatus.otpSent,
        challengeId: result.challengeId,
        maskedPhoneNumber: result.maskedPhoneNumber,
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
        errorMessage: 'Failed to resend verification code: $e',
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
            'Verification session expired or invalid. Please request a new code.',
      );
      return false;
    }

    state = state.copyWith(
      status: VerificationStatus.verifying,
      isSubmitting: true,
      clearErrorMessage: true,
    );

    try {
      final VerifyOtpResult result = await _service.verifyOtp(
        VerifyOtpRequest(
          challengeId: challengeId,
          registrationFlowId: flowId,
          otpCode: trimmedCode,
        ),
      );

      _cooldownTimer?.cancel();

      state = state.copyWith(
        status: VerificationStatus.verified,
        verificationGrant: result.verificationGrant,
        maskedPhoneNumber: result.maskedPhoneNumber,
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
            verifiedMethod: 'whatsapp',
            verifiedDestination: result.maskedPhoneNumber,
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
        errorMessage: 'Verification failed: $e',
        isSubmitting: false,
      );
      return false;
    }
  }

  /// Retries sending OTP after an initial failure.
  Future<void> retryInitialSend() async {
    if (_rawPhoneNumber != null && _registrationFlowId != null) {
      await sendOtp(
        phoneNumber: _rawPhoneNumber!,
        registrationFlowId: _registrationFlowId!,
      );
    }
  }
}

final StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>
phoneVerificationProvider =
    StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>((
      Ref ref,
    ) {
      final PhoneVerificationService service = ref.watch(
        phoneVerificationServiceProvider,
      );
      return PhoneVerificationNotifier(service, ref);
    });
