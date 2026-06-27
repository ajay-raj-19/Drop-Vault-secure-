import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'providers.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repository;
  final String _email;

  ThemeNotifier(this._repository, {required String email}) : _email = email, super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final modeString = await _repository.getThemeMode(_email);
    switch (modeString) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final targetMode = mode == ThemeMode.system ? ThemeMode.light : mode;
    state = targetMode;
    final modeString = targetMode == ThemeMode.dark ? 'dark' : 'light';
    await _repository.saveThemeMode(_email, modeString);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return ThemeNotifier(repository, email: email);
});
