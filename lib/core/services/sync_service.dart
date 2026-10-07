import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import '../utils/uuid_helper.dart';
import 'cache_manager.dart';
import 'cloud_restore_service.dart';
import '../providers/providers.dart';

/// A global sync trigger counter. Increment to cause all watching
/// providers (vault, collections, reminders) to rebuild their state.
final syncTriggerProvider = StateProvider<int>((ref) => 0);

/// Whether a sync is currently in progress.
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Production-grade synchronization engine for Drop Vault.
///
/// Restores cloud data after login and preserves local-only records.
/// Explicit deletion queues are processed during manual synchronization.
class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  Ref? _ref;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  String? _currentEmail;
  int _restoreGeneration = 0;

  // Statistics for the current sync run
  int _itemsUploaded = 0;
  int _itemsDownloaded = 0;
  int _itemsUpdated = 0;
  int _itemsDeleted = 0;
  int _collectionsSynced = 0;
  int _remindersSynced = 0;

  /// Initialize with a Ref so we can read/write providers.
  void initialize(Ref ref) {
    _ref = ref;
  }

  /// Start the 30-second periodic sync timer.
  void startPeriodicSync() {
    // Periodic sync has been disabled.
  }

  /// Stop the periodic sync timer.
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Set the current user email for sync operations.
  void setUser(String? email) {
    if (_currentEmail == email) return;
    _currentEmail = email;
    final generation = ++_restoreGeneration;
    if (email != null) unawaited(_restoreCloudData(email, generation));
  }

  Future<void> _restoreCloudData(String email, int generation) async {
    final service = SupabaseService.instance;
    final prefs = _ref?.read(sharedPreferencesProvider);
    if (!service.isInitialized || prefs == null) return;
    final user = service.client.auth.currentUser;
    if (user == null || user.email != email) return;
    bool stillCurrent() => _ref != null && generation == _restoreGeneration &&
        service.client.auth.currentUser?.id == user.id;
    try {
      await CloudRestoreService(service.client, prefs)
          .restore(email, user.id, isCurrentAccount: stillCurrent);
      if (stillCurrent()) _ref?.read(syncTriggerProvider.notifier).state++;
    } catch (_) {
      debugPrint('[SyncService] Cloud restore unavailable; keeping local data.');
    }
  }

  /// Master sync method — orchestrates all sub-syncs.
  /// Safe to call from any platform. Prevents concurrent syncs.
  Future<void> syncNow() async {
    if (_isSyncing) return;
    if (_currentEmail == null) return;

    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.client.auth.currentUser == null) {
      throw Exception('Supabase is not initialized or user is not logged in.');
    }

    _isSyncing = true;
    _ref?.read(isSyncingProvider.notifier).state = true;

    final stopwatch = Stopwatch()..start();
    final platform = kIsWeb ? 'Web' : Platform.operatingSystem;
    final userId = supabase.client.auth.currentUser!.id;
    final email = _currentEmail!;

    // counters
    _itemsUploaded = 0;
    _itemsDownloaded = 0;
    _itemsUpdated = 0;
    _itemsDeleted = 0;
    _collectionsSynced = 0;
    _remindersSynced = 0;

    debugPrint('========== SYNC START ==========');
    debugPrint('Platform: $platform');
    debugPrint('Current User: $email ($userId)');

    try {
      final prefs = _ref?.read(sharedPreferencesProvider);
      if (prefs == null) {
        debugPrint('[SyncService] ERROR: SharedPreferences not available');
        throw Exception('SharedPreferences not available');
      }

      await syncItems(email, userId, supabase, prefs, isTrash: false);
      await syncItems(email, userId, supabase, prefs, isTrash: true);
      await syncCollections(email, userId, supabase, prefs);
      await syncReminders(email, userId, supabase, prefs);
      await syncProfile(userId, supabase);

      // Notify all UI providers to rebuild
      _ref?.read(syncTriggerProvider.notifier).state++;
    } catch (e, stack) {
      debugPrint('[SyncService] ERROR during sync: $e');
      debugPrint('$stack');
      rethrow;
    } finally {
      stopwatch.stop();
      debugPrint('Items Uploaded: $_itemsUploaded');
      debugPrint('Items Downloaded: $_itemsDownloaded');
      debugPrint('Items Updated: $_itemsUpdated');
      debugPrint('Items Deleted: $_itemsDeleted');
      debugPrint('Collections Synced: $_collectionsSynced');
      debugPrint('Reminders Synced: $_remindersSynced');
      debugPrint('Duration: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('========== SYNC END ==========');

      _isSyncing = false;
      _ref?.read(isSyncingProvider.notifier).state = false;
    }
  }

  // ─────────────────────────────────────────────
  //  ITEMS SYNC (Cloud-Wins)
  // ─────────────────────────────────────────────

  Future<void> syncItems(
    String email,
    String userId,
    SupabaseService supabase,
    SharedPreferences prefs, {
    required bool isTrash,
  }) async {
    final deletionKey = 'pending_deleted_items_$email';

    try {
      // 1. Process offline deletion queue
      final pendingDeletions = prefs.getStringList(deletionKey) ?? [];
      if (pendingDeletions.isNotEmpty) {
        final remaining = <String>[];
        for (final id in pendingDeletions) {
          try {
            await supabase.client
                .from('items')
                .delete()
                .eq('id', toUuid(id))
                .eq('user_id', userId);
            // Also clean up storage
            await _deleteItemStorageIfNeeded(id, userId, supabase, prefs, email);
          } catch (_) {
            remaining.add(id);
          }
        }
        await prefs.setStringList(deletionKey, remaining);
      }

      // 2. Fetch ALL remote items for this user
      final response = await supabase.client
          .from('items')
          .select('*, item_tags(tags(name))')
          .eq('user_id', userId)
          .eq('is_trash', isTrash);

      final remoteItems = (response as List).map((json) {
        final tagsList = <String>[];
        if (json['item_tags'] != null) {
          for (final it in json['item_tags'] as List) {
            if (it['tags'] != null && it['tags']['name'] != null) {
              tagsList.add(it['tags']['name'] as String);
            }
          }
        }
        return VaultItem(
          id: json['id'],
          title: json['title'],
          type: json['type'],
          content: json['content'],
          collectionName: json['collection_name'],
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
          category: json['category'],
          tags: tagsList,
        );
      }).toList();

      final remoteIds = remoteItems.map((i) => i.id).toSet();

      // 3. Fetch ALL local items
      final localRepo = _getLocalItemRepository();
      if (localRepo == null) return;

      final localItems = isTrash
          ? await localRepo.getTrashItems(email)
          : await localRepo.getItems(email);

      // 4. Remote → Local (download new / update existing)
      for (final remoteItem in remoteItems) {
        final localIndex = localItems.indexWhere((i) => toUuid(i.id) == remoteItem.id);
        if (localIndex == -1) {
          // New item from cloud → add locally
          if (isTrash) {
            await localRepo.addTrashItem(email, remoteItem);
          } else {
            await localRepo.addItem(email, remoteItem);
          }
          _itemsDownloaded++;
        } else {
          final localItem = localItems[localIndex];
          if (remoteItem.updatedAt.isAfter(localItem.updatedAt)) {
            // Remote is newer → update local (preserve local ID format)
            final updated = VaultItem(
              id: localItem.id,
              title: remoteItem.title,
              type: remoteItem.type,
              content: remoteItem.content,
              collectionName: remoteItem.collectionName,
              createdAt: remoteItem.createdAt,
              updatedAt: remoteItem.updatedAt,
              tags: remoteItem.tags,
              category: remoteItem.category,
            );
            if (isTrash) {
              await localRepo.deleteTrashItem(email, localItem.id);
              await localRepo.addTrashItem(email, updated);
            } else {
              await localRepo.updateItem(email, updated);
            }
            _itemsUpdated++;
          } else if (localItem.updatedAt.isAfter(remoteItem.updatedAt)) {
            // Local is newer → push to cloud
            await _pushItemToCloud(localItem, userId, supabase, isTrash: isTrash);
            _itemsUploaded++;
          }
        }
      }

      // 5. Preserve local-only records; upload legacy IDs where appropriate.
      // Re-fetch local items after step 4
      final currentLocalItems = isTrash
          ? await localRepo.getTrashItems(email)
          : await localRepo.getItems(email);

      final currentPendingDeletions = prefs.getStringList(deletionKey) ?? [];

      for (final localItem in currentLocalItems) {
        final existsInRemote = remoteIds.contains(toUuid(localItem.id));
        final isPendingDeletion = currentPendingDeletions.contains(localItem.id);
        if (!existsInRemote && !isPendingDeletion) {
          // An absent cloud record can also be an upload that has not succeeded.
          final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(localItem.id);

          if (isUuid) {
            // A UUID does not prove a successful upload or a remote deletion.
            // Preserve local data until an explicit deletion is available.
            continue;
          } else {
            // Local-only item (never synced) → push to cloud
            await _pushItemToCloud(localItem, userId, supabase, isTrash: isTrash);
            _itemsUploaded++;
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[SyncService] syncItems error (isTrash=$isTrash): $e\n$stack');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  //  COLLECTIONS SYNC (Cloud-Wins)
  // ─────────────────────────────────────────────

  Future<void> syncCollections(
    String email,
    String userId,
    SupabaseService supabase,
    SharedPreferences prefs,
  ) async {
    final deletionKey = 'pending_deleted_collections_$email';

    try {
      // 1. Process offline deletion queue
      final pendingDeletions = prefs.getStringList(deletionKey) ?? [];
      if (pendingDeletions.isNotEmpty) {
        final remaining = <String>[];
        for (final id in pendingDeletions) {
          try {
            await supabase.client
                .from('collections')
                .delete()
                .eq('id', toUuid(id))
                .eq('user_id', userId);
          } catch (_) {
            remaining.add(id);
          }
        }
        await prefs.setStringList(deletionKey, remaining);
      }

      // 2. Fetch remote collections
      final response = await supabase.client
          .from('collections')
          .select()
          .eq('user_id', userId);

      final remoteCols = (response as List).map((json) {
        return Collection(
          id: json['id'],
          name: json['name'],
          description: json['description'] ?? '',
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();

      final remoteIds = remoteCols.map((c) => c.id).toSet();

      // 3. Fetch local collections
      final localRepo = _getLocalCollectionRepository();
      if (localRepo == null) return;

      final localCols = await localRepo.getCollections(email);

      // 4. Remote → Local
      for (final remoteCol in remoteCols) {
        final localIndex = localCols.indexWhere((c) => toUuid(c.id) == remoteCol.id);
        if (localIndex == -1) {
          await localRepo.addCollection(email, remoteCol);
          _collectionsSynced++;
        } else {
          final localCol = localCols[localIndex];
          if (remoteCol.updatedAt.isAfter(localCol.updatedAt)) {
            final updated = Collection(
              id: localCol.id,
              name: remoteCol.name,
              description: remoteCol.description,
              createdAt: remoteCol.createdAt,
              updatedAt: remoteCol.updatedAt,
            );
            await localRepo.updateCollection(email, updated);
            _collectionsSynced++;
          } else if (localCol.updatedAt.isAfter(remoteCol.updatedAt)) {
            await _pushCollectionToCloud(localCol, userId, supabase);
            _collectionsSynced++;
          }
        }
      }

      // 5. Preserve missing UUID collections rather than assuming deletion.
      final currentLocalCols = await localRepo.getCollections(email);
      final currentPending = prefs.getStringList(deletionKey) ?? [];

      for (final localCol in currentLocalCols) {
        final existsInRemote = remoteIds.contains(toUuid(localCol.id));
        final isPending = currentPending.contains(localCol.id);
        if (!existsInRemote && !isPending) {
          final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(localCol.id);
          if (isUuid) {
            // Missing cloud rows are not evidence of deletion.
            continue;
          } else {
            await _pushCollectionToCloud(localCol, userId, supabase);
            _collectionsSynced++;
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[SyncService] syncCollections error: $e\n$stack');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  //  REMINDERS SYNC (Cloud-Wins)
  // ─────────────────────────────────────────────

  Future<void> syncReminders(
    String email,
    String userId,
    SupabaseService supabase,
    SharedPreferences prefs,
  ) async {
    final deletionKey = 'pending_deleted_reminders_$email';

    try {
      // 1. Process offline deletion queue
      final pendingDeletions = prefs.getStringList(deletionKey) ?? [];
      if (pendingDeletions.isNotEmpty) {
        final remaining = <String>[];
        for (final id in pendingDeletions) {
          try {
            await supabase.client
                .from('reminders')
                .delete()
                .eq('id', toUuid(id))
                .eq('user_id', userId);
          } catch (_) {
            remaining.add(id);
          }
        }
        await prefs.setStringList(deletionKey, remaining);
      }

      // 2. Fetch remote reminders
      final response = await supabase.client
          .from('reminders')
          .select()
          .eq('user_id', userId);

      final remoteReminders = (response as List).map((json) {
        return Reminder(
          id: json['id'],
          title: json['title'],
          collectionName: json['collection_name'],
          dateTime: DateTime.parse(json['date_time']),
          isCompleted: json['is_completed'] ?? false,
          itemId: json['item_id'],
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();

      final remoteIds = remoteReminders.map((r) => r.id).toSet();

      // 3. Fetch local reminders
      final localRepo = _getLocalReminderRepository();
      if (localRepo == null) return;

      final localReminders = await localRepo.getReminders(email);

      // 4. Remote → Local
      for (final remoteRem in remoteReminders) {
        final localIndex = localReminders.indexWhere((r) => toUuid(r.id) == remoteRem.id);
        if (localIndex == -1) {
          await localRepo.addReminder(email, remoteRem);
          _remindersSynced++;
        } else {
          final localRem = localReminders[localIndex];
          if (remoteRem.updatedAt.isAfter(localRem.updatedAt)) {
            final updated = Reminder(
              id: localRem.id,
              title: remoteRem.title,
              collectionName: remoteRem.collectionName,
              dateTime: remoteRem.dateTime,
              isCompleted: remoteRem.isCompleted,
              itemId: localRem.itemId,
              updatedAt: remoteRem.updatedAt,
            );
            await localRepo.updateReminder(email, updated);
            _remindersSynced++;
          } else if (localRem.updatedAt.isAfter(remoteRem.updatedAt)) {
            await _pushReminderToCloud(localRem, userId, supabase);
            _remindersSynced++;
          }
        }
      }

      // 5. Preserve missing UUID reminders rather than assuming deletion.
      final currentLocalReminders = await localRepo.getReminders(email);
      final currentPending = prefs.getStringList(deletionKey) ?? [];

      for (final localRem in currentLocalReminders) {
        final existsInRemote = remoteIds.contains(toUuid(localRem.id));
        final isPending = currentPending.contains(localRem.id);
        if (!existsInRemote && !isPending) {
          final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(localRem.id);
          if (isUuid) {
            // Preserve unsynced UUID records when cloud results are empty.
            continue;
          } else {
            await _pushReminderToCloud(localRem, userId, supabase);
            _remindersSynced++;
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[SyncService] syncReminders error: $e\n$stack');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  //  PROFILE SYNC
  // ─────────────────────────────────────────────

  Future<void> syncProfile(String userId, SupabaseService supabase) async {
    try {
      await supabase.client.auth.refreshSession();
    } catch (e) {
      debugPrint('[SyncService] syncProfile error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  //  HELPERS — Cloud push operations
  // ─────────────────────────────────────────────

  Future<void> _pushItemToCloud(
    VaultItem item,
    String userId,
    SupabaseService supabase, {
    required bool isTrash,
  }) async {
    final itemId = toUuid(item.id);
    try {
      await supabase.client.from('items').upsert({
        'id': itemId,
        'user_id': userId,
        'title': item.title,
        'type': item.type,
        'content': item.content,
        'collection_name': item.collectionName,
        'category': item.category,
        'is_trash': isTrash,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      });

      // Sync tags
      await _syncItemTags(itemId, item.tags, userId, supabase);

      // Sync favorites
      final isFav = item.tags.any((t) => t.toLowerCase() == 'favorite' || t.toLowerCase() == 'fav');
      if (isFav) {
        final favId = toUuid('${userId}_$itemId');
        await supabase.client.from('favorites').upsert({
          'id': favId,
          'user_id': userId,
          'item_id': itemId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await supabase.client
            .from('favorites')
            .delete()
            .eq('item_id', itemId)
            .eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('[SyncService] _pushItemToCloud error: $e');
    }
  }

  Future<void> _syncItemTags(
    String itemId,
    List<String> tags,
    String userId,
    SupabaseService supabase,
  ) async {
    try {
      final tagIds = <String, String>{};
      for (final tagName in tags) {
        final cleanName = tagName.trim();
        if (cleanName.isEmpty) continue;
        final tagId = toUuid('${userId}_$cleanName');
        await supabase.client.from('tags').upsert({
          'id': tagId,
          'user_id': userId,
          'name': cleanName,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        tagIds[cleanName] = tagId;
      }

      await supabase.client
          .from('item_tags')
          .delete()
          .eq('item_id', itemId)
          .eq('user_id', userId);

      for (final entry in tagIds.entries) {
        final linkId = toUuid('${itemId}_${entry.value}');
        await supabase.client.from('item_tags').upsert({
          'id': linkId,
          'user_id': userId,
          'item_id': itemId,
          'tag_id': entry.value,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  Future<void> _pushCollectionToCloud(
    Collection col,
    String userId,
    SupabaseService supabase,
  ) async {
    try {
      await supabase.client.from('collections').upsert({
        'id': toUuid(col.id),
        'user_id': userId,
        'name': col.name,
        'description': col.description,
        'created_at': col.createdAt.toIso8601String(),
        'updated_at': col.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SyncService] _pushCollectionToCloud error: $e');
    }
  }

  Future<void> _pushReminderToCloud(
    Reminder rem,
    String userId,
    SupabaseService supabase,
  ) async {
    try {
      await supabase.client.from('reminders').upsert({
        'id': toUuid(rem.id),
        'user_id': userId,
        'title': rem.title,
        'collection_name': rem.collectionName,
        'date_time': rem.dateTime.toIso8601String(),
        'is_completed': rem.isCompleted,
        'item_id': rem.itemId != null ? toUuid(rem.itemId!) : null,
        'created_at': rem.dateTime.toIso8601String(),
        'updated_at': rem.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SyncService] _pushReminderToCloud error: $e');
    }
  }

  Future<void> _deleteItemStorageIfNeeded(
    String id,
    String userId,
    SupabaseService supabase,
    SharedPreferences prefs,
    String email,
  ) async {
    try {
      // Attempt to clean up storage for file/image items
      // This is best-effort; the Postgres CASCADE handles relational cleanup
      await CacheManager.instance.removeFile(id);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  //  HELPERS — Local repository access
  // ─────────────────────────────────────────────

  ItemRepository? _getLocalItemRepository() {
    try {
      return _ref?.read(localItemRepositoryProvider);
    } catch (_) {
      return null;
    }
  }

  CollectionRepository? _getLocalCollectionRepository() {
    try {
      return _ref?.read(localCollectionRepositoryProvider);
    } catch (_) {
      return null;
    }
  }

  ReminderRepository? _getLocalReminderRepository() {
    try {
      return _ref?.read(localReminderRepositoryProvider);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stopPeriodicSync();
    _ref = null;
    _currentEmail = null;
    _restoreGeneration++;
  }
}
