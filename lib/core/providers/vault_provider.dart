import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'providers.dart';

class VaultNotifier extends StateNotifier<List<VaultItem>> {
  final ItemRepository _repository;
  final String _email;
  final bool _isTrash;

  VaultNotifier(this._repository, {required String email, required bool isTrash})
      : _email = email,
        _isTrash = isTrash,
        super([]) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    final list = _isTrash
        ? await _repository.getTrashItems(_email)
        : await _repository.getItems(_email);
    state = list;
  }

  Future<void> addItem(VaultItem item) async {
    if (_isTrash) {
      await _repository.addTrashItem(_email, item);
    } else {
      await _repository.addItem(_email, item);
    }
    state = [...state, item];
  }

  Future<void> deleteItem(String id) async {
    if (_isTrash) {
      await _repository.deleteTrashItem(_email, id);
    } else {
      await _repository.deleteItem(_email, id);
    }
    state = state.where((item) => item.id != id).toList();
  }

  Future<void> reloadItems() async {
    await _loadItems();
  }

  Future<void> updateItem(VaultItem updatedItem) async {
    if (_isTrash) {
      await _repository.deleteTrashItem(_email, updatedItem.id);
      await _repository.addTrashItem(_email, updatedItem);
    } else {
      await _repository.updateItem(_email, updatedItem);
    }
    state = state.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
  }

  Future<void> renameCollectionInItems(String oldName, String newName) async {
    if (!_isTrash) {
      await _repository.renameCollectionInItems(_email, oldName, newName);
      state = state.map((item) {
        if (item.collectionName == oldName) {
          return VaultItem(
            id: item.id,
            title: item.title,
            type: item.type,
            content: item.content,
            collectionName: newName,
            createdAt: item.createdAt,
            tags: item.tags,
            category: item.category,
          );
        }
        return item;
      }).toList();
    }
  }

  Future<void> deleteItemsInCollection(String collectionName) async {
    if (!_isTrash) {
      await _repository.deleteItemsInCollection(_email, collectionName);
      state = state.where((item) => item.collectionName != collectionName).toList();
    }
  }

  Future<void> trashItem(VaultItem item, VaultNotifier trashNotifier, ReminderNotifier reminderNotifier, [UndoNotifier? undoNotifier]) async {
    await trashNotifier.addItem(item);
    await deleteItem(item.id);
    final reminders = reminderNotifier.state;
    final deletedReminders = <Reminder>[];
    for (final r in reminders) {
      if (r.itemId == item.id) {
        deletedReminders.add(r);
        await reminderNotifier.deleteReminder(r.id);
      }
    }
    if (undoNotifier != null) {
      undoNotifier.pushUndo(item, deletedReminders);
    }
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, List<VaultItem>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return VaultNotifier(repository, email: email, isTrash: false);
});

final trashProvider = StateNotifierProvider<VaultNotifier, List<VaultItem>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return VaultNotifier(repository, email: email, isTrash: true);
});
