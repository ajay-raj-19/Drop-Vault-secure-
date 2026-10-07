import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowSettingsManager extends WindowListener {
  static final WindowSettingsManager instance = WindowSettingsManager._internal();
  SharedPreferences? _prefs;
  Timer? _debounceTimer;

  WindowSettingsManager._internal();

  Future<void> initialize() async {
    if (kIsWeb || !Platform.isWindows) return;

    _prefs = await SharedPreferences.getInstance();
    windowManager.addListener(this);

    // Load and apply previous window state if remember is enabled
    final bool remember = _prefs?.getBool('remember_window_position') ?? true;
    final double width = remember ? (_prefs?.getDouble('window_width') ?? 1280.0) : 1280.0;
    final double height = remember ? (_prefs?.getDouble('window_height') ?? 720.0) : 720.0;
    final double? x = remember ? _prefs?.getDouble('window_x') : null;
    final double? y = remember ? _prefs?.getDouble('window_y') : null;
    final bool isMaximized = remember ? (_prefs?.getBool('window_maximized') ?? false) : false;

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      minimumSize: const Size(1100, 700),
      center: x == null || y == null,
      title: 'Drop Vault',
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (remember && x != null && y != null && !isMaximized) {
        await windowManager.setPosition(Offset(x, y));
      }
      if (remember && isMaximized) {
        await windowManager.maximize();
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  void _saveWindowStateDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _saveWindowState);
  }

  Future<void> _saveWindowState() async {
    if (_prefs == null) return;

    final bool remember = _prefs!.getBool('remember_window_position') ?? true;
    if (!remember) return;

    try {
      final isMaximized = await windowManager.isMaximized();
      await _prefs!.setBool('window_maximized', isMaximized);

      if (!isMaximized) {
        final size = await windowManager.getSize();
        final position = await windowManager.getPosition();

        await _prefs!.setDouble('window_width', size.width);
        await _prefs!.setDouble('window_height', size.height);
        await _prefs!.setDouble('window_x', position.dx);
        await _prefs!.setDouble('window_y', position.dy);
      }
    } catch (e) {
      debugPrint('Error saving window settings: $e');
    }
  }

  @override
  void onWindowResized() {
    _saveWindowStateDebounced();
  }

  @override
  void onWindowMoved() {
    _saveWindowStateDebounced();
  }

  void onWindowMaximized() {
    _saveWindowStateDebounced();
  }

  void onWindowRestored() {
    _saveWindowStateDebounced();
  }
}
