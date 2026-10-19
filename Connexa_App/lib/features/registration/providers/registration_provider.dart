import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/registration/models/registration_draft.dart';
import 'package:connexa/features/registration/models/registration_submission_models.dart';
import 'package:connexa/features/registration/services/registration_service.dart';

/// In-memory Riverpod provider managing the active registration draft.
///
/// NOTE: This state is held in-memory for the current application session.
/// No personal data is persisted or logged to the console.
final StateProvider<RegistrationDraft> registrationDraftProvider =
    StateProvider<RegistrationDraft>((Ref ref) {
      return const RegistrationDraft();
    });

/// State representation for final registration submission.
class RegistrationSubmissionState {
  const RegistrationSubmissionState({
    this.isSubmitting = false,
    this.result,
    this.errorMessage,
  });

  final bool isSubmitting;
  final RegistrationSubmissionResult? result;
  final String? errorMessage;

  bool get isSuccess => result != null;
}

/// State notifier managing the submission lifecycle, duplicate prevention, and draft preservation on failure.
class RegistrationSubmissionNotifier
    extends StateNotifier<RegistrationSubmissionState> {
  RegistrationSubmissionNotifier(this._service)
    : super(const RegistrationSubmissionState());

  final RegistrationService _service;

  /// Executes final registration persistence against the backend.
  Future<bool> submit(RegistrationDraft draft) async {
    if (state.isSubmitting) return false;

    state = const RegistrationSubmissionState(isSubmitting: true);

    try {
      final RegistrationSubmissionResult result = await _service
          .submitRegistration(draft);
      state = RegistrationSubmissionState(isSubmitting: false, result: result);
      return true;
    } on RegistrationException catch (e) {
      state = RegistrationSubmissionState(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = const RegistrationSubmissionState(
        isSubmitting: false,
        errorMessage:
            'An unexpected error occurred while completing registration.',
      );
      return false;
    }
  }

  /// Clears active error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = RegistrationSubmissionState(
        isSubmitting: state.isSubmitting,
        result: state.result,
        errorMessage: null,
      );
    }
  }
}

/// Riverpod provider for final registration submission.
final StateNotifierProvider<
  RegistrationSubmissionNotifier,
  RegistrationSubmissionState
>
registrationSubmissionProvider =
    StateNotifierProvider<
      RegistrationSubmissionNotifier,
      RegistrationSubmissionState
    >((Ref ref) {
      final RegistrationService service = ref.watch(
        registrationServiceProvider,
      );
      return RegistrationSubmissionNotifier(service);
    });
