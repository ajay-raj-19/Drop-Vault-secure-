import 'dart:async';
import 'dart:convert';

import 'package:drop_vault/features/auth/data/supabase_auth_repository.dart';
import 'package:drop_vault/features/auth/domain/auth_state.dart';
import 'package:drop_vault/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, AuthUser;

Map<String, dynamic> userJson() => {
  'id': '00000000-0000-0000-0000-000000000001',
  'aud': 'authenticated',
  'email': 'person@example.com',
  'created_at': '2026-01-01T00:00:00Z',
  'email_confirmed_at': '2026-01-01T00:00:00Z',
  'app_metadata': {'provider': 'email'},
  'user_metadata': {'full_name': 'Test Person'},
};

Map<String, dynamic> sessionJson() => {
  'access_token': 'test-token',
  'refresh_token': 'test-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': userJson(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SupabaseAuthRepository repository;
  late SharedPreferences prefs;

  Future<void> setup(Future<http.Response> Function(http.Request) handler) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    client = SupabaseClient('https://example.supabase.co', 'test-key',
      httpClient: MockClient(handler),
      authOptions: AuthClientOptions(autoRefreshToken: false,
        pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage()),
    );
    repository = SupabaseAuthRepository(prefs, client);
  }

  tearDown(() async {
    repository.dispose();
    await client.dispose();
  });

  test('notifier starts from current repository state', () async {
    await setup((_) async => http.Response('[]', 200));
    final notifier = AuthNotifier(repository);
    expect(notifier.state.status, AuthStatus.unauthenticated);
    notifier.dispose();
  });

  test('login succeeds while profile requests are still pending', () async {
    final profile = Completer<http.Response>();
    String? password;
    await setup((request) async {
      if (request.url.path.endsWith('/token')) {
        password = (jsonDecode(request.body) as Map)['password'] as String;
        return http.Response(jsonEncode(sessionJson()), 200);
      }
      return profile.future;
    });
    await repository.signIn(' person@example.com ', ' password with spaces ')
        .timeout(const Duration(seconds: 1));
    expect(password, ' password with spaces ');
    expect(repository.currentAuthState.status, AuthStatus.authenticated);
    profile.complete(http.Response('[]', 200));
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });

  test('signup without a session stays unauthenticated', () async {
    await setup((_) async => http.Response(jsonEncode(userJson()), 200));
    await repository.signUp('person@example.com', 'Password123!', 'Person');
    expect(repository.currentAuthState.status, AuthStatus.unauthenticated);
    expect(client.auth.currentSession, isNull);
  });

  test('failed credentials leave login ready to retry', () async {
    await setup((_) async => http.Response(
      jsonEncode({'msg': 'Invalid login credentials', 'code': 'invalid_credentials'}), 400));
    await expectLater(repository.signIn('person@example.com', 'wrong'), throwsException);
    expect(repository.currentAuthState.status, AuthStatus.unauthenticated);
    expect(repository.currentAuthState.errorMessage, contains('Incorrect password'));
  });

  test('late profile response cannot restore a signed-out user', () async {
    final profile = Completer<http.Response>();
    await setup((request) async {
      if (request.url.path.endsWith('/token')) {
        return http.Response(jsonEncode(sessionJson()), 200);
      }
      if (request.url.path.endsWith('/logout')) return http.Response('', 204);
      return profile.future;
    });
    await repository.signIn('person@example.com', 'Password123!');
    await repository.signOut();
    profile.complete(http.Response('[]', 200));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repository.currentAuthState.status, AuthStatus.unauthenticated);
  });

  test('corrupt local migration data does not undo a successful login', () async {
    await setup((request) async => request.url.path.endsWith('/token')
      ? http.Response(jsonEncode(sessionJson()), 200)
      : http.Response('[]', 200));
    await prefs.setStringList('vault_items_anonymous', ['invalid json']);
    await repository.signIn('person@example.com', 'Password123!');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repository.currentAuthState.status, AuthStatus.authenticated);
    expect(prefs.getStringList('vault_items_anonymous'), ['invalid json']);
  });
}
