import '../../../../core/models/vault_item.dart';

abstract class ItemRepository {
  Future<List<VaultItem>> getItems(String email);
  Future<void> addItem(String email, VaultItem item);
  Future<void> updateItem(String email, VaultItem item);
  Future<void> deleteItem(String email, String id);

  Future<List<VaultItem>> getTrashItems(String email);
  Future<void> addTrashItem(String email, VaultItem item);
  Future<void> deleteTrashItem(String email, String id);

  Future<void> renameCollectionInItems(String email, String oldName, String newName);
  Future<void> deleteItemsInCollection(String email, String collectionName);
}
