import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  String? _localImagePath;
  bool _imageRemoved = false;
  bool _isSaving = false;
  bool _isSaved = false;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  // Dynamic theme colors
  Color get background => Theme.of(context).scaffoldBackgroundColor;
  Color get primary => Theme.of(context).colorScheme.primary;
  Color get onSurface => context.appColors.primaryText;
  Color get onSurfaceVariant => context.appColors.secondaryText;
  Color get secondary => context.colorScheme.secondary;
  Color get outlineVariant => context.appColors.border;
  Color get mutedText => context.appColors.mutedText;
  Color get cardBg => context.appColors.cardBackground;
  Color get secondaryBg => context.appColors.secondaryBackground;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _localImagePath = user?.profileImagePath;

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final user = ref.read(authStateProvider).user;
    if (user == null) return false;
    final nameChanged = _nameController.text.trim() != user.displayName;
    final imageChanged = _localImagePath != user.profileImagePath || _imageRemoved;
    return nameChanged || imageChanged;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close the bottom sheet
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _localImagePath = image.path;
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    Navigator.of(context).pop(); // Close the bottom sheet
    setState(() {
      _localImagePath = null;
      _imageRemoved = true;
    });
  }

  void _showImagePickerSheet() {
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final handleColor = isDark ? Colors.white24 : Colors.black12;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                color: secondary,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _buildSheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose From Gallery',
                color: const Color(0xFF6D528E),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_localImagePath != null && !_imageRemoved)
                _buildSheetOption(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  color: Theme.of(context).colorScheme.error,
                  onTap: _removeImage,
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final newName = _nameController.text.trim();
      await ref.read(authStateProvider.notifier).updateProfile(
        displayName: newName.isNotEmpty ? newName : null,
        profileImagePath: _imageRemoved ? null : _localImagePath,
        clearProfileImage: _imageRemoved,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
          _imageRemoved = false;
        });
        _successAnimController.forward();

        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          setState(() => _isSaved = false);
          _successAnimController.reset();
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Column(
              children: [
                _buildProfilePhotoSection(user?.profileImagePath),
                const SizedBox(height: 40),
                _buildNameEditSection(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: background.withOpacity(0.8),
              border: Border(bottom: BorderSide(color: outlineVariant.withOpacity(0.2))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: primary),
                        onPressed: () => context.pop(),
                        style: IconButton.styleFrom(
                          hoverColor: onSurfaceVariant.withOpacity(0.08),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection(String? currentImagePath) {
    // Determine what image to show
    final String? displayPath = _imageRemoved ? null : (_localImagePath ?? currentImagePath);
    final bool hasImage = displayPath != null;

    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePickerSheet,
          child: Stack(
            children: [
              // Profile Image Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF6D528E).withOpacity(0.3)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: hasImage
                      ? _buildImageWidget(displayPath)
                      : _buildPlaceholderAvatar(),
                ),
              ),
              // Camera Overlay Badge
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to change photo',
          style: TextStyle(
            fontSize: 13,
            color: mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String path) {
    // Check if it's a network URL or a local file path
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: 128,
        height: 128,
        errorBuilder: (ctx, err, st) => _buildPlaceholderAvatar(),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: 128,
        height: 128,
        errorBuilder: (ctx, err, st) => _buildPlaceholderAvatar(),
      );
    }
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 128,
      height: 128,
      color: isDark ? const Color(0xFF242424) : const Color(0xFFF3ECF2),
      child: Icon(
        Icons.person,
        size: 56,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }

  Widget _buildNameEditSection() {
    final fillColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F2F7);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.transparent;
    final focusBorderColor = isDark ? AppColors.primaryFixedDim : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: onSurfaceVariant,
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name / Display Name
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: onSurfaceVariant,
                  ),
                ),
              ),
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  fontSize: 16,
                  color: onSurface,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: mutedText),
                  prefixIcon: Icon(Icons.person_outline, color: secondary),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: focusBorderColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Hint text
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: mutedText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This name will be displayed across all Drop Vault screens.',
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: _isSaved
            ? null
            : (_hasChanges
                ? (isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF210440), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ))
                : null),
        color: _isSaved
            ? Colors.green[600]
            : (_hasChanges ? null : (isDark ? const Color(0xFF242424) : const Color(0xFFE7E0E6))),
        boxShadow: _hasChanges && !_isSaved
            ? [
                BoxShadow(
                  color: isDark
                      ? const Color(0xFF6D28D9).withOpacity(0.3)
                      : const Color(0xFF6D528E).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _hasChanges ? _handleSave : null,
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : _isSaved
                    ? ScaleTransition(
                        scale: _successScaleAnim,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Saved!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.save_outlined,
                            color: _hasChanges
                                ? Colors.white
                                : (isDark ? Colors.white30 : Colors.black26),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              color: _hasChanges
                                  ? Colors.white
                                  : (isDark ? Colors.white30 : Colors.black45),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
