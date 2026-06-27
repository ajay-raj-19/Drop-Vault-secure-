import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/backup_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage>
    with SingleTickerProviderStateMixin {
  // ── Export state ───────────────────────────────────────────────────────────
  String _exportFormat = 'json'; // json | csv | pdf
  String _exportScope = 'all'; // all | collection | type
  String? _selectedCollection;
  String? _selectedType;
  bool _isExporting = false;

  // ── Import state ───────────────────────────────────────────────────────────
  PlatformFile? _pickedFile;
  ImportMode _importMode = ImportMode.merge;
  bool _isImporting = false;

  // ── Auto-backup state ──────────────────────────────────────────────────────
  String _autoBackupFreq = 'off'; // off | daily | weekly

  // ── Service ────────────────────────────────────────────────────────────────
  BackupService? _svc;

  // ── Animation controller ───────────────────────────────────────────────────
  late AnimationController _animCtrl;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initService();
  }

  void _initService() {
    final prefs = ref.read(sharedPreferencesProvider);
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) return;

    _svc = BackupService(
      prefs,
      userEmail: user.email,
      userName: user.displayName,
    );
    _autoBackupFreq = _svc!.getAutoBackupFrequency();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Theme helpers
  // ─────────────────────────────────────────────────────────────────────────

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _onSurface => context.appColors.primaryText;
  Color get _secondary => context.appColors.secondaryText;
  Color get _border => context.appColors.border;
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _primaryDim => context.appColors.primaryFixedDim;
  Color get _onPrimaryDim => AppColors.onPrimaryFixedVariant;
  Color get _secondaryFixed => context.appColors.secondaryFixed;
  Color get _onSecondaryFixed => context.appColors.onSecondaryFixed;
  Color get _secondaryCont => AppColors.secondaryContainer;
  Color get _onSecondaryCont => AppColors.onSecondaryContainer;
  Color get _surfaceVar => Theme.of(context).brightness == Brightness.dark
      ? context.appColors.secondaryBackground
      : const Color(0xFFE7E0E6);

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final summary = _svc?.getDataSummary() ??
        {'items': 0, 'collections': 0, 'reminders': 0};
    final collections =
        ref.watch(collectionProvider).map((c) => c.name).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 100,
          bottom: 120,
          left: 24,
          right: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataSummary(summary),
                const SizedBox(height: 24),
                _buildExportSection(collections),
                const SizedBox(height: 24),
                _buildImportSection(),
                const SizedBox(height: 24),
                _buildAutoBackupSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _bg.withValues(alpha: 0.85),
              border: Border(
                bottom: BorderSide(color: _border.withValues(alpha: 0.2)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: _onSurface),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Backup & Restore',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _onSurface,
                        ),
                      ),
                    ],
                  ),
                  const UserAvatar(size: 32, borderRadius: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data Summary Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDataSummary(Map<String, int> summary) {
    final lastBackup = _svc?.getLastBackupDateString();
    String lastBackupText = 'Never';
    if (lastBackup != null) {
      final dt = DateTime.tryParse(lastBackup);
      if (dt != null) {
        lastBackupText =
            '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return _Section(
      title: 'YOUR DATA',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  icon: Icons.folder,
                  label: 'Collections',
                  value: '${summary['collections'] ?? 0}',
                  color: _secondaryFixed,
                  iconColor: _onSecondaryFixed,
                ),
                _StatChip(
                  icon: Icons.widgets,
                  label: 'Items',
                  value: '${summary['items'] ?? 0}',
                  color: _primaryDim,
                  iconColor: _onPrimaryDim,
                ),
                _StatChip(
                  icon: Icons.alarm,
                  label: 'Reminders',
                  value: '${summary['reminders'] ?? 0}',
                  color: _secondaryCont,
                  iconColor: _onSecondaryCont,
                ),
              ],
            ),
          ),
          Divider(color: _border.withValues(alpha: 0.3), height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: _secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last backup: $lastBackupText',
                    style: TextStyle(fontSize: 13, color: _secondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Export Section
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildExportSection(List<String> collections) {
    return _Section(
      title: 'EXPORT DATA',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scope ──
            Text(
              'Export Scope',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ScopeChip(
                  label: 'All Data',
                  selected: _exportScope == 'all',
                  onTap: () => setState(() {
                    _exportScope = 'all';
                    _selectedCollection = null;
                    _selectedType = null;
                  }),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: 'By Collection',
                  selected: _exportScope == 'collection',
                  onTap: () => setState(() {
                    _exportScope = 'collection';
                    _selectedType = null;
                  }),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: 'By Type',
                  selected: _exportScope == 'type',
                  onTap: () => setState(() {
                    _exportScope = 'type';
                    _selectedCollection = null;
                  }),
                ),
              ],
            ),

            // ── Collection picker ──
            if (_exportScope == 'collection') ...[
              const SizedBox(height: 12),
              _buildDropdown(
                hint: 'Select collection',
                value: _selectedCollection,
                items: collections,
                onChanged: (v) => setState(() => _selectedCollection = v),
              ),
            ],

            // ── Type picker ──
            if (_exportScope == 'type') ...[
              const SizedBox(height: 12),
              _buildDropdown(
                hint: 'Select type',
                value: _selectedType,
                items: const ['link', 'note', 'file', 'image'],
                itemLabels: const ['Links', 'Notes', 'Files', 'Images'],
                onChanged: (v) => setState(() => _selectedType = v),
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: _border.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 16),

            // ── Format ──
            Text(
              'Export Format',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _FormatChip(
                  icon: Icons.data_object,
                  label: 'JSON',
                  sublabel: 'Full backup',
                  selected: _exportFormat == 'json',
                  onTap: () => setState(() => _exportFormat = 'json'),
                ),
                const SizedBox(width: 8),
                _FormatChip(
                  icon: Icons.table_chart,
                  label: 'CSV',
                  sublabel: 'Excel ready',
                  selected: _exportFormat == 'csv',
                  onTap: () => setState(() => _exportFormat = 'csv'),
                ),
                const SizedBox(width: 8),
                _FormatChip(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  sublabel: 'Report',
                  selected: _exportFormat == 'pdf',
                  onTap: () => setState(() => _exportFormat = 'pdf'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Export Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _doExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded, size: 20),
                label: Text(
                  _isExporting ? 'Exporting…' : 'Export ${_exportFormat.toUpperCase()}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceVar.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border.withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: _secondary, fontSize: 14)),
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          style: TextStyle(color: _onSurface, fontSize: 14),
          icon: Icon(Icons.expand_more, color: _secondary),
          onChanged: onChanged,
          items: items.asMap().entries.map((e) {
            final label = (itemLabels != null && e.key < itemLabels.length)
                ? itemLabels[e.key]
                : e.value;
            return DropdownMenuItem(
              value: e.value,
              child: Text(label),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Import Section
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildImportSection() {
    return _Section(
      title: 'RESTORE DATA',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _primaryDim.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: _primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only JSON backup files created by Drop Vault are supported.',
                      style: TextStyle(fontSize: 12, color: _secondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // File picker
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _surfaceVar.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pickedFile != null
                        ? _primary.withValues(alpha: 0.6)
                        : _border.withValues(alpha: 0.4),
                    width: _pickedFile != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryDim.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _pickedFile != null
                            ? Icons.check_circle
                            : Icons.folder_open,
                        color: _pickedFile != null ? _primary : _onPrimaryDim,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pickedFile != null
                                ? _pickedFile!.name
                                : 'Select Backup File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pickedFile != null
                                ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB · JSON'
                                : 'Tap to browse',
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pickedFile != null)
                      GestureDetector(
                        onTap: () => setState(() => _pickedFile = null),
                        child:
                            Icon(Icons.close, size: 18, color: _secondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Import Mode
            Text(
              'Import Mode',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.merge_type,
                    title: 'Merge',
                    subtitle: 'Add to existing data',
                    selected: _importMode == ImportMode.merge,
                    onTap: () =>
                        setState(() => _importMode = ImportMode.merge),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.restart_alt,
                    title: 'Replace',
                    subtitle: 'Erase & restore',
                    selected: _importMode == ImportMode.replace,
                    onTap: () =>
                        setState(() => _importMode = ImportMode.replace),
                    isDangerous: true,
                  ),
                ),
              ],
            ),

            // Replace warning
            if (_importMode == ImportMode.replace) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This will permanently delete ALL your current data before restoring.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Import Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (_pickedFile != null && !_isImporting) ? _doImport : null,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _isImporting ? 'Restoring…' : 'Restore Backup',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _importMode == ImportMode.replace
                      ? Colors.red
                      : null,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auto-Backup Section
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAutoBackupSection() {
    return _Section(
      title: 'AUTO-BACKUP',
      child: Column(
        children: [
          for (final freq in [
            ('off', Icons.block, 'Off', 'Manual only'),
            ('daily', Icons.today, 'Daily', 'Reminder every day'),
            ('weekly', Icons.date_range, 'Weekly', 'Reminder every week'),
          ])
            _AutoBackupTile(
              icon: freq.$2,
              title: freq.$3,
              subtitle: freq.$4,
              selected: _autoBackupFreq == freq.$1,
              onTap: () async {
                setState(() => _autoBackupFreq = freq.$1);
                await _svc?.setAutoBackupFrequency(freq.$1);
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _doExport() async {
    if (_svc == null) return;

    // Validate scope selection
    if (_exportScope == 'collection' && _selectedCollection == null) {
      _showSnack('Please select a collection first.', isError: true);
      return;
    }
    if (_exportScope == 'type' && _selectedType == null) {
      _showSnack('Please select an item type first.', isError: true);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final col =
          _exportScope == 'collection' ? _selectedCollection : null;
      final type = _exportScope == 'type' ? _selectedType : null;

      String? savedPath;
      switch (_exportFormat) {
        case 'json':
          savedPath = await _svc!.exportJson(
              collectionFilter: col, typeFilter: type);
          break;
        case 'csv':
          savedPath = await _svc!.exportCsv(
              collectionFilter: col, typeFilter: type);
          break;
        case 'pdf':
          savedPath = await _svc!.exportPdf(
              collectionFilter: col, typeFilter: type);
          break;
      }

      if (savedPath != null) {
        _showSnack('Export successful! Saved to $savedPath', isError: false);
      } else {
        _showSnack('Export cancelled.', isError: false);
      }

      setState(() {}); // refresh last-backup date display
    } catch (e) {
      _showSnack('Export failed: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pickedFile = result.files.first);
      }
    } catch (e) {
      _showSnack('Could not pick file: $e', isError: true);
    }
  }

  Future<void> _doImport() async {
    if (_svc == null || _pickedFile == null) return;

    // Confirm replace mode
    if (_importMode == ImportMode.replace) {
      final confirmed = await _showReplaceConfirmDialog();
      if (!confirmed) return;
    }

    setState(() => _isImporting = true);
    try {
      final bytes = _pickedFile!.bytes;
      if (bytes == null) {
        _showSnack('Could not read file. Please try again.', isError: true);
        return;
      }

      final jsonStr = String.fromCharCodes(bytes);
      final result = await _svc!.importJson(jsonStr, _importMode);

      if (result.success) {
        // Invalidate providers so UI refreshes with imported data
        ref.invalidate(vaultProvider);
        ref.invalidate(collectionProvider);
        ref.invalidate(reminderProvider);

        setState(() => _pickedFile = null);
        _showImportSuccessDialog(result);
      } else {
        _showSnack(result.message, isError: true);
      }
    } catch (e) {
      _showSnack('Import failed: $e', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<bool> _showReplaceConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Replace All Data?'),
              ],
            ),
            content: const Text(
              'This will permanently delete all your current collections, items, and reminders, then restore the backup. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete & Restore'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showImportSuccessDialog(ImportResult result) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Restore Complete'),
          ],
        ),
        content: Text(
          '✓ ${result.collectionCount} collection${result.collectionCount == 1 ? '' : 's'}\n'
          '✓ ${result.itemCount} item${result.itemCount == 1 ? '' : 's'}\n'
          '✓ ${result.reminderCount} reminder${result.reminderCount == 1 ? '' : 's'}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Section wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: context.appColors.secondaryText,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appColors.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.appColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scope Chip (export scope)
// ─────────────────────────────────────────────────────────────────────────────

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : context.appColors.border.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? primary : context.appColors.secondaryText,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Format Chip (JSON / CSV / PDF)
// ─────────────────────────────────────────────────────────────────────────────

class _FormatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.7)
                  : context.appColors.border.withValues(alpha: 0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? primary : context.appColors.secondaryText,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? primary : context.appColors.primaryText,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9,
                  color: context.appColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Mode Card
// ─────────────────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool isDangerous;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDangerous && selected
        ? Colors.red
        : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.7)
                : context.appColors.border.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? primary : context.appColors.secondaryText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? primary : context.appColors.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.appColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto-Backup Tile
// ─────────────────────────────────────────────────────────────────────────────

class _AutoBackupTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AutoBackupTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.15)
                      : context.appColors.secondaryBackground.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? primary : context.appColors.secondaryText,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: context.appColors.primaryText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? primary : context.appColors.mutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
