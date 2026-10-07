import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/uuid_helper.dart';

/// Downloads an account's existing cloud records without deleting local data.
class CloudRestoreService {
  final SupabaseClient client;
  final SharedPreferences prefs;

  CloudRestoreService(this.client, this.prefs);

  Future<List<Map<String, dynamic>>> _readAll(
      String table, String select, String userId) async {
    final records = <Map<String, dynamic>>[];
    const pageSize = 1000;
    for (var offset = 0;; offset += pageSize) {
      final page = await client.from(table).select(select)
          .eq('user_id', userId).order('id')
          .range(offset, offset + pageSize - 1)
          .timeout(const Duration(seconds: 30));
      records.addAll(page);
      if (page.length < pageSize) return records;
    }
  }

  Future<void> restore(String email, String userId,
      {required bool Function() isCurrentAccount}) async {
    final items = await _readAll('items', '*, item_tags(tags(name))', userId);
    final collections = await _readAll('collections', '*', userId);
    final reminders = await _readAll('reminders', '*', userId);
    if (!isCurrentAccount()) return;

    Map<String, dynamic> itemJson(Map<String, dynamic> row) => {
      'id': row['id'], 'title': row['title'], 'type': row['type'],
      'content': row['content'], 'collectionName': row['collection_name'],
      'createdAt': row['created_at'], 'updatedAt': row['updated_at'],
      'category': row['category'],
      'tags': (row['item_tags'] as List? ?? [])
          .map((tag) => tag['tags']?['name']).whereType<String>().toList(),
    };
    for (final trash in [false, true]) {
      if (!isCurrentAccount()) return;
      await _merge('${trash ? 'trash_items' : 'vault_items'}_$email',
          'pending_deleted_items_$email',
          items.where((row) => (row['is_trash'] ?? false) == trash)
              .map(itemJson).toList());
    }
    if (!isCurrentAccount()) return;
    await _merge('collections_$email', 'pending_deleted_collections_$email',
        collections.map((row) => <String, dynamic>{
          'id': row['id'], 'name': row['name'],
          'description': row['description'] ?? '',
          'createdAt': row['created_at'], 'updatedAt': row['updated_at'],
        }).toList());
    if (!isCurrentAccount()) return;
    await _merge('reminders_$email', 'pending_deleted_reminders_$email',
        reminders.map((row) => <String, dynamic>{
          'id': row['id'], 'title': row['title'],
          'collectionName': row['collection_name'], 'dateTime': row['date_time'],
          'isCompleted': row['is_completed'] ?? false, 'itemId': row['item_id'],
          'updatedAt': row['updated_at'],
        }).toList());
  }

  Future<void> _merge(String key, String deletionKey,
      List<Map<String, dynamic>> remote) async {
    // Re-read after network awaits so local edits made during download survive.
    var original = prefs.getStringList(key) ?? [];
    final backupKey = 'before_cloud_restore_$key';
    if (original.isNotEmpty && !prefs.containsKey(backupKey)) {
      await prefs.setStringList(backupKey, original);
      original = prefs.getStringList(key) ?? [];
    }
    final records = <String, Map<String, dynamic>>{};
    for (final value in original) {
      final row = jsonDecode(value) as Map<String, dynamic>;
      records[toUuid(row['id'] as String)] = row;
    }
    final deleted = (prefs.getStringList(deletionKey) ?? []).map(toUuid).toSet();
    for (final row in remote) {
      final id = toUuid(row['id'] as String);
      if (deleted.contains(id)) continue;
      final local = records[id];
      final localTime = DateTime.tryParse(local?['updatedAt'] as String? ?? '');
      final remoteTime = DateTime.tryParse(row['updatedAt'] as String? ?? '');
      if (local == null || (remoteTime != null &&
          (localTime == null || remoteTime.isAfter(localTime)))) {
        records[id] = {...row, if (local != null) 'id': local['id']};
      }
    }
    await prefs.setStringList(key, records.values.map(jsonEncode).toList());
  }
}
