import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';

/// Key used to persist onboarding completion state in SharedPreferences.
const String _onboardingCompletedKey = 'onboarding_completed';

/// Manages the `onboarding_completed` flag in SharedPreferences.
///
/// This state is completely independent from authentication state:
/// - Set to `true` when the user finishes (or skips) onboarding.
/// - **Never cleared on logout** — ensures onboarding is only shown once.
class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs)
      : super(_prefs.getBool(_onboardingCompletedKey) ?? false);

  /// Marks onboarding as completed and persists the flag.
  Future<void> completeOnboarding() async {
    state = true;
    await _prefs.setBool(_onboardingCompletedKey, true);
  }
}

/// Provider for the onboarding completion state.
///
/// Returns `true` if the user has already completed (or skipped) onboarding,
/// `false` if this is a fresh install and onboarding should be shown.
final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});
