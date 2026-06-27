import '../domain/collection_repository.dart';
import '../../../../core/models/collection.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/uuid_helper.dart';

class SupabaseCollectionRepository implements CollectionRepository {
  final SupabaseService _supabaseService;
  final CollectionRepository _localRepository;

  SupabaseCollectionRepository(this._supabaseService, this._localRepository);

  @override
  Future<List<Collection>> getCollections(String email) async {
    // 1. Fetch from local cache first
    final localCols = await _localRepository.getCollections(email);

    // 2. Try fetching from Supabase if online and authenticated
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        final response = await _supabaseService.client
            .from('collections')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: true);

        final remoteCols = (response as List).map((json) {
          return Collection(
            id: json['id'],
            name: json['name'],
            description: json['description'] ?? '',
            createdAt: DateTime.parse(json['created_at']),
          );
        }).toList();

        // Sync local cache with remote collections
        for (final col in remoteCols) {
          final localIndex = localCols.indexWhere((c) => toUuid(c.id) == col.id);
          if (localIndex == -1) {
            await _localRepository.addCollection(email, col);
          } else {
            // Check if name or description changed, update local cache
            final localCol = localCols[localIndex];
            if (localCol.name != col.name || localCol.description != col.description) {
              await _localRepository.updateCollection(email, col);
            }
          }
        }
        
        // Return latest state from local cache
        return await _localRepository.getCollections(email);
      } catch (_) {
        // Fall back to local list on network errors
      }
    }

    return localCols;
  }

  @override
  Future<void> addCollection(String email, Collection collection) async {
    // 1. Save locally first
    await _localRepository.addCollection(email, collection);

    // 2. Synchronize with Supabase if online
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('collections').upsert({
          'id': toUuid(collection.id),
          'user_id': userId,
          'name': collection.name,
          'description': collection.description,
          'created_at': collection.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Fail silently offline
      }
    }
  }

  @override
  Future<void> updateCollection(String email, Collection collection) async {
    // 1. Save locally first
    await _localRepository.updateCollection(email, collection);

    // 2. Synchronize with Supabase if online
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('collections').upsert({
          'id': toUuid(collection.id),
          'user_id': userId,
          'name': collection.name,
          'description': collection.description,
          'created_at': collection.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Fail silently offline
      }
    }
  }

  @override
  Future<void> deleteCollection(String email, String id) async {
    // 1. Delete locally first
    await _localRepository.deleteCollection(email, id);

    // 2. Synchronize with Supabase if online
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client
            .from('collections')
            .delete()
            .eq('id', toUuid(id))
            .eq('user_id', userId);
      } catch (_) {
        // Fail silently offline
      }
    }
  }
}
