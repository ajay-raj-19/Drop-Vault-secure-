import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supporting enums / result class
// ─────────────────────────────────────────────────────────────────────────────

enum ImportMode { merge, replace }

class ImportResult {
  final bool success;
  final String message;
  final int itemCount;
  final int collectionCount;
  final int reminderCount;

  const ImportResult({
    required this.success,
    required this.message,
    this.itemCount = 0,
    this.collectionCount = 0,
    this.reminderCount = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BackupService
// ─────────────────────────────────────────────────────────────────────────────

class BackupService {
  final SharedPreferences _prefs;
  final String _userEmail;
  final String _userName;

  BackupService(
    this._prefs, {
    required String userEmail,
    required String userName,
  })  : _userEmail = userEmail,
        _userName = userName;

  // ── SharedPreferences keys ──────────────────────────────────────────────────

  String get _itemsKey => 'vault_items_$_userEmail';
  String get _collectionsKey => 'collections_$_userEmail';
  String get _remindersKey => 'reminders_$_userEmail';
  String get _autoBackupFreqKey => 'auto_backup_freq_$_userEmail';
  String get _lastBackupDateKey => 'last_backup_date_$_userEmail';

  // ── Data loaders ───────────────────────────────────────────────────────────

  List<VaultItem> _loadItems() {
    return (_prefs.getStringList(_itemsKey) ?? [])
        .map((s) => VaultItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  List<Collection> _loadCollections() {
    return (_prefs.getStringList(_collectionsKey) ?? [])
        .map((s) => Collection.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  List<Reminder> _loadReminders() {
    return (_prefs.getStringList(_remindersKey) ?? [])
        .map((s) => Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ── Data summary ───────────────────────────────────────────────────────────

  Map<String, int> getDataSummary() {
    final items = _loadItems();
    return {
      'items': items.length,
      'collections': _loadCollections().length,
      'reminders': _loadReminders().length,
      'links': items.where((i) => i.type == 'link').length,
      'notes': items.where((i) => i.type == 'note').length,
      'files': items.where((i) => i.type == 'file').length,
      'images': items.where((i) => i.type == 'image').length,
    };
  }

  // ── Filtered items helper ──────────────────────────────────────────────────

  List<VaultItem> _filteredItems({String? collectionFilter, String? typeFilter}) {
    return _loadItems().where((item) {
      if (collectionFilter != null && item.collectionName != collectionFilter) return false;
      if (typeFilter != null && item.type != typeFilter) return false;
      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT – JSON
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> exportJson({
    String? collectionFilter,
    String? typeFilter,
  }) async {
    final items = _filteredItems(
      collectionFilter: collectionFilter,
      typeFilter: typeFilter,
    );
    final collections = _loadCollections();
    final reminders = _loadReminders();

    final data = <String, dynamic>{
      'version': '1.0',
      'app': 'Drop Vault',
      'exportDate': DateTime.now().toIso8601String(),
      'userEmail': _userEmail,
      'userName': _userName,
      'collections': collections.map((c) => c.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final fileName = 'DropVault_Backup_${_dateStamp()}.json';
    await _shareText(jsonStr, fileName, 'application/json');
    await _markBackupNow();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT – CSV
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> exportCsv({
    String? collectionFilter,
    String? typeFilter,
  }) async {
    final items = _filteredItems(
      collectionFilter: collectionFilter,
      typeFilter: typeFilter,
    );

    final buf = StringBuffer();
    buf.writeln('Title,Type,Collection,Category,Tags,Content,Created Date');
    for (final item in items) {
      buf.writeln([
        _csv(item.title),
        _csv(item.type),
        _csv(item.collectionName),
        _csv(item.category ?? ''),
        _csv(item.tags.join('; ')),
        _csv(item.content.replaceAll('\n', ' ').replaceAll('\r', '')),
        _csv(item.createdAt.toIso8601String().substring(0, 10)),
      ].join(','));
    }

    final fileName = 'DropVault_Backup_${_dateStamp()}.csv';
    await _shareText(buf.toString(), fileName, 'text/csv');
    await _markBackupNow();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT – PDF
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> exportPdf({
    String? collectionFilter,
    String? typeFilter,
  }) async {
    final items = _filteredItems(
      collectionFilter: collectionFilter,
      typeFilter: typeFilter,
    );
    final collections = _loadCollections();
    final reminders = _loadReminders();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _pdfHeader(),
        footer: (ctx) => _pdfFooter(ctx),
        build: (_) => _buildPdfBody(items, collections, reminders),
      ),
    );

    final bytes = await doc.save();
    final fileName = 'DropVault_Backup_${_dateStamp()}.pdf';
    await _shareBytes(bytes, fileName, 'application/pdf');
    await _markBackupNow();
  }

  // ── PDF header / footer ───────────────────────────────────────────────────

  pw.Widget _pdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.deepPurple, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Drop Vault',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.deepPurple,
            ),
          ),
          pw.Text(
            'Exported: ${_dateStamp()}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFooter(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  // ── PDF body builder ──────────────────────────────────────────────────────

  List<pw.Widget> _buildPdfBody(
    List<VaultItem> items,
    List<Collection> collections,
    List<Reminder> reminders,
  ) {
    final content = <pw.Widget>[];
    final subStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final h1 = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final h2 = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);

    // ── Title ──
    content.add(pw.Text('Vault Export Report', style: h1));
    content.add(pw.SizedBox(height: 4));
    content.add(pw.Text('User: $_userName ($_userEmail)', style: subStyle));
    content.add(pw.Text(
      'Date: ${DateTime.now().toString().substring(0, 19)}',
      style: subStyle,
    ));
    content.add(pw.SizedBox(height: 16));

    // ── Stats card ──
    content.add(
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.deepPurple50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.deepPurple200),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _pdfStat('Collections', '${collections.length}'),
            _pdfStat('Items', '${items.length}'),
            _pdfStat('Links', '${items.where((i) => i.type == 'link').length}'),
            _pdfStat('Notes', '${items.where((i) => i.type == 'note').length}'),
            _pdfStat('Reminders', '${reminders.length}'),
          ],
        ),
      ),
    );
    content.add(pw.SizedBox(height: 24));

    // ── Collections & Items ──
    content.add(pw.Text('Collections & Items', style: h2));
    content.add(pw.SizedBox(height: 10));

    for (final col in collections) {
      final colItems =
          items.where((i) => i.collectionName == col.name).toList();
      content.add(_pdfCollectionBlock(col, colItems));
      content.add(pw.SizedBox(height: 10));
    }

    // Orphan items (no matching collection)
    final knownNames = collections.map((c) => c.name).toSet();
    final orphans =
        items.where((i) => !knownNames.contains(i.collectionName)).toList();
    if (orphans.isNotEmpty) {
      content.add(pw.Text('Other Items', style: h2));
      content.add(pw.SizedBox(height: 6));
      for (final item in orphans) {
        content.add(_pdfItemTile(item));
        content.add(pw.SizedBox(height: 4));
      }
      content.add(pw.SizedBox(height: 12));
    }

    // ── Reminders table ──
    if (reminders.isNotEmpty) {
      content.add(pw.Text('Reminders', style: h2));
      content.add(pw.SizedBox(height: 8));
      content.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(color: PdfColors.deepPurple100),
              children: [
                _pdfCell('Title', bold: true),
                _pdfCell('Collection', bold: true),
                _pdfCell('Date & Time', bold: true),
                _pdfCell('Status', bold: true),
              ],
            ),
            ...reminders.map(
              (r) => pw.TableRow(
                children: [
                  _pdfCell(r.title),
                  _pdfCell(r.collectionName),
                  _pdfCell(r.dateTime.toString().substring(0, 16)),
                  _pdfCell(r.isCompleted ? '✓ Done' : 'Pending'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return content;
  }

  pw.Widget _pdfCollectionBlock(Collection col, List<VaultItem> items) {
    final rows = <pw.Widget>[];

    // Header
    rows.add(
      pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        color: PdfColors.deepPurple100,
        child: pw.Row(
          children: [
            pw.Text(
              col.name,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '${items.length} item${items.length == 1 ? '' : 's'}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );

    if (col.description.isNotEmpty) {
      rows.add(pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: pw.Text(
          col.description,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ));
    }

    for (final item in items) {
      rows.add(pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: _pdfItemTile(item),
      ));
      rows.add(pw.SizedBox(height: 4));
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  pw.Widget _pdfItemTile(VaultItem item) {
    final snippetContent = item.content.length > 250
        ? '${item.content.substring(0, 250)}…'
        : item.content;

    final children = <pw.Widget>[
      pw.Row(
        children: [
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            color: PdfColors.deepPurple200,
            child: pw.Text(
              item.type.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              item.title,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    ];

    if (snippetContent.isNotEmpty) {
      children.add(pw.SizedBox(height: 3));
      children.add(pw.Text(
        snippetContent,
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
      ));
    }

    if (item.tags.isNotEmpty) {
      children.add(pw.SizedBox(height: 2));
      children.add(pw.Text(
        'Tags: ${item.tags.join(', ')}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ));
    }

    children.add(pw.SizedBox(height: 2));
    children.add(pw.Text(
      'Added: ${item.createdAt.toString().substring(0, 10)}',
      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
    ));

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMPORT – JSON
  // ═══════════════════════════════════════════════════════════════════════════

  Future<ImportResult> importJson(
    String jsonContent,
    ImportMode mode,
  ) async {
    try {
      final raw = jsonDecode(jsonContent);
      if (raw is! Map<String, dynamic>) {
        return const ImportResult(
          success: false,
          message: 'Invalid backup file. Expected a JSON object.',
        );
      }
      final data = raw;

      if (!data.containsKey('items') && !data.containsKey('collections')) {
        return const ImportResult(
          success: false,
          message: 'Invalid backup format. Missing "items" or "collections".',
        );
      }

      final importedItems = _parseList(data['items'], VaultItem.fromJson);
      final importedCols = _parseList(data['collections'], Collection.fromJson);
      final importedReminders = _parseList(data['reminders'], Reminder.fromJson);

      if (mode == ImportMode.replace) {
        await _prefs.remove(_itemsKey);
        await _prefs.remove(_collectionsKey);
        await _prefs.remove(_remindersKey);
        await _persistItems(importedItems);
        await _persistCollections(importedCols);
        await _persistReminders(importedReminders);
      } else {
        // Merge – skip duplicates by id
        final existingItems = _loadItems();
        final existingIds = existingItems.map((i) => i.id).toSet();
        await _persistItems([
          ...existingItems,
          ...importedItems.where((i) => !existingIds.contains(i.id)),
        ]);

        final existingCols = _loadCollections();
        final existingColIds = existingCols.map((c) => c.id).toSet();
        await _persistCollections([
          ...existingCols,
          ...importedCols.where((c) => !existingColIds.contains(c.id)),
        ]);

        final existingReminders = _loadReminders();
        final existingReminderIds = existingReminders.map((r) => r.id).toSet();
        await _persistReminders([
          ...existingReminders,
          ...importedReminders
              .where((r) => !existingReminderIds.contains(r.id)),
        ]);
      }

      await _markBackupNow();
      return ImportResult(
        success: true,
        message: 'Restore successful!',
        itemCount: importedItems.length,
        collectionCount: importedCols.length,
        reminderCount: importedReminders.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

  List<T> _parseList<T>(
    dynamic rawList,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (rawList == null) return [];
    return (rawList as List)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO-BACKUP SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  String getAutoBackupFrequency() =>
      _prefs.getString(_autoBackupFreqKey) ?? 'off';

  Future<void> setAutoBackupFrequency(String freq) async =>
      _prefs.setString(_autoBackupFreqKey, freq);

  String? getLastBackupDateString() =>
      _prefs.getString(_lastBackupDateKey);

  Future<void> _markBackupNow() async =>
      _prefs.setString(_lastBackupDateKey, DateTime.now().toIso8601String());

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSIST HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _persistItems(List<VaultItem> items) => _prefs.setStringList(
        _itemsKey,
        items.map((i) => jsonEncode(i.toJson())).toList(),
      );

  Future<void> _persistCollections(List<Collection> cols) =>
      _prefs.setStringList(
        _collectionsKey,
        cols.map((c) => jsonEncode(c.toJson())).toList(),
      );

  Future<void> _persistReminders(List<Reminder> reminders) =>
      _prefs.setStringList(
        _remindersKey,
        reminders.map((r) => jsonEncode(r.toJson())).toList(),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE SHARE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _shareText(
    String content,
    String fileName,
    String mimeType,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'Drop Vault Backup',
    );
  }

  Future<void> _shareBytes(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'Drop Vault Backup',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STRING UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  String _dateStamp() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _csv(String value) {
    final needsQuoting = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (needsQuoting) return '"${value.replaceAll('"', '""')}"';
    return value;
  }
}
