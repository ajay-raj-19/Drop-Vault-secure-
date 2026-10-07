import 'dart:convert';

import 'package:drop_vault/core/services/cloud_restore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const email = 'test@example.com';
  const id = '00000000-0000-0000-0000-000000000001';
  const userId = '00000000-0000-0000-0000-000000000002';
  late SharedPreferences prefs;
  late SupabaseClient client;
  late CloudRestoreService service;
  late Map<String, List<Map<String, dynamic>>> remote;

  Map<String, dynamic> remoteItem() => {
    'id': id, 'title': 'Cloud note', 'type': 'note', 'content': 'Saved content',
    'collection_name': 'Notes', 'is_trash': false,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-02T00:00:00Z',
    'item_tags': [{'tags': {'name': 'saved'}}],
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    remote = {'items': [], 'collections': [], 'reminders': []};
    client = SupabaseClient('https://example.supabase.co', 'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        expect(request.method, 'GET'); // Recovery must not mutate cloud data.
        expect(request.url.queryParameters['user_id'], 'eq.$userId');
        return http.Response(jsonEncode(remote[request.url.pathSegments.last]), 200,
            request: request, headers: {'content-type': 'application/json'});
      }),
    );
    service = CloudRestoreService(client, prefs);
  });
  tearDown(() async => client.dispose());

  test('fresh login restores cloud items and collections', () async {
    remote['items'] = [remoteItem()];
    remote['collections'] = [{
      'id': id, 'name': 'Notes', 'description': '',
      'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-02T00:00:00Z',
    }];
    await service.restore(email, userId, isCurrentAccount: () => true);
    final items = prefs.getStringList('vault_items_$email')!;
    expect(items, hasLength(1));
    expect(jsonDecode(items.single)['tags'], ['saved']);
    expect(prefs.getStringList('collections_$email'), hasLength(1));
  });

  test('empty cloud does not erase local UUID items', () async {
    final local = jsonEncode({'id': id, 'title': 'Offline note'});
    await prefs.setStringList('vault_items_$email', [local]);
    await service.restore(email, userId, isCurrentAccount: () => true);
    expect(prefs.getStringList('vault_items_$email'), [local]);
    expect(prefs.getStringList('before_cloud_restore_vault_items_$email'), [local]);
  });

  test('newer local edits survive restoration', () async {
    remote['items'] = [remoteItem()];
    final local = jsonEncode({
      'id': id, 'title': 'Newer local title', 'updatedAt': '2026-02-01T00:00:00Z',
    });
    await prefs.setStringList('vault_items_$email', [local]);
    await service.restore(email, userId, isCurrentAccount: () => true);
    expect(prefs.getStringList('vault_items_$email'), [local]);
  });

  test('queued deletions are not restored', () async {
    remote['items'] = [remoteItem()];
    await prefs.setStringList('pending_deleted_items_$email', [id]);
    await service.restore(email, userId, isCurrentAccount: () => true);
    expect(prefs.getStringList('vault_items_$email'), isEmpty);
  });

  test('account switch cancels a pending restore', () async {
    remote['items'] = [remoteItem()];
    await service.restore(email, userId, isCurrentAccount: () => false);
    expect(prefs.containsKey('vault_items_$email'), isFalse);
  });

  test('repeated restore does not duplicate items', () async {
    remote['items'] = [remoteItem()];
    await service.restore(email, userId, isCurrentAccount: () => true);
    await service.restore(email, userId, isCurrentAccount: () => true);
    expect(prefs.getStringList('vault_items_$email'), hasLength(1));
  });
}
