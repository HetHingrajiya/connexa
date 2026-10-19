/// Result returned upon confirmed server persistence of registration.
class RegistrationSubmissionResult {
  const RegistrationSubmissionResult({
    required this.memberId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.primaryProfileType,
    required this.verifiedMethod,
    required this.verifiedDestination,
    required this.createdAtUtc,
    required this.message,
  });

  final int memberId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String primaryProfileType;
  final String verifiedMethod;
  final String verifiedDestination;
  final DateTime createdAtUtc;
  final String message;

  factory RegistrationSubmissionResult.fromJson(Map<String, dynamic> json) {
    return RegistrationSubmissionResult(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      primaryProfileType: json['primaryProfileType']?.toString() ?? '',
      verifiedMethod: json['verifiedMethod']?.toString() ?? '',
      verifiedDestination: json['verifiedDestination']?.toString() ?? '',
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '') ??
          DateTime.now(),
      message:
          json['message']?.toString() ?? 'Registration completed successfully.',
    );
  }
}

/// Exception thrown when registration submission fails.
class RegistrationException implements Exception {
  const RegistrationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
