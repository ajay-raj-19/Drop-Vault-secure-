import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'providers.dart';

// Search Query Scaffolding
final searchQueryProvider = StateProvider<String>((ref) => '');

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final SettingsRepository _repository;
  final String _email;

  RecentSearchesNotifier(this._repository, {required String email}) : _email = email, super([]) {
    _loadSearches();
  }

  Future<void> _loadSearches() async {
    final list = await _repository.getRecentSearches(_email);
    state = list;
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(state);
    current.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > 4) {
      state = current.sublist(0, 4);
    } else {
      state = current;
    }
    await _repository.saveRecentSearches(_email, state);
  }

  Future<void> removeSearch(String query) async {
    state = state.where((item) => item != query).toList();
    await _repository.saveRecentSearches(_email, state);
  }

  Future<void> clearAll() async {
    state = [];
    await _repository.saveRecentSearches(_email, []);
  }
}

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return RecentSearchesNotifier(repository, email: email);
});

class LinkCategoriesNotifier extends StateNotifier<List<String>> {
  final SettingsRepository _repository;
  final String _email;

  LinkCategoriesNotifier(this._repository, {required String email}) : _email = email, super(['GitHub', 'YouTube', 'Instagram', 'Website', 'Others']) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _repository.getLinkCategories(_email);
    state = list;
  }

  Future<void> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (state.any((item) => item.toLowerCase() == trimmed.toLowerCase())) return;

    final current = List<String>.from(state);
    final othersIndex = current.indexOf('Others');
    if (othersIndex != -1) {
      current.insert(othersIndex, trimmed);
    } else {
      current.add(trimmed);
    }
    state = current;
    await _repository.saveLinkCategories(_email, state);
  }
}

final linkCategoriesProvider = StateNotifierProvider<LinkCategoriesNotifier, List<String>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return LinkCategoriesNotifier(repository, email: email);
});

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final SettingsRepository _repository;
  final String _email;
  final SharedPreferences _prefs;

  UserSettingsNotifier(this._repository, this._prefs, {required String email}) : _email = email, super(UserSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _repository.getSettings(_email);
    
    bool launchEnabled = false;
    try {
      if (!kIsWeb && Platform.isWindows) {
        launchEnabled = await launchAtStartup.isEnabled();
      }
    } catch (_) {}

    final defaultFolder = _prefs.getString('default_download_folder') ?? '';
    final openBrowser = _prefs.getBool('open_links_in_default_browser') ?? true;
    final rememberWindow = _prefs.getBool('remember_window_position') ?? true;

    state = UserSettings(
      notificationsEnabled: s.notificationsEnabled,
      remindersEnabled: s.remindersEnabled,
      autoSyncEnabled: s.autoSyncEnabled,
      launchOnStartup: launchEnabled,
      defaultDownloadFolder: defaultFolder,
      openLinksInDefaultBrowser: openBrowser,
      rememberWindowPosition: rememberWindow,
    );
  }

  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? remindersEnabled,
    bool? autoSyncEnabled,
    bool? launchOnStartup,
    String? defaultDownloadFolder,
    bool? openLinksInDefaultBrowser,
    bool? rememberWindowPosition,
  }) async {
    final updated = UserSettings(
      notificationsEnabled: notificationsEnabled ?? state.notificationsEnabled,
      remindersEnabled: remindersEnabled ?? state.remindersEnabled,
      autoSyncEnabled: autoSyncEnabled ?? state.autoSyncEnabled,
      launchOnStartup: launchOnStartup ?? state.launchOnStartup,
      defaultDownloadFolder: defaultDownloadFolder ?? state.defaultDownloadFolder,
      openLinksInDefaultBrowser: openLinksInDefaultBrowser ?? state.openLinksInDefaultBrowser,
      rememberWindowPosition: rememberWindowPosition ?? state.rememberWindowPosition,
    );
    await _repository.updateSettings(_email, updated);

    if (rememberWindowPosition != null) {
      await _prefs.setBool('remember_window_position', rememberWindowPosition);
    }

    state = updated;
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserSettingsNotifier(repository, prefs, email: email);
});
