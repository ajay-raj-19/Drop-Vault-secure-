import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// Manages local caching of remote Supabase files/images with LRU eviction.
class CacheManager {
  static final CacheManager instance = CacheManager._internal();
  CacheManager._internal();

  static const String _cacheFolder = 'drop_vault_cache';
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50 MB limit
  static const int _targetCacheSize = 30 * 1024 * 1024; // Reduce to 30 MB on eviction

  Future<Directory> get _getCacheDir async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/$_cacheFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _getFileName(String url) {
    // Generate a deterministic filename using the MD5 hash of the URL
    final bytes = utf8.encode(url);
    final hash = md5.convert(bytes).toString();
    final urlPath = url.split('?').first;
    final extension = urlPath.contains('.') ? urlPath.split('.').last : 'bin';
    // Validate extension length to avoid queries / garbage path segments
    final cleanExtension = extension.length > 5 ? 'bin' : extension;
    return '$hash.$cleanExtension';
  }

  /// Retrieves a cached file by its remote URL if it exists, updating its access timestamp.
  Future<File?> getFile(String url) async {
    try {
      final dir = await _getCacheDir;
      final fileName = _getFileName(url);
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        // Update last modified timestamp to mark it as recently used (LRU)
        await file.setLastModified(DateTime.now());
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Saves the download stream bytes as a cached file and triggers eviction if limit is exceeded.
  Future<File> saveFile(String url, List<int> bytes) async {
    final dir = await _getCacheDir;
    final fileName = _getFileName(url);
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // Run eviction process asynchronously to avoid blocking the main stream
    _performEvictionIfNeeded();

    return file;
  }

  /// Deletes a file from the local cache folder.
  Future<void> removeFile(String url) async {
    try {
      final dir = await _getCacheDir;
      final fileName = _getFileName(url);
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Wipes all files in the cache folder.
  Future<void> clearCache() async {
    try {
      final dir = await _getCacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _performEvictionIfNeeded() async {
    try {
      final dir = await _getCacheDir;
      final entities = await dir.list(recursive: false).toList();
      final files = entities.whereType<File>().toList();

      var totalSize = 0;
      final fileStats = <_FileStat>[];

      for (final file in files) {
        final size = await file.length();
        totalSize += size;
        final lastModified = await file.lastModified();
        fileStats.add(_FileStat(file, size, lastModified));
      }

      if (totalSize > _maxCacheSize) {
        // Sort files by last accessed time (oldest first)
        fileStats.sort((a, b) => a.lastModified.compareTo(b.lastModified));

        for (final stat in fileStats) {
          if (totalSize <= _targetCacheSize) break;
          try {
            await stat.file.delete();
            totalSize -= stat.size;
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}

class _FileStat {
  final File file;
  final int size;
  final DateTime lastModified;

  _FileStat(this.file, this.size, this.lastModified);
}
