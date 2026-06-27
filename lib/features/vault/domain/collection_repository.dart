import '../../../../core/models/collection.dart';

abstract class CollectionRepository {
  Future<List<Collection>> getCollections(String email);
  Future<void> addCollection(String email, Collection collection);
  Future<void> updateCollection(String email, Collection collection);
  Future<void> deleteCollection(String email, String id);
}
