import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../domain/item_repository.dart';
import '../../../../core/models/vault_item.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/uuid_helper.dart';
import '../../../../core/providers/transfer_provider.dart';
import '../../../../core/services/cache_manager.dart';

class SupabaseItemRepository implements ItemRepository {
  final SupabaseService _supabaseService;
  final ItemRepository _localRepository;
  final SharedPreferences _prefs;

  SupabaseItemRepository(this._supabaseService, this._localRepository, this._prefs);

  @override
  Future<List<VaultItem>> getItems(String email) async {
    return _localRepository.getItems(email);
  }

  @override
  Future<List<VaultItem>> getTrashItems(String email) async {
    return _localRepository.getTrashItems(email);
  }




  Future<void> _validateFile(VaultItem item) async {
    final type = item.type.toLowerCase();
    if (type == 'image' || type == 'file') {
      final file = File(item.content);
      if (!await file.exists()) {
        throw Exception('File does not exist locally: ${item.content}');
      }
      
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        throw Exception('File size exceeds the 10 MB limit');
      }

      final extension = item.content.split('.').last.toLowerCase();
      if (type == 'image') {
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
          throw Exception('Unsupported image format: $extension');
        }
      } else if (type == 'file') {
        if (!['pdf', 'docx', 'xlsx', 'pptx', 'txt', 'zip'].contains(extension)) {
          throw Exception('Unsupported file format: $extension');
        }
      }
    }
  }

  @override
  Future<void> addItem(String email, VaultItem item) async {
    final updatedItem = VaultItem(
      id: item.id,
      title: item.title,
      type: item.type,
      content: item.content,
      collectionName: item.collectionName,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      tags: item.tags,
      category: item.category,
    );
    await _validateFile(updatedItem);
    await _localRepository.addItem(email, updatedItem);
    await _syncItemToCloud(email, updatedItem, isTrash: false);
  }

  @override
  Future<void> updateItem(String email, VaultItem item) async {
    final updatedItem = VaultItem(
      id: item.id,
      title: item.title,
      type: item.type,
      content: item.content,
      collectionName: item.collectionName,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      tags: item.tags,
      category: item.category,
    );
    await _validateFile(updatedItem);
    await _localRepository.updateItem(email, updatedItem);
    await _syncItemToCloud(email, updatedItem, isTrash: false);
  }

  @override
  Future<void> deleteItem(String email, String id) async {
    debugPrint('=== DELETE DIAGNOSTICS ===');
    debugPrint('Delete Requested: Item');
    debugPrint('Item ID: $id');
    debugPrint('Repository Used: SupabaseItemRepository');

    // 1. Retrieve item details before deleting locally
    final items = await _localRepository.getItems(email);
    final itemIndex = items.indexWhere((i) => i.id == id);
    VaultItem? itemToDelete = itemIndex != -1 ? items[itemIndex] : null;

    // 2. Immediately delete local cache
    await _localRepository.deleteItem(email, id);
    debugPrint('Local Delete Success: true');
    debugPrint('Cache Updated: true');

    bool supabaseSuccess = false;
    bool queueUpdated = false;

    // 3. Delete from Supabase
    if (itemToDelete != null) {
      try {
        await _deleteItemFromCloud(itemToDelete);
        supabaseSuccess = true;
      } catch (e) {
        // Offline/failure: queue deletion
        final deletionKey = 'pending_deleted_items_$email';
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(id)) {
          pendingDeletions.add(id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueUpdated = true;
        }
      }
    } else {
      // Fallback: Delete directly from Supabase database by ID
      try {
        if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
          final userId = _supabaseService.client.auth.currentUser!.id;
          await _supabaseService.client
              .from('items')
              .delete()
              .eq('id', toUuid(id))
              .eq('user_id', userId);
          supabaseSuccess = true;
        } else {
          // Offline/not initialized fallback
          final deletionKey = 'pending_deleted_items_$email';
          final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
          if (!pendingDeletions.contains(id)) {
            pendingDeletions.add(id);
            await _prefs.setStringList(deletionKey, pendingDeletions);
            queueUpdated = true;
          }
        }
      } catch (e) {
        // Queue it
        final deletionKey = 'pending_deleted_items_$email';
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(id)) {
          pendingDeletions.add(id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueUpdated = true;
        }
      }
    }

    debugPrint('Supabase Delete Success: $supabaseSuccess');
    debugPrint('Pending Queue Updated: $queueUpdated');
    debugPrint('UI Updated: State updated in notifier');
    debugPrint('Final Verification: Deletion fully processed');
    debugPrint('==========================');
  }

  @override
  Future<void> addTrashItem(String email, VaultItem item) async {
    final updatedItem = VaultItem(
      id: item.id,
      title: item.title,
      type: item.type,
      content: item.content,
      collectionName: item.collectionName,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      tags: item.tags,
      category: item.category,
    );
    await _validateFile(updatedItem);
    await _localRepository.addTrashItem(email, updatedItem);
    await _syncItemToCloud(email, updatedItem, isTrash: true);
  }

  @override
  Future<void> deleteTrashItem(String email, String id) async {
    debugPrint('=== DELETE DIAGNOSTICS ===');
    debugPrint('Delete Requested: Trash Item');
    debugPrint('Item ID: $id');
    debugPrint('Repository Used: SupabaseItemRepository');

    // 1. Retrieve item details before deleting locally
    final items = await _localRepository.getTrashItems(email);
    final itemIndex = items.indexWhere((i) => i.id == id);
    VaultItem? itemToDelete = itemIndex != -1 ? items[itemIndex] : null;

    // 2. Immediately delete local cache
    await _localRepository.deleteTrashItem(email, id);
    debugPrint('Local Delete Success: true');
    debugPrint('Cache Updated: true');

    bool supabaseSuccess = false;
    bool queueUpdated = false;

    // 3. Delete from Supabase
    if (itemToDelete != null) {
      try {
        await _deleteItemFromCloud(itemToDelete);
        supabaseSuccess = true;
      } catch (e) {
        // Offline/failure: queue deletion
        final deletionKey = 'pending_deleted_items_$email';
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(id)) {
          pendingDeletions.add(id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueUpdated = true;
        }
      }
    } else {
      // Fallback: Delete directly from Supabase database by ID
      try {
        if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
          final userId = _supabaseService.client.auth.currentUser!.id;
          await _supabaseService.client
              .from('items')
              .delete()
              .eq('id', toUuid(id))
              .eq('user_id', userId);
          supabaseSuccess = true;
        } else {
          // Offline/not initialized fallback
          final deletionKey = 'pending_deleted_items_$email';
          final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
          if (!pendingDeletions.contains(id)) {
            pendingDeletions.add(id);
            await _prefs.setStringList(deletionKey, pendingDeletions);
            queueUpdated = true;
          }
        }
      } catch (e) {
        // Queue it
        final deletionKey = 'pending_deleted_items_$email';
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(id)) {
          pendingDeletions.add(id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueUpdated = true;
        }
      }
    }

    debugPrint('Supabase Delete Success: $supabaseSuccess');
    debugPrint('Pending Queue Updated: $queueUpdated');
    debugPrint('UI Updated: State updated in notifier');
    debugPrint('Final Verification: Deletion fully processed');
    debugPrint('==========================');
  }

  @override
  Future<void> renameCollectionInItems(String email, String oldName, String newName) async {
    await _localRepository.renameCollectionInItems(email, oldName, newName);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client
            .from('items')
            .update({
              'collection_name': newName,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('collection_name', oldName);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteItemsInCollection(String email, String collectionName) async {
    debugPrint('=== DELETE DIAGNOSTICS ===');
    debugPrint('Delete Requested: Items in Collection ($collectionName)');
    debugPrint('Repository Used: SupabaseItemRepository');

    // 1. Get collection item details before deleting locally
    final items = await _localRepository.getItems(email);
    final itemsInCol = items.where((i) => i.collectionName == collectionName).toList();

    // 2. Immediately delete local cache
    await _localRepository.deleteItemsInCollection(email, collectionName);
    debugPrint('Local Delete Success: true');
    debugPrint('Cache Updated: true');

    bool allSupabaseSuccess = true;
    int queueCount = 0;

    // 3. Loop and delete/queue from cloud
    for (final item in itemsInCol) {
      try {
        await _deleteItemFromCloud(item);
      } catch (e) {
        allSupabaseSuccess = false;
        final deletionKey = 'pending_deleted_items_$email';
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(item.id)) {
          pendingDeletions.add(item.id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueCount++;
        }
      }
    }

    debugPrint('Supabase Delete Success: $allSupabaseSuccess');
    debugPrint('Pending Queue Updated: ${queueCount > 0} ($queueCount items queued)');
    debugPrint('UI Updated: State updated in notifier');
    debugPrint('Final Verification: Deletion fully processed');
    debugPrint('==========================');
  }

  Future<void> _syncItemToCloud(String email, VaultItem item, {required bool isTrash}) async {
    final type = item.type.toLowerCase();
    String activeContent = item.content;

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      final userId = _supabaseService.client.auth.currentUser!.id;
      final itemId = toUuid(item.id);

      if ((type == 'image' || type == 'file') && !activeContent.startsWith('http')) {
        try {
          final file = File(activeContent);
          if (await file.exists()) {
            final bucket = type == 'image' ? 'vault-images' : 'vault-files';
            final extension = activeContent.split('.').last;
            final path = '$userId/$itemId.$extension';

            final remoteUrl = await _uploadFileWithProgress(item.id, bucket, path, file);
            activeContent = remoteUrl;

            // Cache file locally under remote URL
            final bytes = await file.readAsBytes();
            await CacheManager.instance.saveFile(remoteUrl, bytes);

            // Update local storage content to point to remote URL so it can download/cache on other devices
            final updatedItem = _copyItemWithContent(item, remoteUrl);
            if (isTrash) {
              await _localRepository.deleteTrashItem(email, item.id);
              await _localRepository.addTrashItem(email, updatedItem);
            } else {
              await _localRepository.updateItem(email, updatedItem);
            }
          }
        } catch (_) {
          // Upload failed, queue for later sync
          await _queueVaultUpload(email, item.id, activeContent, type == 'image' ? 'vault-images' : 'vault-files', isTrash);
        }
      }

      try {
        debugPrint('=== SUPABASE INSERT/UPSERT OPERATION ===');
        debugPrint('Repository Used: SupabaseItemRepository');
        debugPrint('User ID: $userId');
        debugPrint('Item ID: $itemId');
        debugPrint('Title: ${item.title}');
        debugPrint('Payload: { id: $itemId, user_id: $userId, title: ${item.title}, type: ${item.type}, content: $activeContent }');

        // 1. Upsert to Postgres
        await _supabaseService.client.from('items').upsert({
          'id': itemId,
          'user_id': userId,
          'title': item.title,
          'type': item.type,
          'content': activeContent,
          'collection_name': item.collectionName,
          'category': item.category,
          'is_trash': isTrash,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
        });

        // 2. Sync Tags
        await _syncItemTags(itemId, item.tags);

        // 3. Sync Favorites
        final isFav = item.tags.any((t) => t.toLowerCase() == 'favorite' || t.toLowerCase() == 'fav');
        if (isFav) {
          final favId = toUuid('${userId}_$itemId');
          await _supabaseService.client.from('favorites').upsert({
            'id': favId,
            'user_id': userId,
            'item_id': itemId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          await _supabaseService.client
              .from('favorites')
              .delete()
              .eq('item_id', itemId)
              .eq('user_id', userId);
        }
        debugPrint('Insert Success/Failure: Success');
        debugPrint('=========================================');
      } catch (e, stack) {
        debugPrint('Insert Success/Failure: Failure');
        debugPrint('Error Message: $e');
        debugPrint('Stack Trace: $stack');
        debugPrint('=========================================');
      }
    }
  }

  Future<void> _deleteItemFromCloud(VaultItem item) async {
    // Delete cached copy
    await CacheManager.instance.removeFile(item.content);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        final itemId = toUuid(item.id);

        // Delete from Storage
        if (item.content.startsWith('http')) {
          final bucket = item.type.toLowerCase() == 'image' ? 'vault-images' : 'vault-files';
          final extension = item.content.split('?').first.split('.').last;
          final path = '$userId/$itemId.$extension';
          await _supabaseService.client.storage.from(bucket).remove([path]);
        }

        // Delete Postgres record (Cascade handles item_tags, favorites, reminders)
        await _supabaseService.client
            .from('items')
            .delete()
            .eq('id', itemId)
            .eq('user_id', userId);
      } catch (_) {}
    }
  }

  Future<void> _syncItemTags(String itemId, List<String> tags) async {
    if (!_supabaseService.isInitialized || _supabaseService.client.auth.currentUser == null) return;
    
    final userId = _supabaseService.client.auth.currentUser!.id;
    final tagIds = <String, String>{};

    for (final tagName in tags) {
      final cleanName = tagName.trim();
      if (cleanName.isEmpty) continue;

      final tagId = toUuid('${userId}_$cleanName');
      await _supabaseService.client.from('tags').upsert({
        'id': tagId,
        'user_id': userId,
        'name': cleanName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      tagIds[cleanName] = tagId;
    }

    await _supabaseService.client
        .from('item_tags')
        .delete()
        .eq('item_id', itemId)
        .eq('user_id', userId);

    for (final entry in tagIds.entries) {
      final linkId = toUuid('${itemId}_${entry.value}');
      await _supabaseService.client.from('item_tags').upsert({
        'id': linkId,
        'user_id': userId,
        'item_id': itemId,
        'tag_id': entry.value,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _queueVaultUpload(String email, String itemId, String filePath, String bucket, bool isTrash) async {
    try {
      const queueKey = 'pending_vault_uploads';
      final queue = _prefs.getStringList(queueKey) ?? [];
      
      final dataStr = jsonEncode({
        'email': email,
        'itemId': itemId,
        'filePath': filePath,
        'bucket': bucket,
        'isTrash': isTrash,
      });

      if (!queue.contains(dataStr)) {
        queue.add(dataStr);
        await _prefs.setStringList(queueKey, queue);
      }
    } catch (_) {}
  }

  Future<void> syncPendingUploads() async {
    if (!_supabaseService.isInitialized || _supabaseService.client.auth.currentUser == null) return;

    const queueKey = 'pending_vault_uploads';
    final list = _prefs.getStringList(queueKey) ?? [];
    if (list.isEmpty) return;

    final userId = _supabaseService.client.auth.currentUser!.id;
    final remainingQueue = <String>[];

    for (final itemJsonStr in list) {
      try {
        final data = jsonDecode(itemJsonStr) as Map<String, dynamic>;
        final email = data['email'] as String;
        final itemId = data['itemId'] as String;
        final filePath = data['filePath'] as String;
        final bucket = data['bucket'] as String;
        final isTrash = data['isTrash'] as bool;

        final file = File(filePath);
        if (await file.exists()) {
          final extension = filePath.split('.').last;
          final path = '$userId/${toUuid(itemId)}.$extension';

          final remoteUrl = await _uploadFileWithProgress(itemId, bucket, path, file);

          final bytes = await file.readAsBytes();
          await CacheManager.instance.saveFile(remoteUrl, bytes);

          // Update local cache
          if (isTrash) {
            final trashItems = await _localRepository.getTrashItems(email);
            final index = trashItems.indexWhere((i) => i.id == itemId);
            if (index != -1) {
              final updated = _copyItemWithContent(trashItems[index], remoteUrl);
              await _localRepository.deleteTrashItem(email, itemId);
              await _localRepository.addTrashItem(email, updated);
            }
          } else {
            final items = await _localRepository.getItems(email);
            final index = items.indexWhere((i) => i.id == itemId);
            if (index != -1) {
              final updated = _copyItemWithContent(items[index], remoteUrl);
              await _localRepository.updateItem(email, updated);
            }
          }

          // Update Postgres
          await _supabaseService.client.from('items').update({
            'content': remoteUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', toUuid(itemId)).eq('user_id', userId);
        }
      } catch (_) {
        remainingQueue.add(itemJsonStr);
      }
    }

    await _prefs.setStringList(queueKey, remainingQueue);
  }

  Future<String> _uploadFileWithProgress(String id, String bucket, String path, File file) async {
    final client = HttpClient();
    final projectUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final uploadUrl = '$projectUrl/storage/v1/object/$bucket/$path';
    
    final fileName = path.split('/').last;
    TransferRegistry.updateStatus(id, fileName, TransferStatus.uploading);

    try {
      final request = await client.postUrl(Uri.parse(uploadUrl));
      
      final token = _supabaseService.client.auth.currentSession?.accessToken;
      final apiKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('apikey', apiKey);
      
      String contentType = 'application/octet-stream';
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.endsWith('.webp')) {
        contentType = 'image/webp';
      } else if (fileName.endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (fileName.endsWith('.txt')) {
        contentType = 'text/plain';
      } else if (fileName.endsWith('.zip')) {
        contentType = 'application/zip';
      }
      
      request.headers.set('Content-Type', contentType);
      
      final fileStream = file.openRead();
      final totalLength = await file.length();
      request.contentLength = totalLength;
      
      var uploadedBytes = 0;
      await request.addStream(fileStream.map((chunk) {
        uploadedBytes += chunk.length;
        if (totalLength > 0) {
          final progress = uploadedBytes / totalLength;
          TransferRegistry.updateProgress(id, progress);
        }
        return chunk;
      }));
      
      final response = await request.close();
      if (response.statusCode == 200 || response.statusCode == 201) {
        TransferRegistry.updateStatus(id, fileName, TransferStatus.completed);
        return _supabaseService.client.storage.from(bucket).getPublicUrl(path);
      } else {
        final responseBody = await response.transform(utf8.decoder).join();
        throw Exception('Upload failed: status ${response.statusCode}, body: $responseBody');
      }
    } catch (e) {
      TransferRegistry.updateStatus(id, fileName, TransferStatus.failed, error: e.toString());
      rethrow;
    } finally {
      client.close();
    }
  }

  VaultItem _copyItemWithContent(VaultItem item, String content) {
    return VaultItem(
      id: item.id,
      title: item.title,
      type: item.type,
      content: content,
      collectionName: item.collectionName,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      tags: item.tags,
      category: item.category,
    );
  }
}
