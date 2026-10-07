import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../data/mock_auth_service.dart';
import '../../data/supabase_auth_repository.dart';

import '../../../../core/providers/providers.dart' show sharedPreferencesProvider, supabaseServiceProvider;

import 'package:flutter/foundation.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  if (supabaseService.isInitialized) {
    final repository = SupabaseAuthRepository(prefs, supabaseService.client);
    ref.onDispose(repository.dispose);
    return repository;
  } else {
    if (kReleaseMode) {
      throw StateError('Supabase is not initialized in Release Mode. Mock authentication is disabled.');
    }
    return MockAuthService(prefs);
  }
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _subscription;

  AuthNotifier(this._repository) : super(_repository.currentAuthState) {
    _subscription = _repository.authStateChanges.listen((state) {
      this.state = state;
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _repository.signIn(email, password);
    } catch (e) {
      // Errors are handled by updating state inside the repository,
      // but rethrowing allows UI components to react if needed.
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    try {
      await _repository.signUp(email, password, displayName);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      await _repository.verifyEmail(email, code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle(String email, String displayName, {String? profileImagePath}) async {
    try {
      await _repository.signInWithGoogle(email, displayName, profileImagePath: profileImagePath);
    } catch (e) {
      rethrow;
    }
  }



  Future<void> exchangeCodeForSession(String code) async {
    try {
      await _repository.exchangeCodeForSession(code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String email, String newPassword) async {
    try {
      await _repository.updatePassword(email, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  Future<void> recoverPassword(String email) async {
    try {
      await _repository.recoverPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? profileImagePath, bool clearProfileImage = false}) async {
    try {
      await _repository.updateProfile(
        displayName: displayName,
        profileImagePath: profileImagePath,
        clearProfileImage: clearProfileImage,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(String email) async {
    await _repository.deleteAccount(email);
  }

  Future<String?> pickGoogleAccount() async {
    return await _repository.pickGoogleAccount();
  }

  Future<bool> isEmailRegistered(String email) async {
    return await _repository.isEmailRegistered(email);
  }

  Future<void> reloadSession() async {
    await _repository.reloadSession();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
