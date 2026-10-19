/// Model representing the authenticated member basic identity.
class AuthenticatedMember {
  const AuthenticatedMember({
    required this.memberId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.primaryProfileType,
  });

  final int memberId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String primaryProfileType;

  factory AuthenticatedMember.fromJson(Map<String, dynamic> json) {
    return AuthenticatedMember(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Member',
      primaryProfileType: json['primaryProfileType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'memberId': memberId,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'role': role,
    'primaryProfileType': primaryProfileType,
  };
}

/// Model representing authentication response containing JWT access & refresh tokens.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.member,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final AuthenticatedMember member;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      member: AuthenticatedMember.fromJson(
        json['member'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

/// Detailed Member Profile returned from GET /api/v1/members/me.
class MemberProfile {
  const MemberProfile({
    required this.memberId,
    required this.fullName,
    required this.countryCode,
    required this.phoneNumber,
    required this.email,
    required this.primaryProfileType,
    required this.verifiedMethod,
    required this.verifiedDestination,
    required this.role,
    required this.isActive,
    required this.createdAtUtc,
    this.profileDetails,
  });

  final int memberId;
  final String fullName;
  final String countryCode;
  final String phoneNumber;
  final String email;
  final String primaryProfileType;
  final String verifiedMethod;
  final String verifiedDestination;
  final String role;
  final bool isActive;
  final DateTime createdAtUtc;
  final Map<String, dynamic>? profileDetails;

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '+91',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      primaryProfileType: json['primaryProfileType']?.toString() ?? '',
      verifiedMethod: json['verifiedMethod']?.toString() ?? '',
      verifiedDestination: json['verifiedDestination']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Member',
      isActive: json['isActive'] as bool? ?? true,
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      profileDetails: json['profileDetails'] as Map<String, dynamic>?,
    );
  }
}

/// Generic exception thrown during authentication actions.
class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Result returned when requesting setup OTP.
class RequestSetupOtpResult {
  const RequestSetupOtpResult({
    required this.challengeId,
    required this.destination,
    required this.maskedDestination,
    required this.channel,
    required this.flowId,
    required this.message,
  });

  final int challengeId;
  final String destination;
  final String maskedDestination;
  final String channel;
  final String flowId;
  final String message;

  factory RequestSetupOtpResult.fromJson(Map<String, dynamic> json) {
    return RequestSetupOtpResult(
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      destination: json['destination']?.toString() ?? '',
      maskedDestination: json['maskedDestination']?.toString() ?? '',
      channel: json['channel']?.toString() ?? 'Email',
      flowId: json['flowId']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Verification code sent.',
    );
  }
}

/// Result returned when verifying setup OTP.
class VerifySetupOtpResult {
  const VerifySetupOtpResult({
    required this.credentialSetupToken,
    required this.expiresAtUtc,
    required this.destination,
    required this.message,
  });

  final String credentialSetupToken;
  final DateTime expiresAtUtc;
  final String destination;
  final String message;

  factory VerifySetupOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifySetupOtpResult(
      credentialSetupToken: json['credentialSetupToken']?.toString() ?? '',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 30)),
      destination: json['destination']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Verification successful.',
    );
  }
}
