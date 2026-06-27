import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/item_repository.dart';
import '../../../../core/models/vault_item.dart';

class LocalItemRepository implements ItemRepository {
  final SharedPreferences _prefs;

  LocalItemRepository(this._prefs);

  String _getItemsKey(String email) => 'vault_items_$email';
  String _getTrashKey(String email) => 'trash_items_$email';

  @override
  Future<List<VaultItem>> getItems(String email) async {
    final list = _prefs.getStringList(_getItemsKey(email));
    if (list != null) {
      return list.map((itemStr) => VaultItem.fromJson(jsonDecode(itemStr))).toList();
    }
    return [];
  }

  @override
  Future<void> addItem(String email, VaultItem item) async {
    final items = await getItems(email);
    items.add(item);
    await _saveItems(email, items);
  }

  @override
  Future<void> updateItem(String email, VaultItem item) async {
    final items = await getItems(email);
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await _saveItems(email, items);
    }
  }

  @override
  Future<void> deleteItem(String email, String id) async {
    final items = await getItems(email);
    items.removeWhere((i) => i.id == id);
    await _saveItems(email, items);
  }

  @override
  Future<List<VaultItem>> getTrashItems(String email) async {
    final list = _prefs.getStringList(_getTrashKey(email));
    if (list != null) {
      return list.map((itemStr) => VaultItem.fromJson(jsonDecode(itemStr))).toList();
    }
    return [];
  }

  @override
  Future<void> addTrashItem(String email, VaultItem item) async {
    final items = await getTrashItems(email);
    items.add(item);
    await _saveTrashItems(email, items);
  }

  @override
  Future<void> deleteTrashItem(String email, String id) async {
    final items = await getTrashItems(email);
    items.removeWhere((i) => i.id == id);
    await _saveTrashItems(email, items);
  }

  @override
  Future<void> renameCollectionInItems(String email, String oldName, String newName) async {
    final items = await getItems(email);
    final updated = items.map((item) {
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
    await _saveItems(email, updated);
  }

  @override
  Future<void> deleteItemsInCollection(String email, String collectionName) async {
    final items = await getItems(email);
    items.removeWhere((item) => item.collectionName == collectionName);
    await _saveItems(email, items);
  }

  Future<void> _saveItems(String email, List<VaultItem> items) async {
    final list = items.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_getItemsKey(email), list);
  }

  Future<void> _saveTrashItems(String email, List<VaultItem> items) async {
    final list = items.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_getTrashKey(email), list);
  }
}
