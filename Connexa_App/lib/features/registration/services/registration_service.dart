import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';
import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/registration_submission_models.dart';

/// Riverpod provider for [RegistrationService].
final Provider<RegistrationService> registrationServiceProvider =
    Provider<RegistrationService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return RegistrationService(dio);
    });

/// Service responsible for submitting finalized registration drafts to the backend API.
class RegistrationService {
  RegistrationService(this._dio);

  final Dio _dio;

  static const String _submitEndpoint = '/api/v1/registration/submit';

  /// Submits the registration draft and server verification grant.
  Future<RegistrationSubmissionResult> submitRegistration(
    RegistrationDraft draft,
  ) async {
    if (!draft.isVerified || draft.verificationGrant == null) {
      throw const RegistrationException(
        'Registration cannot proceed without a valid server verification grant.',
      );
    }

    if (draft.profileType == null) {
      throw const RegistrationException(
        'Please select a profile role before submitting registration.',
      );
    }

    final Map<String, dynamic> payload = _buildPayload(draft);

    try {
      final Response<dynamic> response = await _dio.post(
        _submitEndpoint,
        data: payload,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return RegistrationSubmissionResult.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
        throw RegistrationException(
          data['message']?.toString() ?? 'Registration submission failed.',
          statusCode: response.statusCode,
        );
      }
      throw const RegistrationException('Invalid server response format.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _buildPayload(RegistrationDraft draft) {
    final Map<String, dynamic> json = <String, dynamic>{
      'verificationGrant': draft.verificationGrant,
      'registrationFlowId': draft.registrationFlowId,
      'fullName': draft.fullName.trim(),
      'countryCode': draft.countryCode.trim(),
      'mobileNumber': draft.mobileNumber.trim(),
      'email': draft.email.trim(),
      'profileType': _profileTypeToInt(draft.profileType!),
    };

    switch (draft.profileType!) {
      case ProfileType.businessCompany:
        final BusinessProfileDetails? b = draft.businessDetails;
        final IndustrySelection? ind = b?.industrySelection;
        json['businessDetails'] = <String, dynamic>{
          'companyName': b?.companyName.trim() ?? '',
          'businessCapabilities':
              b?.businessCapabilities
                  .map((BusinessCapability c) => c.label)
                  .toList() ??
              <String>[],
          'businessDescription': b?.businessDescription.trim() ?? '',
          'industryId': ind?.industryId ?? 0,
          'businessGroupId': ind?.businessGroupId ?? 0,
          'subGroupId': ind?.subGroupId ?? 0,
          'categoryId': ind?.categoryId ?? 0,
        };
        break;

      case ProfileType.employeeJobSeeker:
        final EmployeeProfileDetails? e = draft.employeeDetails;
        json['employeeDetails'] = <String, dynamic>{
          'jobTitle': e?.jobTitle.trim() ?? '',
          'skills': e?.skills.trim() ?? '',
          'experience': e?.experience.trim() ?? '',
          'preferredJobType': e?.preferredJobType.trim() ?? '',
        };
        break;

      case ProfileType.serviceEngineer:
        final ServiceEngineerProfileDetails? s = draft.serviceEngineerDetails;
        json['serviceEngineerDetails'] = <String, dynamic>{
          'specialization': s?.specialization.trim() ?? '',
          'supportedEquipment': s?.supportedEquipment.trim() ?? '',
          'yearsOfExperience': s?.yearsOfExperience.trim() ?? '',
          'serviceCoverage': s?.serviceCoverage.trim() ?? '',
        };
        break;

      case ProfileType.traderSupplier:
        final TraderProfileDetails? t = draft.traderDetails;
        json['traderDetails'] = <String, dynamic>{
          'tradingName': t?.tradingName.trim() ?? '',
          'capabilities':
              t?.capabilities.map((BusinessCapability c) => c.label).toList() ??
              <String>[],
          'productsSupplied': t?.productsSupplied.trim() ?? '',
          'serviceCoverage': t?.serviceCoverage.trim() ?? '',
        };
        break;

      case ProfileType.contractorJobWorker:
        final ContractorProfileDetails? c = draft.contractorDetails;
        final IndustrySelection? ind = c?.industrySelection;
        json['contractorDetails'] = <String, dynamic>{
          'workName': c?.workName.trim() ?? '',
          'workCapabilities': c?.workCapabilities.toList() ?? <String>[],
          'processesSupported': c?.processesSupported.trim() ?? '',
          'workCoverage': c?.workCoverage.trim() ?? '',
          'industryId': ind?.industryId ?? 0,
          'businessGroupId': ind?.businessGroupId ?? 0,
          'subGroupId': ind?.subGroupId ?? 0,
          'categoryId': ind?.categoryId ?? 0,
        };
        break;
    }

    return json;
  }

  static int _profileTypeToInt(ProfileType type) {
    switch (type) {
      case ProfileType.businessCompany:
        return 1;
      case ProfileType.employeeJobSeeker:
        return 2;
      case ProfileType.serviceEngineer:
        return 3;
      case ProfileType.traderSupplier:
        return 4;
      case ProfileType.contractorJobWorker:
        return 5;
    }
  }

  RegistrationException _handleDioError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final dynamic data = e.response?.data;

    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message']?.toString();
    }

    if (statusCode == 409) {
      return RegistrationException(
        serverMessage ??
            'An account with this phone number or email address already exists. Please sign in instead.',
        statusCode: 409,
      );
    }

    if (statusCode == 400) {
      return RegistrationException(
        serverMessage ??
            'Invalid registration request. Please check your inputs.',
        statusCode: 400,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const RegistrationException(
        'Unable to reach Connexa servers. Please check your network connection and retry.',
        statusCode: 503,
      );
    }

    return RegistrationException(
      serverMessage ?? 'An unexpected error occurred during registration.',
      statusCode: statusCode,
    );
  }
}
