/// Data models for Step 29 Security and Account Management.
class ForgotPasswordRequest {
  const ForgotPasswordRequest({
    required this.identifier,
    this.preferredChannel,
  });

  final String identifier;
  final String? preferredChannel;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'identifier': identifier.trim(),
        if (preferredChannel != null) 'preferredChannel': preferredChannel,
      };
}

class ForgotPasswordResponse {
  const ForgotPasswordResponse({
    required this.success,
    required this.message,
    required this.maskedDestination,
    required this.channel,
    required this.flowId,
    required this.challengeId,
    required this.expirySeconds,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      maskedDestination: json['maskedDestination'] as String? ?? '',
      channel: json['channel'] as String? ?? 'Email',
      flowId: json['flowId'] as String? ?? '',
      challengeId: json['challengeId'] as int? ?? 0,
      expirySeconds: json['expirySeconds'] as int? ?? 600,
    );
  }

  final bool success;
  final String message;
  final String maskedDestination;
  final String channel;
  final String flowId;
  final int challengeId;
  final int expirySeconds;
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.identifier,
    required this.otpCode,
    required this.flowId,
    required this.challengeId,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String identifier;
  final String otpCode;
  final String flowId;
  final int challengeId;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'identifier': identifier.trim(),
        'otpCode': otpCode.trim(),
        'flowId': flowId,
        'challengeId': challengeId,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    this.revokeOtherSessions = true,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final bool revokeOtherSessions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'revokeOtherSessions': revokeOtherSessions,
      };
}

class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.deviceName,
    this.ipAddress,
    required this.createdAtUtc,
    required this.lastActiveAtUtc,
    required this.isCurrent,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'] as int? ?? 0,
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      ipAddress: json['ipAddress'] as String?,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? '') ??
          DateTime.now().toUtc(),
      lastActiveAtUtc:
          DateTime.tryParse(json['lastActiveAtUtc'] as String? ?? '') ??
              DateTime.now().toUtc(),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  final int id;
  final String deviceName;
  final String? ipAddress;
  final DateTime createdAtUtc;
  final DateTime lastActiveAtUtc;
  final bool isCurrent;
}

class DeactivateAccountRequest {
  const DeactivateAccountRequest({
    required this.password,
    this.reason,
  });

  final String password;
  final String? reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'password': password,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}

class DeleteAccountRequest {
  const DeleteAccountRequest({
    required this.password,
    required this.reason,
  });

  final String password;
  final String reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'password': password,
        'reason': reason,
      };
}

class AccountStatus {
  const AccountStatus({
    required this.isActive,
    this.deactivatedAtUtc,
    this.deactivationReason,
    required this.hasPendingDeletionRequest,
    this.deletionRequestedAtUtc,
  });

  factory AccountStatus.fromJson(Map<String, dynamic> json) {
    return AccountStatus(
      isActive: json['isActive'] as bool? ?? true,
      deactivatedAtUtc: json['deactivatedAtUtc'] != null
          ? DateTime.tryParse(json['deactivatedAtUtc'] as String)
          : null,
      deactivationReason: json['deactivationReason'] as String?,
      hasPendingDeletionRequest:
          json['hasPendingDeletionRequest'] as bool? ?? false,
      deletionRequestedAtUtc: json['deletionRequestedAtUtc'] != null
          ? DateTime.tryParse(json['deletionRequestedAtUtc'] as String)
          : null,
    );
  }

  final bool isActive;
  final DateTime? deactivatedAtUtc;
  final String? deactivationReason;
  final bool hasPendingDeletionRequest;
  final DateTime? deletionRequestedAtUtc;
}

