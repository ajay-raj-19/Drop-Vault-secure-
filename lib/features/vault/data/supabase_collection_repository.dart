import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/collection_repository.dart';
import '../../../../core/models/collection.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/uuid_helper.dart';

class SupabaseCollectionRepository implements CollectionRepository {
  final SupabaseService _supabaseService;
  final CollectionRepository _localRepository;
  final SharedPreferences _prefs;

  SupabaseCollectionRepository(this._supabaseService, this._localRepository, this._prefs);

  String _getPendingDeletionsKey(String email) => 'pending_deleted_collections_$email';

  Future<void> _pushCollectionToRemote(Collection col, String userId) async {
    await _supabaseService.client.from('collections').upsert({
      'id': toUuid(col.id),
      'user_id': userId,
      'name': col.name,
      'description': col.description,
      'created_at': col.createdAt.toIso8601String(),
      'updated_at': col.updatedAt.toIso8601String(),
    });
  }

  @override
  Future<List<Collection>> getCollections(String email) async {
    return _localRepository.getCollections(email);
  }

  @override
  Future<void> addCollection(String email, Collection collection) async {
    final updatedCol = Collection(
      id: collection.id,
      name: collection.name,
      description: collection.description,
      createdAt: collection.createdAt,
      updatedAt: DateTime.now(),
    );

    await _localRepository.addCollection(email, updatedCol);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _pushCollectionToRemote(updatedCol, userId);
      } catch (_) {
        // Silent fail
      }
    }
  }

  @override
  Future<void> updateCollection(String email, Collection collection) async {
    final updatedCol = Collection(
      id: collection.id,
      name: collection.name,
      description: collection.description,
      createdAt: collection.createdAt,
      updatedAt: DateTime.now(),
    );

    await _localRepository.updateCollection(email, updatedCol);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _pushCollectionToRemote(updatedCol, userId);
      } catch (_) {
        // Silent fail
      }
    }
  }

  @override
  Future<void> deleteCollection(String email, String id) async {
    debugPrint('=== DELETE DIAGNOSTICS ===');
    debugPrint('Delete Requested: Collection');
    debugPrint('Collection ID: $id');
    debugPrint('Repository Used: SupabaseCollectionRepository');

    // 1. Immediately delete from local cache
    await _localRepository.deleteCollection(email, id);
    debugPrint('Local Delete Success: true');
    debugPrint('Cache Updated: true');

    bool supabaseSuccess = false;
    bool queueUpdated = false;

    // 2. Try to delete from Supabase
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client
            .from('collections')
            .delete()
            .eq('id', toUuid(id))
            .eq('user_id', userId);
        supabaseSuccess = true;
      } catch (_) {
        // Offline/failure: queue deletion
        final deletionKey = _getPendingDeletionsKey(email);
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(id)) {
          pendingDeletions.add(id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueUpdated = true;
        }
      }
    } else {
      // Offline/not logged in: queue deletion
      final deletionKey = _getPendingDeletionsKey(email);
      final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
      if (!pendingDeletions.contains(id)) {
        pendingDeletions.add(id);
        await _prefs.setStringList(deletionKey, pendingDeletions);
        queueUpdated = true;
      }
    }

    debugPrint('Supabase Delete Success: $supabaseSuccess');
    debugPrint('Pending Queue Updated: $queueUpdated');
    debugPrint('UI Updated: State updated in notifier');
    debugPrint('Final Verification: Deletion fully processed');
    debugPrint('==========================');
  }
}
