import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/transfer_provider.dart';
import '../../../core/services/cache_manager.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/desktop_file_service.dart';
import '../../../core/widgets/resizable_dialog.dart';
import '../../../core/widgets/desktop_sidebar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../backup/data/backup_service.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class CollectionItemsScreen extends ConsumerStatefulWidget {
  final String collectionName;

  const CollectionItemsScreen({super.key, required this.collectionName});

  @override
  ConsumerState<CollectionItemsScreen> createState() => _CollectionItemsScreenState();

  // --- Core Open Logic (Single Tap) ---
  static Future<void> openItemDirectly(BuildContext context, WidgetRef ref, VaultItem item) async {
    final type = item.type.toLowerCase();
    if (type == 'image') {
      showFullImagePreview(context, ref, item);
    } else if (type == 'link') {
      await launchURL(context, item.content);
    } else if (type == 'note') {
      context.push('/viewer/note', extra: item);
    } else if (type == 'file') {
      await openFileDirectly(context, ref, item);
    }
  }

  static Future<void> launchURL(BuildContext context, String urlString) async {
    final cleanUrl = urlString.trim();
    if (cleanUrl.isEmpty) return;
    
    // Add schema if not present
    var finalUrl = cleanUrl;
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      finalUrl = 'https://$cleanUrl';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final openBrowser = prefs.getBool('open_links_in_default_browser') ?? true;
      final mode = openBrowser ? LaunchMode.externalApplication : LaunchMode.platformDefault;
      
      final Uri url = Uri.parse(finalUrl);
      if (!await launchUrl(url, mode: mode)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link format'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<File?> downloadFileWithProgress({
    required String id,
    required String name,
    required String url,
    required SupabaseService supabaseService,
  }) async {
    final client = HttpClient();
    final downloadUrl = url.contains('/storage/v1/object/public/')
        ? url.replaceAll('/storage/v1/object/public/', '/storage/v1/object/authenticated/')
        : url;

    TransferRegistry.updateStatus(id, name, TransferStatus.downloading);

    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));

      if (supabaseService.isInitialized && supabaseService.client.auth.currentUser != null) {
        final token = supabaseService.client.auth.currentSession?.accessToken;
        final apiKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.set('apikey', apiKey);
      }

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$name');
      final fileSink = file.openWrite();

      final totalBytes = response.contentLength;
      int downloadedBytes = 0;

      await for (final chunk in response) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;
          TransferRegistry.updateProgress(id, progress);
        }
      }

      await fileSink.close();
      TransferRegistry.updateStatus(id, name, TransferStatus.completed);
      
      // Cache the file locally
      final fileBytes = await file.readAsBytes();
      await CacheManager.instance.saveFile(url, fileBytes);
      
      return file;
    } catch (e) {
      TransferRegistry.updateStatus(id, name, TransferStatus.failed, error: e.toString());
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<void> openFileDirectly(BuildContext context, WidgetRef ref, VaultItem item) async {
    final filePath = item.content;
    if (filePath.isEmpty) return;

    final isUrl = filePath.startsWith('http://') || filePath.startsWith('https://');
    if (!isUrl) {
      final file = File(filePath);
      if (await file.exists()) {
        final result = await OpenFilex.open(filePath);
        if (!context.mounted) return;
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local file does not exist. It may have been moved or deleted.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (!context.mounted) return;
    final supabaseService = ref.read(supabaseServiceProvider);
    
    // Show download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DownloadProgressDialog(id: item.id, title: item.title),
    );

    try {
      final file = await downloadFileWithProgress(
        id: item.id,
        name: item.title,
        url: filePath,
        supabaseService: supabaseService,
      );
      
      if (!context.mounted) return;
      Navigator.pop(context); // Close the dialog
      if (file != null) {
        final result = await OpenFilex.open(file.path);
        if (!context.mounted) return;
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static void showFullImagePreview(BuildContext context, WidgetRef ref, VaultItem item) {
    final isUrl = item.content.startsWith('http://') || item.content.startsWith('https://');
    final isLocal = !isUrl && item.content.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SwipeToDismissImageViewer(item: item, isUrl: isUrl, isLocal: isLocal),
      ),
    );
  }

  static void showItemLongPressBottomSheet(BuildContext context, WidgetRef ref, VaultItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(ctx);
              openItemDirectly(context, ref, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              showEditItemDialog(context, ref, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              showDeleteConfirmationDialog(context, ref, item);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static void showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, VaultItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Delete Item?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will move the item to the trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(vaultProvider.notifier).trashItem(
                item,
                ref.read(trashProvider.notifier),
                ref.read(reminderProvider.notifier),
                ref.read(undoProvider.notifier),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item moved to trash'), backgroundColor: Colors.orange),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static Future<void> showItemContextMenu(
    BuildContext context,
    WidgetRef ref,
    VaultItem item,
    Offset globalPosition,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFavorite = item.tags.any((t) => t.toLowerCase() == 'favorite' || t.toLowerCase() == 'fav');

    // For file explorer actions
    final isFile = item.type.toLowerCase() == 'file';
    final isUrl = item.content.startsWith('http://') || item.content.startsWith('https://');
    String? localFilePath;
    if (isFile) {
      if (!isUrl) {
        localFilePath = item.content;
      } else {
        final cached = await CacheManager.instance.getFile(item.content);
        if (cached != null) {
          localFilePath = cached.path;
        }
      }
    }

    final relativeRect = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx + 1,
      globalPosition.dy + 1,
    );

    if (!context.mounted) return;

    final selected = await showMenu<String>(
      context: context,
      position: relativeRect,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 18),
              SizedBox(width: 12),
              Text('Open'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 12),
              Text('Edit / Move'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'favorite',
          child: Row(
            children: [
              Icon(isFavorite ? Icons.star : Icons.star_border, size: 18),
              const SizedBox(width: 12),
              Text(isFavorite ? 'Remove Favorite' : 'Mark Favorite'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 12),
              Text('Copy Content/Link'),
            ],
          ),
        ),
        if (isFile && localFilePath != null) ...[
          const PopupMenuItem<String>(
            value: 'reveal',
            child: Row(
              children: [
                Icon(Icons.folder, size: 18),
                SizedBox(width: 12),
                Text('Reveal in Explorer'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'open_folder',
            child: Row(
              children: [
                Icon(Icons.folder_open, size: 18),
                SizedBox(width: 12),
                Text('Open Containing Folder'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'save_as',
            child: Row(
              children: [
                Icon(Icons.save_alt, size: 18),
                SizedBox(width: 12),
                Text('Save Copy As...'),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          textStyle: TextStyle(color: Colors.red),
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );

    if (selected == null || !context.mounted) return;

    switch (selected) {
      case 'open':
        await openItemDirectly(context, ref, item);
        break;
      case 'edit':
        showEditItemDialog(context, ref, item);
        break;
      case 'favorite':
        final List<String> updatedTags = List<String>.from(item.tags);
        if (isFavorite) {
          updatedTags.removeWhere((t) => t.toLowerCase() == 'favorite' || t.toLowerCase() == 'fav');
        } else {
          updatedTags.add('favorite');
        }
        final updatedItem = VaultItem(
          id: item.id,
          title: item.title,
          type: item.type,
          content: item.content,
          collectionName: item.collectionName,
          createdAt: item.createdAt,
          tags: updatedTags,
          category: item.category,
        );
        await ref.read(vaultProvider.notifier).updateItem(updatedItem);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: item.content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content copied to clipboard')),
          );
        }
        break;
      case 'reveal':
        if (localFilePath != null) {
          await DesktopFileService.revealFile(localFilePath);
        }
        break;
      case 'open_folder':
        if (localFilePath != null) {
          await DesktopFileService.openContainingFolder(localFilePath);
        }
        break;
      case 'save_as':
        if (localFilePath != null) {
          final saved = await DesktopFileService.saveAs(localFilePath, item.title);
          if (saved && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File copy saved successfully'), backgroundColor: Colors.green),
            );
          }
        }
        break;
      case 'delete':
        showDeleteConfirmationDialog(context, ref, item);
        break;
    }
  }

  static void showEditItemDialog(BuildContext context, WidgetRef ref, VaultItem item) {
    final titleController = TextEditingController(text: item.title);
    final contentController = TextEditingController(text: item.content);
    final tagsController = TextEditingController(text: item.tags.join(', '));
    final collections = ref.read(collectionProvider);
    String? selectedCollection = collections.any((c) => c.name == item.collectionName) ? item.collectionName : (collections.isNotEmpty ? collections.first.name : 'Personal Research');

    final String titleLabel;
    final String? contentLabel;
    final bool showContentField;

    if (item.type.toLowerCase() == 'link') {
      titleLabel = 'Title';
      contentLabel = 'URL';
      showContentField = true;
    } else if (item.type.toLowerCase() == 'note') {
      titleLabel = 'Title';
      contentLabel = 'Note Content';
      showContentField = true;
    } else if (item.type.toLowerCase() == 'file') {
      titleLabel = 'File Name';
      contentLabel = null;
      showContentField = false;
    } else if (item.type.toLowerCase() == 'image') {
      titleLabel = 'Image Name';
      contentLabel = null;
      showContentField = false;
    } else {
      titleLabel = 'Title';
      contentLabel = 'Content';
      showContentField = true;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> handleSave() async {
            final newTitle = titleController.text.trim();
            final newContent = showContentField ? contentController.text.trim() : item.content;
            final newTags = tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            if (newTitle.isNotEmpty) {
              Navigator.pop(ctx);
              final updatedItem = VaultItem(
                id: item.id,
                title: newTitle,
                type: item.type,
                content: newContent,
                collectionName: selectedCollection ?? item.collectionName,
                createdAt: item.createdAt,
                tags: newTags,
              );
              await ref.read(vaultProvider.notifier).updateItem(updatedItem);
            }
          }

          final isWindows = !kIsWeb && Platform.isWindows;
          
          final dialogContent = SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: titleLabel),
                ),
                if (showContentField && contentLabel != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: item.type.toLowerCase() == 'note' ? 5 : 1,
                    decoration: InputDecoration(labelText: contentLabel),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                ),
                const SizedBox(height: 16),
                const Text('Collection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCollection,
                  items: collections.isNotEmpty
                      ? collections.map((col) => DropdownMenuItem(value: col.name, child: Text(col.name))).toList()
                      : [DropdownMenuItem(value: item.collectionName, child: Text(item.collectionName))],
                  onChanged: (val) {
                    setState(() {
                      selectedCollection = val;
                    });
                  },
                ),
              ],
            ),
          );

          final dialogActions = [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: handleSave,
              child: const Text('Save'),
            ),
          ];

          if (isWindows) {
            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.keyS, control: true): handleSave,
              },
              child: ResizableDialog(
                title: Text('Edit ${item.type.toUpperCase()}'),
                content: dialogContent,
                actions: dialogActions,
                initialSize: const Size(600, 500),
              ),
            );
          }

          return CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyS, control: true): handleSave,
            },
            child: AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text('Edit ${item.type.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: dialogContent,
              actions: dialogActions,
            ),
          );
        },
      ),
    );
  }
}

class _CollectionItemsScreenState extends ConsumerState<CollectionItemsScreen> {
  int? _selectedIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  IconData _getCollectionIcon(String name) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return Icons.school;
      case 'project phoenix':
      case 'programming':
        return Icons.terminal;
      case 'financial documents':
      case 'fitness':
        return Icons.fitness_center;
      case 'inspiration box':
      case 'travel':
        return Icons.explore;
      default:
        return Icons.folder;
    }
  }

  Color _getCollectionBgColor(String name, bool isDark) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return isDark ? const Color(0xFF27153B) : const Color(0xFFEEDBFF);
      case 'project phoenix':
      case 'programming':
        return isDark ? const Color(0xFF2E1C3F) : const Color(0xFFD9B9FD);
      case 'financial documents':
      case 'fitness':
        return isDark ? const Color(0xFF3C1F16) : const Color(0xFFFEB196);
      case 'inspiration box':
      case 'travel':
        return isDark ? const Color(0xFF3B1C1A) : const Color(0xFFFFDAD6);
      default:
        return isDark ? const Color(0xFF242424) : const Color(0xFFEDE6EC);
    }
  }

  Color _getCollectionIconColor(String name, bool isDark) {
    switch (name.toLowerCase()) {
      case 'personal research':
      case 'study':
        return isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
      case 'project phoenix':
      case 'programming':
        return isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
      case 'financial documents':
      case 'fitness':
        return isDark ? const Color(0xFFFEB196) : const Color(0xFF79422D);
      case 'inspiration box':
      case 'travel':
        return isDark ? const Color(0xFFFFB4AB) : const Color(0xFF390B09);
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }

  Future<void> _exportCollection(BuildContext context, WidgetRef ref) async {
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Export Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Choose a file format to export this collection:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'json'), child: const Text('JSON')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'csv'), child: const Text('CSV')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'pdf'), child: const Text('PDF')),
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final svc = BackupService(prefs, userEmail: user.email, userName: user.displayName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting export...'), duration: Duration(seconds: 1)),
    );

    try {
      String? savedPath;
      if (format == 'json') {
        savedPath = await svc.exportJson(collectionFilter: widget.collectionName);
      } else if (format == 'csv') {
        savedPath = await svc.exportCsv(collectionFilter: widget.collectionName);
      } else if (format == 'pdf') {
        savedPath = await svc.exportPdf(collectionFilter: widget.collectionName);
      }

      if (savedPath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export successful! Saved to $savedPath'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _getCollectionBgColor(widget.collectionName, isDark);
    final iconColor = _getCollectionIconColor(widget.collectionName, isDark);
    final iconData = _getCollectionIcon(widget.collectionName);
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final primary = Theme.of(context).colorScheme.primary;

    // Get user-added items of this collection
    final vaultItems = ref.watch(vaultProvider)
        .where((item) => item.collectionName.toLowerCase() == widget.collectionName.toLowerCase())
        .toList();

    final totalItems = vaultItems.length;

    if (_selectedIndex != null && _selectedIndex! >= vaultItems.length) {
      _selectedIndex = vaultItems.isEmpty ? null : vaultItems.length - 1;
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    Widget bodyContent = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (vaultItems.isNotEmpty) {
            setState(() {
              if (_selectedIndex == null) {
                _selectedIndex = 0;
              } else {
                _selectedIndex = (_selectedIndex! + 1).clamp(0, vaultItems.length - 1);
              }
            });
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          if (vaultItems.isNotEmpty) {
            setState(() {
              if (_selectedIndex == null) {
                _selectedIndex = 0;
              } else {
                _selectedIndex = (_selectedIndex! - 1).clamp(0, vaultItems.length - 1);
              }
            });
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (_selectedIndex != null && _selectedIndex! < vaultItems.length) {
            CollectionItemsScreen.openItemDirectly(context, ref, vaultItems[_selectedIndex!]);
          }
        },
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (_selectedIndex != null && _selectedIndex! < vaultItems.length) {
            CollectionItemsScreen.showDeleteConfirmationDialog(context, ref, vaultItems[_selectedIndex!]);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true): () {
          _exportCollection(context, ref);
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: CustomScrollView(
          slivers: [
            // --- Collapsing App Bar with category header ---
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: onSurface, size: 20),
                ),
                onPressed: () => context.go('/main/vault'),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => context.go('/main/profile'),
                    child: const Center(
                      child: UserAvatar(size: 32, borderRadius: 16),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Collection icon badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: bgColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(iconData, size: 32, color: iconColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.collectionName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalItems items',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Item count + sort bar ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COLLECTION ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: onSurfaceVariant,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!kIsWeb && Platform.isWindows) ...[
                          IconButton(
                            icon: const Icon(Icons.download, size: 18),
                            tooltip: 'Export Collection (Ctrl+Shift+E)',
                            onPressed: () => _exportCollection(context, ref),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort, size: 16, color: onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'Recent',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- User-added vault items (if any) ---
            if (vaultItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = vaultItems[index];
                      
                      IconData tileIcon = item.getIconData();
                      Color tileBgColor = Colors.grey;
                      Color tileIconColor = Colors.white;

                      if (item.type.toLowerCase() == 'link') {
                        tileIconColor = isDark ? const Color(0xFFFEB196) : const Color(0xFF79422D);
                        tileBgColor = isDark ? const Color(0xFF3D2518) : const Color(0xFFFEB196);
                      } else if (item.type.toLowerCase() == 'note') {
                        tileIconColor = isDark ? const Color(0xFFD9B9FD) : const Color(0xFF270B46);
                        tileBgColor = isDark ? const Color(0xFF2A1845) : const Color(0xFFEEDBFF);
                      } else if (item.type.toLowerCase() == 'file') {
                        tileIconColor = isDark ? const Color(0xFF8CB4E8) : const Color(0xFF1B4A7D);
                        tileBgColor = isDark ? const Color(0xFF1A2538) : const Color(0xFFD6E8FF);
                      } else if (item.type.toLowerCase() == 'image') {
                        tileIconColor = isDark ? const Color(0xFFFFB4AB) : const Color(0xFF390B09);
                        tileBgColor = isDark ? const Color(0xFF3A1816) : const Color(0xFFFFDAD6);
                      }

                      final isSelected = _selectedIndex == index;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == vaultItems.length - 1 ? 120 : 12,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            CollectionItemsScreen.openItemDirectly(context, ref, item);
                          },
                          onLongPress: () => CollectionItemsScreen.showItemLongPressBottomSheet(context, ref, item),
                          onSecondaryTapDown: (details) => CollectionItemsScreen.showItemContextMenu(context, ref, item, details.globalPosition),
                          child: _buildItemTile(
                            context,
                            title: item.title,
                            subtitle: item.content,
                            icon: tileIcon,
                            bgColor: tileBgColor,
                            iconColor: tileIconColor,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    },
                    childCount: vaultItems.length,
                  ),
                ),
              ),

            if (vaultItems.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: PremiumEmptyState(
                    icon: Icons.folder_open,
                    title: 'No Items In Collection',
                    subtitle: 'Save a new item under this collection to see it here.',
                    buttonText: 'Add Item',
                    onTapButton: () => context.go('/main/add'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (isWide) {
      bodyContent = Row(
        children: [
          const DesktopSidebar(),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? const Color(0x14FFFFFF) : Colors.black.withValues(alpha: 0.05),
          ),
          Expanded(child: bodyContent),
        ],
      );
    }

    return PopScope(
      canPop: isWide,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/main/vault');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: bodyContent,
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    bool isSelected = false,
  }) {
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final primary = Theme.of(context).colorScheme.primary;

    final card = GlassCard(
      padding: const EdgeInsets.all(16),
      boxShadow: DesignTokens.shadowLight,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: onSurfaceVariant, size: 20),
        ],
      ),
    );

    if (isSelected) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: primary, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: card,
      );
    }
    return card;
  }
}

// --- Zoom, Pan, Swipe-to-dismiss Fullscreen Image Viewer widget ---
class SwipeToDismissImageViewer extends ConsumerStatefulWidget {
  final VaultItem item;
  final bool isUrl;
  final bool isLocal;

  const SwipeToDismissImageViewer({
    super.key,
    required this.item,
    required this.isUrl,
    required this.isLocal,
  });

  @override
  ConsumerState<SwipeToDismissImageViewer> createState() => SwipeToDismissImageViewerState();
}

class SwipeToDismissImageViewerState extends ConsumerState<SwipeToDismissImageViewer> {
  double _dragOffset = 0.0;
  File? _cachedFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCacheAndDownload();
  }

  Future<void> _checkCacheAndDownload() async {
    if (!widget.isUrl) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cacheManager = CacheManager.instance;
      final file = await cacheManager.getFile(widget.item.content);
      if (file != null) {
        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isLoading = false;
          });
        }
        return;
      }

      // Not cached, download it in the background
      final supabaseService = ref.read(supabaseServiceProvider);
      final downloadedFile = await CollectionItemsScreen.downloadFileWithProgress(
        id: widget.item.id,
        name: widget.item.title,
        url: widget.item.content,
        supabaseService: supabaseService,
      );

      if (mounted) {
        setState(() {
          _cachedFile = downloadedFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (widget.isUrl) {
      if (_cachedFile != null) {
        imageWidget = Image.file(
          _cachedFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, size: 80, color: Colors.white30),
          ),
        );
      } else if (_isLoading) {
        final transferState = ref.watch(transferProvider)[widget.item.id];
        final progress = transferState?.progress ?? 0.0;
        imageWidget = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Loading Image... ${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      } else {
        imageWidget = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, size: 80, color: Colors.white30),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      }
    } else if (widget.isLocal) {
      imageWidget = Image.file(
        File(widget.item.content),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.white30),
        ),
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.broken_image, size: 80, color: Colors.white30),
      );
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.primaryDelta!;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset.abs() > 150 || details.velocity.pixelsPerSecond.dy.abs() > 1000) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragOffset = 0.0;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: Colors.black.withValues(
          alpha: (0.9 - (_dragOffset.abs() / 1000)).clamp(0.0, 0.9),
        ),
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(0.0, _dragOffset),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                maxScale: 4.0,
                child: imageWidget,
              ),
              Positioned(
                top: 40,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DownloadProgressDialog extends ConsumerWidget {
  final String id;
  final String title;

  const DownloadProgressDialog({
    super.key,
    required this.id,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferState = ref.watch(transferProvider)[id];
    final progress = transferState?.progress ?? 0.0;
    final status = transferState?.status ?? TransferStatus.downloading;
    
    String statusText = 'Downloading...';
    if (status == TransferStatus.completed) {
      statusText = 'Completed';
    } else if (status == TransferStatus.failed) {
      statusText = 'Failed: ${transferState?.errorMessage ?? 'Unknown error'}';
    } else if (status == TransferStatus.retrying) {
      statusText = 'Retrying...';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (status == TransferStatus.failed)
              const Icon(Icons.error_outline, color: Colors.red, size: 48)
            else if (status == TransferStatus.completed)
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 48)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: status == TransferStatus.failed 
                    ? Colors.red 
                    : (status == TransferStatus.completed ? Colors.green : Colors.grey),
              ),
            ),
            if (status != TransferStatus.failed && status != TransferStatus.completed) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
            if (status == TransferStatus.failed || status == TransferStatus.completed) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
