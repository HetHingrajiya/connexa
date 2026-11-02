import 'package:flutter_test/flutter_test.dart';
import 'package:connexa/features/auth/models/security_models.dart';

void main() {
  group('Security Models & DTO Tests', () {
    test('ForgotPasswordRequest serialization', () {
      const ForgotPasswordRequest req = ForgotPasswordRequest(
        identifier: 'test@example.com',
        preferredChannel: 'WhatsApp',
      );

      final Map<String, dynamic> json = req.toJson();
      expect(json['identifier'], 'test@example.com');
      expect(json['preferredChannel'], 'WhatsApp');
    });

    test('ForgotPasswordResponse parsing from JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'success': true,
        'message': 'Code dispatched',
        'maskedDestination': 't***@example.com',
        'channel': 'Email',
        'flowId': 'FLOW-12345',
        'challengeId': 42,
        'expirySeconds': 600,
      };

      final ForgotPasswordResponse res = ForgotPasswordResponse.fromJson(json);
      expect(res.success, isTrue);
      expect(res.message, 'Code dispatched');
      expect(res.maskedDestination, 't***@example.com');
      expect(res.channel, 'Email');
      expect(res.flowId, 'FLOW-12345');
      expect(res.challengeId, 42);
      expect(res.expirySeconds, 600);
    });

    test('ResetPasswordRequest serialization', () {
      const ResetPasswordRequest req = ResetPasswordRequest(
        identifier: 'user@connexa.com',
        otpCode: '123456',
        flowId: 'FLOW-999',
        challengeId: 10,
        newPassword: 'SecurePassword123!',
        confirmPassword: 'SecurePassword123!',
      );

      final Map<String, dynamic> json = req.toJson();
      expect(json['identifier'], 'user@connexa.com');
      expect(json['otpCode'], '123456');
      expect(json['flowId'], 'FLOW-999');
      expect(json['challengeId'], 10);
      expect(json['newPassword'], 'SecurePassword123!');
      expect(json['confirmPassword'], 'SecurePassword123!');
    });

    test('ChangePasswordRequest serialization', () {
      const ChangePasswordRequest req = ChangePasswordRequest(
        currentPassword: 'OldPassword1!',
        newPassword: 'NewPassword2@',
        confirmPassword: 'NewPassword2@',
        revokeOtherSessions: true,
      );

      final Map<String, dynamic> json = req.toJson();
      expect(json['currentPassword'], 'OldPassword1!');
      expect(json['newPassword'], 'NewPassword2@');
      expect(json['confirmPassword'], 'NewPassword2@');
      expect(json['revokeOtherSessions'], isTrue);
    });

    test('ActiveSession deserialization and parsing', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 7,
        'deviceName': 'Windows PC (Chrome)',
        'ipAddress': '192.168.1.50',
        'createdAtUtc': '2026-11-02T10:00:00Z',
        'lastActiveAtUtc': '2026-11-02T17:30:00Z',
        'isCurrent': true,
      };

      final ActiveSession session = ActiveSession.fromJson(json);
      expect(session.id, 7);
      expect(session.deviceName, 'Windows PC (Chrome)');
      expect(session.ipAddress, '192.168.1.50');
      expect(session.isCurrent, isTrue);
      expect(session.createdAtUtc.isUtc, isTrue);
      expect(session.lastActiveAtUtc.isUtc, isTrue);
    });

    test('DeactivateAccountRequest serialization', () {
      const DeactivateAccountRequest req = DeactivateAccountRequest(
        password: 'Password123!',
        reason: 'Temporary break from business',
      );

      final Map<String, dynamic> json = req.toJson();
      expect(json['password'], 'Password123!');
      expect(json['reason'], 'Temporary break from business');
    });

    test('DeleteAccountRequest serialization', () {
      const DeleteAccountRequest req = DeleteAccountRequest(
        password: 'Password123!',
        reason: 'Closing company operations',
      );

      final Map<String, dynamic> json = req.toJson();
      expect(json['password'], 'Password123!');
      expect(json['reason'], 'Closing company operations');
    });

    test('AccountStatus deserialization', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'isActive': true,
        'deactivatedAtUtc': null,
        'deactivationReason': null,
        'hasPendingDeletionRequest': true,
        'deletionRequestedAtUtc': '2026-11-02T12:00:00Z',
      };

      final AccountStatus status = AccountStatus.fromJson(json);
      expect(status.isActive, isTrue);
      expect(status.hasPendingDeletionRequest, isTrue);
      expect(status.deletionRequestedAtUtc, isNotNull);
      expect(status.deactivatedAtUtc, isNull);
    });
  });
}

