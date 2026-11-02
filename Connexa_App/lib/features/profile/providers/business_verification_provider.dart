import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';
import 'package:connexa/features/profile/models/business_verification_models.dart';
import 'package:connexa/features/profile/services/business_verification_service.dart';

/// Provider for loading the current member's verification status.
final AutoDisposeFutureProvider<VerificationStatusResponse>
verificationStatusProvider =
    FutureProvider.autoDispose<VerificationStatusResponse>((Ref ref) async {
      final BusinessVerificationService service = ref.watch(
        businessVerificationServiceProvider,
      );
      return service.getVerificationStatus();
    });

class AdminVerificationFilter {
  const AdminVerificationFilter({this.status, this.page = 1});
  final String? status;
  final int page;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminVerificationFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          page == other.page;

  @override
  int get hashCode => Object.hash(status, page);
}

/// Provider for loading admin verifications list based on filter and page.
final AutoDisposeFutureProviderFamily<
  AdminVerificationListResponse,
  AdminVerificationFilter
>
adminVerificationsProvider = FutureProvider.autoDispose
    .family<AdminVerificationListResponse, AdminVerificationFilter>((
      Ref ref,
      AdminVerificationFilter filter,
    ) async {
      final BusinessVerificationService service = ref.watch(
        businessVerificationServiceProvider,
      );
      return service.getAdminVerifications(
        status: filter.status,
        page: filter.page,
      );
    });

class VerificationSubmitState {
  const VerificationSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.success = false,
    this.submittedRequest,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final bool success;
  final BusinessVerificationRequest? submittedRequest;

  VerificationSubmitState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? success,
    BusinessVerificationRequest? submittedRequest,
  }) {
    return VerificationSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      success: success ?? this.success,
      submittedRequest: submittedRequest ?? this.submittedRequest,
    );
  }
}

class VerificationSubmitNotifier
    extends StateNotifier<VerificationSubmitState> {
  VerificationSubmitNotifier(this._service, this._ref)
    : super(const VerificationSubmitState());

  final BusinessVerificationService _service;
  final Ref _ref;

  Future<bool> submitVerification({
    required String registrationNumber,
    required String address,
    required String city,
    required String stateName,
    required String pincode,
    String? notes,
    required List<DocumentUploadItem> documents,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final BusinessVerificationRequest request = await _service
          .submitVerification(
            registrationNumber: registrationNumber,
            address: address,
            city: city,
            state: stateName,
            pincode: pincode,
            notes: notes,
            documents: documents,
          );

      state = state.copyWith(
        isSubmitting: false,
        success: true,
        submittedRequest: request,
      );

      // Invalidate current verification status and refresh profile
      _ref.invalidate(verificationStatusProvider);
      _ref.read(authProvider.notifier).refreshProfile();

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const VerificationSubmitState();
  }
}

final AutoDisposeStateNotifierProvider<
  VerificationSubmitNotifier,
  VerificationSubmitState
>
verificationSubmitProvider =
    StateNotifierProvider.autoDispose<
      VerificationSubmitNotifier,
      VerificationSubmitState
    >((Ref ref) {
      final BusinessVerificationService service = ref.watch(
        businessVerificationServiceProvider,
      );
      return VerificationSubmitNotifier(service, ref);
    });
