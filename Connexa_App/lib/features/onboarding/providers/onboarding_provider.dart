import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory session state tracking whether onboarding has been completed.
///
/// NOTE: This state is maintained in-memory for the active session.
/// In accordance with Step 3 specifications, no persistent storage is attached,
/// and restarting the app will reset this state.
final StateProvider<bool> onboardingCompletedProvider = StateProvider<bool>((
  Ref ref,
) {
  return false;
});
