import 'dart:convert';
import 'dart:io';
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
    await syncPendingUploads();
    return _fetchItems(email, isTrash: false);
  }

  @override
  Future<List<VaultItem>> getTrashItems(String email) async {
    await syncPendingUploads();
    return _fetchItems(email, isTrash: true);
  }

  Future<List<VaultItem>> _fetchItems(String email, {required bool isTrash}) async {
    final localItems = isTrash
        ? await _localRepository.getTrashItems(email)
        : await _localRepository.getItems(email);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        final response = await _supabaseService.client
            .from('items')
            .select('*, item_tags(tags(name))')
            .eq('user_id', userId)
            .eq('is_trash', isTrash)
            .order('created_at', ascending: false);

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
            category: json['category'],
            tags: tagsList,
          );
        }).toList();

        // Sync local cache
        for (final item in remoteItems) {
          final localIndex = localItems.indexWhere((i) => toUuid(i.id) == item.id);
          if (localIndex == -1) {
            if (isTrash) {
              await _localRepository.addTrashItem(email, item);
            } else {
              await _localRepository.addItem(email, item);
            }
          } else {
            final localItem = localItems[localIndex];
            if (localItem.title != item.title ||
                localItem.content != item.content ||
                localItem.collectionName != item.collectionName ||
                localItem.category != item.category ||
                localItem.tags.length != item.tags.length) {
              
              if (isTrash) {
                await _localRepository.deleteTrashItem(email, localItem.id);
                await _localRepository.addTrashItem(email, item);
              } else {
                await _localRepository.updateItem(email, item);
              }
            }
          }
        }

        return isTrash
            ? await _localRepository.getTrashItems(email)
            : await _localRepository.getItems(email);
      } catch (_) {
        // Fall back silently to local cache
      }
    }

    return localItems;
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
    await _validateFile(item);
    await _localRepository.addItem(email, item);
    await _syncItemToCloud(email, item, isTrash: false);
  }

  @override
  Future<void> updateItem(String email, VaultItem item) async {
    await _validateFile(item);
    await _localRepository.updateItem(email, item);
    await _syncItemToCloud(email, item, isTrash: false);
  }

  @override
  Future<void> deleteItem(String email, String id) async {
    final items = await _localRepository.getItems(email);
    final itemIndex = items.indexWhere((i) => i.id == id);
    VaultItem? itemToDelete;
    if (itemIndex != -1) {
      itemToDelete = items[itemIndex];
    }

    await _localRepository.deleteItem(email, id);

    if (itemToDelete != null) {
      await _deleteItemFromCloud(itemToDelete);
    }
  }

  @override
  Future<void> addTrashItem(String email, VaultItem item) async {
    await _validateFile(item);
    await _localRepository.addTrashItem(email, item);
    await _syncItemToCloud(email, item, isTrash: true);
  }

  @override
  Future<void> deleteTrashItem(String email, String id) async {
    final items = await _localRepository.getTrashItems(email);
    final itemIndex = items.indexWhere((i) => i.id == id);
    VaultItem? itemToDelete;
    if (itemIndex != -1) {
      itemToDelete = items[itemIndex];
    }

    await _localRepository.deleteTrashItem(email, id);

    if (itemToDelete != null) {
      await _deleteItemFromCloud(itemToDelete);
    }
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
    final items = await _localRepository.getItems(email);
    final itemsInCol = items.where((i) => i.collectionName == collectionName).toList();

    await _localRepository.deleteItemsInCollection(email, collectionName);

    for (final item in itemsInCol) {
      await _deleteItemFromCloud(item);
    }
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
          'updated_at': DateTime.now().toIso8601String(),
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
      } catch (_) {
        // Fail silently offline
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
      tags: item.tags,
      category: item.category,
    );
  }
}
