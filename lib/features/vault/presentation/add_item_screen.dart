import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/user_avatar.dart';

class AddItemPage extends ConsumerStatefulWidget {
  final List<File>? initialFiles;
  const AddItemPage({super.key, this.initialFiles});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  // Theme Colors resolved dynamically
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get primaryFixed => context.appColors.primaryFixed;
  Color get onPrimaryFixed => context.appColors.onPrimaryFixed;
  Color get surfaceContainerLowest => context.appColors.cardBackground;
  Color get surfaceContainerLow => context.appColors.secondaryBackground;
  Color get surfaceContainerHigh => context.appColors.elevatedCardBackground;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get outline => context.appColors.mutedText;
  Color get outlineVariant => context.appColors.border;
  Color get secondary => Theme.of(context).colorScheme.secondary;
  Color get secondaryContainer => AppColors.secondaryContainer;
  Color get onSecondaryContainer => AppColors.onSecondaryContainer;

  bool _isReminderEnabled = true;
  final List<String> _tags = ['research', '2024'];
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  String _selectedType = 'note';
  String? _selectedCollection;
  String _selectedLinkCategory = 'GitHub';

  // Multi-file selection list
  final List<File> _selectedFiles = [];

  // Reminder selections
  String _activeReminderOption = 'tomorrow';
  DateTime? _selectedReminderDate;

  // Saving state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default reminder is set to tomorrow
    _selectedReminderDate = DateTime.now().add(const Duration(days: 1));

    // Handle files passed on navigate (e.g. from drag & drop)
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      _selectedFiles.addAll(widget.initialFiles!);
      final firstFile = widget.initialFiles!.first;
      final fileName = firstFile.path.split(Platform.pathSeparator).last;
      
      _titleController.text = fileName;

      final extension = fileName.split('.').last.toLowerCase();
      if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(extension)) {
        _selectedType = 'image';
      } else {
        _selectedType = 'file';
      }
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'zip', 'ppt', 'pptx'],
        allowMultiple: true,
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              final pickedFile = File(file.path!);
              if (!_selectedFiles.any((f) => f.path == pickedFile.path)) {
                _selectedFiles.add(pickedFile);
              }
            }
          }
          if (_titleController.text.trim().isEmpty && _selectedFiles.isNotEmpty) {
            _titleController.text = _selectedFiles.first.path.split(Platform.pathSeparator).last;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking file'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
        if (!mounted) return;
        if (result != null) {
          setState(() {
            for (final file in result.files) {
              if (file.path != null) {
                final pickedFile = File(file.path!);
                if (!_selectedFiles.any((f) => f.path == pickedFile.path)) {
                  _selectedFiles.add(pickedFile);
                }
              }
            }
            _selectedType = 'image';
            if (_titleController.text.trim().isEmpty && _selectedFiles.isNotEmpty) {
              _titleController.text = _selectedFiles.first.path.split(Platform.pathSeparator).last;
            }
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Select Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Photo Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await picker.pickImage(source: source);
        if (!mounted) return;
        if (image != null) {
          final size = await image.length();
          if (!mounted) return;
          if (size > 10 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum image size is 10 MB'), backgroundColor: Colors.red),
            );
          } else {
            setState(() {
              final pickedFile = File(image.path);
              if (!_selectedFiles.any((f) => f.path == pickedFile.path)) {
                _selectedFiles.add(pickedFile);
              }
              if (_titleController.text.trim().isEmpty && _selectedFiles.isNotEmpty) {
                _titleController.text = _selectedFiles.first.path.split(Platform.pathSeparator).last;
              }
            });
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickCustomReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedReminderDate ?? DateTime.now().add(const Duration(days: 1))),
      );
      if (time != null) {
        setState(() {
          _activeReminderOption = 'custom';
          _selectedReminderDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _showInlineCreateCollectionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Create Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter collection name...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(collectionProvider.notifier).createCollection(name);
                setState(() {
                  _selectedCollection = name;
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final collections = ref.watch(collectionProvider);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSaveItem,
      },
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            // Background Overlay
            Container(color: primary.withValues(alpha: 0.03)),
  
            // Main Layout
            Row(
              children: [
                if (isDesktop && !isWide) _buildDesktopSideNav(),
                Expanded(
                  child: Column(
                    children: [
                      _buildAppBar(isDesktop),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                              child: _buildMainContent(collections),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.only(
        left: isDesktop ? 40 : 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.go('/main/dashboard'),
                style: IconButton.styleFrom(
                  backgroundColor: onSurfaceVariant.withValues(alpha: 0.1),
                  foregroundColor: onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Drop Vault',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
              ),
            ],
          ),
          const UserAvatar(
            size: 32,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isMultiline ? 5 : 1,
          style: TextStyle(color: onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: onSurfaceVariant.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(List<Collection> collections) {
    final typeUpper = _selectedType.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 100),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: outlineVariant) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Add New Item', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 8),
          Text('Securely store a new piece of your digital world.', style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
          const SizedBox(height: 32),

          // Action Grid
          _buildActionGrid(),
          const SizedBox(height: 32),

          // Title Input
          _buildTextField('TITLE', _titleController, 'Enter item title...'),
          const SizedBox(height: 24),

          // Conditional input fields based on type selection
          if (typeUpper == 'LINK') ...[
            _buildTextField('URL', _contentController, 'Enter link URL (e.g. google.com)...'),
            const SizedBox(height: 24),
            _buildLinkCategoryDropdown(),
            if (_selectedLinkCategory == 'Others') ...[
              const SizedBox(height: 24),
              _buildTextField('CREATE NEW CATEGORY', _newCategoryController, 'Enter custom category name (e.g. Flutter)...'),
            ],
            const SizedBox(height: 24),
          ] else if (typeUpper == 'NOTE') ...[
            _buildTextField('NOTE BODY', _contentController, 'Enter note body...', isMultiline: true),
            const SizedBox(height: 24),
          ] else if (typeUpper == 'FILE') ...[
            _buildFileSelector(),
            const SizedBox(height: 24),
          ] else if (typeUpper == 'IMAGE') ...[
            _buildImageSelector(),
            const SizedBox(height: 24),
          ],

          // Collection
          _buildCollectionSelector(collections),
          const SizedBox(height: 24),

          // Tags Input
          _buildTagsInput(),
          const SizedBox(height: 24),

          // Reminders
          _buildReminderSection(),
          const SizedBox(height: 32),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildQuickAction('Add Link', Icons.link, 'link'),
        _buildQuickAction('Add Note', Icons.note_add, 'note'),
        _buildQuickAction('Upload File', Icons.upload_file, 'file'),
        _buildQuickAction('Add Image', Icons.image, 'image'),
      ],
    );
  }

  Widget _buildQuickAction(String title, IconData icon, String type) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryFixed : surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? onPrimaryFixed : secondary, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? onPrimaryFixed : onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCategoryDropdown() {
    final categories = ref.watch(linkCategoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LINK CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: secondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(28),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLinkCategory,
              icon: Icon(Icons.expand_more, color: onSurfaceVariant),
              dropdownColor: surfaceContainerLowest,
              items: categories.map((String cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat, style: TextStyle(color: onSurface)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLinkCategory = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT FILES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        if (_selectedFiles.isEmpty)
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: secondary),
                  const SizedBox(height: 12),
                  Text('Select files from storage', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('PDF, DOC, DOCX, TXT, ZIP, PPT, PPTX (Max 10MB)', style: TextStyle(fontSize: 11, color: outline)),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ..._selectedFiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                final fileName = file.path.split(Platform.pathSeparator).last;
                final sizeStr = file.existsSync() 
                    ? '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB' 
                    : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.insert_drive_file, color: secondary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fileName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (sizeStr.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(sizeStr, style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add More Files'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT IMAGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        if (_selectedFiles.isEmpty)
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: secondary),
                  const SizedBox(height: 12),
                  Text('Select images', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('PNG, JPG, JPEG, WEBP, GIF (Max 10MB)', style: TextStyle(fontSize: 11, color: outline)),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ..._selectedFiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                final fileName = file.path.split(Platform.pathSeparator).last;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(fileName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add More Images'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCollectionSelector(List<Collection> collections) {
    if (_selectedCollection == null && collections.isNotEmpty) {
      _selectedCollection = collections.first.name;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT COLLECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: secondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCollection,
                    icon: Icon(Icons.expand_more, color: onSurfaceVariant),
                    dropdownColor: surfaceContainerLowest,
                    items: collections.map((Collection col) {
                      return DropdownMenuItem<String>(
                        value: col.name,
                        child: Text(col.name, style: TextStyle(color: onSurface)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCollection = val;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: _showInlineCreateCollectionDialog,
              style: IconButton.styleFrom(
                backgroundColor: secondary.withValues(alpha: 0.05),
                foregroundColor: primary,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADD TAGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: secondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$tag', style: TextStyle(fontSize: 12, color: onSecondaryContainer)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeTag(tag),
                          child: Icon(Icons.close, size: 16, color: onSecondaryContainer),
                        ),
                      ],
                    ),
                  )),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _tagController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: 'Type and enter...',
                    hintStyle: TextStyle(fontSize: 14, color: onSurfaceVariant.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _addTag,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications, color: primary),
                  const SizedBox(width: 12),
                  Text('Set Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
                ],
              ),
              Switch(
                value: _isReminderEnabled,
                onChanged: (val) {
                  setState(() {
                    _isReminderEnabled = val;
                  });
                },
                activeTrackColor: primary,
                activeThumbColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: !_isReminderEnabled,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isReminderEnabled ? 1.0 : 0.4,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickPickButton('Tomorrow', _activeReminderOption == 'tomorrow', onTap: () {
                    setState(() {
                      _activeReminderOption = 'tomorrow';
                      _selectedReminderDate = DateTime.now().add(const Duration(days: 1));
                    });
                  }),
                  _buildQuickPickButton('Next Week', _activeReminderOption == 'next_week', onTap: () {
                    setState(() {
                      _activeReminderOption = 'next_week';
                      _selectedReminderDate = DateTime.now().add(const Duration(days: 7));
                    });
                  }),
                  _buildQuickPickButton('Custom', _activeReminderOption == 'custom', icon: Icons.calendar_today, onTap: _pickCustomReminderDate),
                ],
              ),
            ),
          ),
          if (_isReminderEnabled && _selectedReminderDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reminder set for: ${_selectedReminderDate!.month}/${_selectedReminderDate!.day} at ${_selectedReminderDate!.hour.toString().padLeft(2, '0')}:${_selectedReminderDate!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPickButton(String label, bool isSelected, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          border: Border.all(color: isSelected ? primary.withValues(alpha: 0.2) : outlineVariant.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primary : onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: _isSaving ? null : _handleSaveItem,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _isSaving
              ? null
              : LinearGradient(
                  colors: [secondary, Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isSaving ? Colors.grey : null,
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isSaving
              ? [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Saving...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ]
              : [
                  const Icon(Icons.save, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Save Item',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
        ),
      ),
    );
  }

  Future<void> _handleSaveItem() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red),
      );
      return;
    }

    String finalContent = '';
    String? finalCategory;
    final isFileOrImage = _selectedType == 'file' || _selectedType == 'image';

    if (isFileOrImage) {
      if (_selectedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one $_selectedType'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      if (_selectedType == 'link') {
        final rawUrl = _contentController.text.trim();
        if (rawUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a URL'), backgroundColor: Colors.red),
          );
          return;
        }

        // Friendly validation and parsing of URL
        var parsedUrl = rawUrl;
        if (!parsedUrl.startsWith('http://') && !parsedUrl.startsWith('https://')) {
          parsedUrl = 'https://$parsedUrl';
        }
        final uri = Uri.tryParse(parsedUrl);
        if (uri == null || !uri.host.contains('.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid URL'), backgroundColor: Colors.red),
          );
          return;
        }
        finalContent = parsedUrl;

        // Category Selection
        if (_selectedLinkCategory == 'Others') {
          final customCat = _newCategoryController.text.trim();
          if (customCat.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a custom category name'), backgroundColor: Colors.red),
            );
            return;
          }
          await ref.read(linkCategoriesProvider.notifier).addCategory(customCat);
          finalCategory = customCat;
        } else {
          finalCategory = _selectedLinkCategory;
        }
      } else if (_selectedType == 'note') {
        finalContent = _contentController.text.trim();
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (isFileOrImage) {
        // Save multiple files/images
        for (var i = 0; i < _selectedFiles.length; i++) {
          final file = _selectedFiles[i];
          final fileTitle = i == 0 ? title : '$title ($i)';

          final newItem = VaultItem(
            id: 'item-${DateTime.now().millisecondsSinceEpoch}-$i',
            title: fileTitle,
            type: _selectedType,
            content: file.path,
            collectionName: _selectedCollection ?? 'Personal Research',
            createdAt: DateTime.now(),
            tags: List<String>.from(_tags),
            category: null,
          );

          // Save item
          await ref.read(vaultProvider.notifier).addItem(newItem);

          // Save reminder if enabled
          if (_isReminderEnabled && _selectedReminderDate != null) {
            final newReminder = Reminder(
              id: 'rem-${DateTime.now().millisecondsSinceEpoch}-$i',
              title: 'Review $fileTitle',
              collectionName: _selectedCollection ?? 'Personal Research',
              dateTime: _selectedReminderDate!,
              itemId: newItem.id,
            );
            await ref.read(reminderProvider.notifier).addReminder(newReminder);
          }
        }
      } else {
        // Save single link/note
        final newItem = VaultItem(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          type: _selectedType,
          content: finalContent,
          collectionName: _selectedCollection ?? 'Personal Research',
          createdAt: DateTime.now(),
          tags: List<String>.from(_tags),
          category: finalCategory,
        );

        // Save item
        await ref.read(vaultProvider.notifier).addItem(newItem);

        // Save reminder if enabled
        if (_isReminderEnabled && _selectedReminderDate != null) {
          final newReminder = Reminder(
            id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Review $title',
            collectionName: _selectedCollection ?? 'Personal Research',
            dateTime: _selectedReminderDate!,
            itemId: newItem.id,
          );
          await ref.read(reminderProvider.notifier).addReminder(newReminder);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedType.toUpperCase()} Saved Successfully'), backgroundColor: Colors.green),
        );
        context.go('/main/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildDesktopSideNav() {
    return Container(
      width: 80,
      color: surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text('D', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 32),
          IconButton(icon: Icon(Icons.inventory_2, color: onSurfaceVariant), onPressed: () {}),
          const SizedBox(height: 24),
          IconButton(icon: Icon(Icons.star, color: onSurfaceVariant), onPressed: () {}),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFEEDBFF), borderRadius: BorderRadius.circular(24)),
            child: IconButton(icon: const Icon(Icons.add, color: Colors.black), onPressed: () {}),
          ),
          const SizedBox(height: 24),
          IconButton(icon: Icon(Icons.cloud_done, color: onSurfaceVariant), onPressed: () {}),
          const Spacer(),
          IconButton(icon: Icon(Icons.settings, color: onSurfaceVariant), onPressed: () => context.go('/main/profile/settings')),
        ],
      ),
    );
  }
}
