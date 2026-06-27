import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/collection_repository.dart';
import '../../../../core/models/collection.dart';

class LocalCollectionRepository implements CollectionRepository {
  final SharedPreferences _prefs;

  LocalCollectionRepository(this._prefs);

  String _getKey(String email) => 'collections_$email';

  @override
  Future<List<Collection>> getCollections(String email) async {
    final list = _prefs.getStringList(_getKey(email));
    if (list != null) {
      return list
          .map((itemStr) => Collection.fromJson(jsonDecode(itemStr)))
          .where((col) => !['col-1', 'col-2', 'col-3', 'col-4'].contains(col.id))
          .toList();
    }
    return [];
  }

  @override
  Future<void> addCollection(String email, Collection collection) async {
    final collections = await getCollections(email);
    collections.add(collection);
    await _save(email, collections);
  }

  @override
  Future<void> updateCollection(String email, Collection collection) async {
    final collections = await getCollections(email);
    final index = collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      collections[index] = collection;
      await _save(email, collections);
    }
  }

  @override
  Future<void> deleteCollection(String email, String id) async {
    final collections = await getCollections(email);
    collections.removeWhere((c) => c.id == id);
    await _save(email, collections);
  }

  Future<void> _save(String email, List<Collection> collections) async {
    final list = collections.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_getKey(email), list);
  }
}
