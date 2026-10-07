import 'dart:async';

import 'package:drop_vault/features/auth/domain/auth_repository.dart';
import 'package:drop_vault/features/auth/domain/auth_state.dart';
import 'package:drop_vault/features/auth/presentation/login_screen.dart';
import 'package:drop_vault/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class LoginRepository extends Fake implements AuthRepository {
  String? password;
  int googleCalls = 0;
  @override
  AuthState get currentAuthState => AuthState.unauthenticated();
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
  @override
  Future<void> signIn(String email, String password) async {
    this.password = password;
  }
  @override
  Future<void> signInWithGoogle(String email, String displayName,
      {String? profileImagePath}) async {
    googleCalls++;
  }
}

void main() {
  Future<void> showLogin(WidgetTester tester, LoginRepository repository) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: LoginPage()),
    ));
  }

  testWidgets('login preserves the password exactly as typed', (tester) async {
    final repository = LoginRepository();
    await showLogin(tester, repository);
    await tester.enterText(find.byType(TextFormField).first, 'person@example.com');
    await tester.enterText(find.byType(TextFormField).last, ' Password123! ');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.password, ' Password123! ');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Google login authenticates without an account-existence lookup', (tester) async {
    final repository = LoginRepository();
    await showLogin(tester, repository);
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(repository.googleCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
