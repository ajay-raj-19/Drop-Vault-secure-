import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class DesktopFileService {
  /// Opens the containing folder of the given file path in Windows File Explorer.
  static Future<void> openContainingFolder(String filePath) async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        final parentPath = file.parent.path;
        await Process.run('explorer.exe', [parentPath]);
      } else {
        final dir = Directory(filePath);
        if (await dir.exists()) {
          await Process.run('explorer.exe', [dir.path]);
        }
      }
    } catch (e) {
      debugPrint('Error opening containing folder: $e');
    }
  }

  /// Reveals the file at the given file path in Windows File Explorer.
  static Future<void> revealFile(String filePath) async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Run explorer.exe with /select argument to highlight the file
        await Process.run('explorer.exe', ['/select,', file.path]);
      }
    } catch (e) {
      debugPrint('Error revealing file: $e');
    }
  }

  /// Copies a file from cached/local storage to a custom selected folder on Windows.
  static Future<bool> saveAs(String sourceFilePath, String defaultFileName) async {
    if (kIsWeb || !Platform.isWindows) return false;

    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) return false;

      // Launch Save File dialog
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File As',
        fileName: defaultFileName,
      );

      if (outputPath != null) {
        await sourceFile.copy(outputPath);
        return true;
      }
    } catch (e) {
      debugPrint('Error in Save As operation: $e');
    }
    return false;
  }
}
