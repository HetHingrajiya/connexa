import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/registration/models/registration_draft.dart';

/// In-memory Riverpod provider managing the active registration draft.
///
/// NOTE: This state is held in-memory for the current application session.
/// No personal data is persisted or logged to the console.
final StateProvider<RegistrationDraft> registrationDraftProvider =
    StateProvider<RegistrationDraft>((Ref ref) {
      return const RegistrationDraft();
    });
