int _parseChallengeId(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final int? parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return 0;
}

/// Verification channel selected by the user.
enum VerificationMethod {
  whatsapp(
    'WhatsApp',
    'Receive 6-digit verification code via WhatsApp message',
  ),
  email('Email', 'Receive 6-digit verification code via email message');

  const VerificationMethod(this.label, this.description);
  final String label;
  final String description;
}

// --- WhatsApp Verification Models ---

/// Request payload for initiating WhatsApp OTP dispatch.
class SendOtpRequest {
  const SendOtpRequest({
    required this.phoneNumber,
    required this.registrationFlowId,
  });

  final String phoneNumber;
  final String registrationFlowId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phoneNumber': phoneNumber,
    'registrationFlowId': registrationFlowId,
  };
}

/// Server response for accepted OTP dispatch.
class SendOtpResult {
  const SendOtpResult({
    required this.challengeId,
    required this.maskedPhoneNumber,
    required this.expiresAtUtc,
    required this.cooldownSeconds,
    required this.accepted,
    required this.status,
    this.message,
    this.isLiveDelivery = true,
  });

  final int challengeId;
  final String maskedPhoneNumber;
  final DateTime expiresAtUtc;
  final int cooldownSeconds;
  final bool accepted;
  final String status;
  final String? message;
  final bool isLiveDelivery;

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      challengeId: _parseChallengeId(json['challengeId']),
      maskedPhoneNumber: json['maskedPhoneNumber']?.toString() ?? '',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toInt() ?? 60,
      accepted: json['accepted'] == true,
      status: json['status']?.toString() ?? 'Pending',
      message: json['message']?.toString(),
      isLiveDelivery: json['isLiveDelivery'] != false,
    );
  }
}

/// Request payload for resending an OTP code for an active challenge.
class ResendOtpRequest {
  const ResendOtpRequest({
    required this.challengeId,
    required this.registrationFlowId,
  });

  final int challengeId;
  final String registrationFlowId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'challengeId': challengeId,
    'registrationFlowId': registrationFlowId,
  };
}

/// Server response for resent OTP.
class ResendOtpResult {
  const ResendOtpResult({
    required this.challengeId,
    required this.maskedPhoneNumber,
    required this.expiresAtUtc,
    required this.cooldownSeconds,
    required this.accepted,
    required this.status,
    this.message,
    this.isLiveDelivery = true,
  });

  final int challengeId;
  final String maskedPhoneNumber;
  final DateTime expiresAtUtc;
  final int cooldownSeconds;
  final bool accepted;
  final String status;
  final String? message;
  final bool isLiveDelivery;

  factory ResendOtpResult.fromJson(Map<String, dynamic> json) {
    return ResendOtpResult(
      challengeId: _parseChallengeId(json['challengeId']),
      maskedPhoneNumber: json['maskedPhoneNumber']?.toString() ?? '',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toInt() ?? 60,
      accepted: json['accepted'] == true,
      status: json['status']?.toString() ?? 'Pending',
      message: json['message']?.toString(),
      isLiveDelivery: json['isLiveDelivery'] != false,
    );
  }
}

/// Request payload to verify user-entered OTP code.
class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.challengeId,
    required this.registrationFlowId,
    required this.otpCode,
  });

  final int challengeId;
  final String registrationFlowId;
  final String otpCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'challengeId': challengeId,
    'registrationFlowId': registrationFlowId,
    'otpCode': otpCode,
  };
}

/// Server response upon successful server-side WhatsApp OTP verification.
class VerifyOtpResult {
  const VerifyOtpResult({
    required this.verified,
    required this.maskedPhoneNumber,
    required this.verificationGrant,
    required this.verificationGrantExpiresAtUtc,
    required this.message,
  });

  final bool verified;
  final String maskedPhoneNumber;
  final String verificationGrant;
  final DateTime verificationGrantExpiresAtUtc;
  final String message;

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      verified: json['verified'] == true,
      maskedPhoneNumber: json['maskedPhoneNumber']?.toString() ?? '',
      verificationGrant: json['verificationGrant']?.toString() ?? '',
      verificationGrantExpiresAtUtc:
          DateTime.tryParse(
            json['verificationGrantExpiresAtUtc']?.toString() ?? '',
          ) ??
          DateTime.now().add(const Duration(hours: 1)),
      message: json['message']?.toString() ?? 'Phone number verified.',
    );
  }
}

// --- Email Verification Models ---

/// Request payload for initiating Email OTP dispatch.
class SendEmailOtpRequest {
  const SendEmailOtpRequest({
    required this.email,
    required this.registrationFlowId,
  });

  final String email;
  final String registrationFlowId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'registrationFlowId': registrationFlowId,
  };
}

/// Server response for accepted Email OTP dispatch.
class SendEmailOtpResult {
  const SendEmailOtpResult({
    required this.challengeId,
    required this.maskedEmail,
    required this.expiresAtUtc,
    required this.cooldownSeconds,
    required this.accepted,
    required this.status,
    this.message,
    this.isLiveDelivery = true,
  });

  final int challengeId;
  final String maskedEmail;
  final DateTime expiresAtUtc;
  final int cooldownSeconds;
  final bool accepted;
  final String status;
  final String? message;
  final bool isLiveDelivery;

  factory SendEmailOtpResult.fromJson(Map<String, dynamic> json) {
    return SendEmailOtpResult(
      challengeId: _parseChallengeId(json['challengeId']),
      maskedEmail: json['maskedEmail']?.toString() ?? '',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toInt() ?? 60,
      accepted: json['accepted'] == true,
      status: json['status']?.toString() ?? 'Pending',
      message: json['message']?.toString(),
      isLiveDelivery: json['isLiveDelivery'] != false,
    );
  }
}

/// Request payload for resending an Email OTP code.
class ResendEmailOtpRequest {
  const ResendEmailOtpRequest({
    required this.challengeId,
    required this.registrationFlowId,
  });

  final int challengeId;
  final String registrationFlowId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'challengeId': challengeId,
    'registrationFlowId': registrationFlowId,
  };
}

/// Server response for resent Email OTP.
class ResendEmailOtpResult {
  const ResendEmailOtpResult({
    required this.challengeId,
    required this.maskedEmail,
    required this.expiresAtUtc,
    required this.cooldownSeconds,
    required this.accepted,
    required this.status,
    this.message,
    this.isLiveDelivery = true,
  });

  final int challengeId;
  final String maskedEmail;
  final DateTime expiresAtUtc;
  final int cooldownSeconds;
  final bool accepted;
  final String status;
  final String? message;
  final bool isLiveDelivery;

  factory ResendEmailOtpResult.fromJson(Map<String, dynamic> json) {
    return ResendEmailOtpResult(
      challengeId: _parseChallengeId(json['challengeId']),
      maskedEmail: json['maskedEmail']?.toString() ?? '',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toInt() ?? 60,
      accepted: json['accepted'] == true,
      status: json['status']?.toString() ?? 'Pending',
      message: json['message']?.toString(),
      isLiveDelivery: json['isLiveDelivery'] != false,
    );
  }
}

/// Request payload to verify user-entered Email OTP code.
class VerifyEmailOtpRequest {
  const VerifyEmailOtpRequest({
    required this.challengeId,
    required this.registrationFlowId,
    required this.otpCode,
  });

  final int challengeId;
  final String registrationFlowId;
  final String otpCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'challengeId': challengeId,
    'registrationFlowId': registrationFlowId,
    'otpCode': otpCode,
  };
}

/// Server response upon successful server-side Email OTP verification.
class VerifyEmailOtpResult {
  const VerifyEmailOtpResult({
    required this.verified,
    required this.maskedEmail,
    required this.verificationGrant,
    required this.verificationGrantExpiresAtUtc,
    required this.message,
  });

  final bool verified;
  final String maskedEmail;
  final String verificationGrant;
  final DateTime verificationGrantExpiresAtUtc;
  final String message;

  factory VerifyEmailOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyEmailOtpResult(
      verified: json['verified'] == true,
      maskedEmail: json['maskedEmail']?.toString() ?? '',
      verificationGrant: json['verificationGrant']?.toString() ?? '',
      verificationGrantExpiresAtUtc:
          DateTime.tryParse(
            json['verificationGrantExpiresAtUtc']?.toString() ?? '',
          ) ??
          DateTime.now().add(const Duration(hours: 1)),
      message: json['message']?.toString() ?? 'Email address verified.',
    );
  }
}

/// Typed exception encapsulating verification failures.
class VerificationException implements Exception {
  const VerificationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
