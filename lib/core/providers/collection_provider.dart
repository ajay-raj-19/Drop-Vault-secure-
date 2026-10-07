import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'providers.dart';

class CollectionNotifier extends StateNotifier<List<Collection>> {
  final CollectionRepository _repository;
  final String _email;

  CollectionNotifier(this._repository, {required String email}) : _email = email, super([]) {
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final list = await _repository.getCollections(_email);
    state = list;
  }

  Future<void> reloadCollections() async {
    await _loadCollections();
  }

  Future<void> addCollection(Collection collection) async {
    await _repository.addCollection(_email, collection);
    state = [...state, collection];
  }

  Future<void> createCollection(String name, {String description = ''}) async {
    final newCol = Collection(
      id: 'col-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    await addCollection(newCol);
  }

  Future<void> deleteCollection(String id) async {
    debugPrint('=== UI DELETE ACTION ===');
    debugPrint('Collection ID: $id');
    
    // 1. Immediately remove from local UI
    state = state.where((col) => col.id != id).toList();
    debugPrint('UI Updated: Removed $id from state');
    
    // 2. Process cache and cloud deletions
    await _repository.deleteCollection(_email, id);
    
    debugPrint('========================');
  }

  Future<void> updateCollection(Collection updatedCol) async {
    await _repository.updateCollection(_email, updatedCol);
    state = state.map((col) => col.id == updatedCol.id ? updatedCol : col).toList();
  }

  Future<void> trashCollection(Collection collection, List<VaultItem> items, VaultNotifier trashNotifier, VaultNotifier vaultNotifier, ReminderNotifier reminderNotifier) async {
    final trashedColItem = VaultItem(
      id: 'col-trash-${collection.id}',
      title: collection.name,
      type: 'collection',
      content: jsonEncode(collection.toJson()),
      collectionName: '',
      createdAt: DateTime.now(),
    );
    await trashNotifier.addItem(trashedColItem);

    final itemsInCol = items.where((item) => item.collectionName == collection.name).toList();
    for (final item in itemsInCol) {
      await trashNotifier.addItem(item);
      await vaultNotifier.deleteItem(item.id);
      final reminders = reminderNotifier.state;
      for (final r in reminders) {
        if (r.itemId == item.id) {
          await reminderNotifier.deleteReminder(r.id);
        }
      }
    }

    await deleteCollection(collection.id);
  }
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, List<Collection>>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  // Rebuild whenever a sync completes
  ref.watch(syncTriggerProvider);
  return CollectionNotifier(repository, email: email);
});
