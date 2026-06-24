import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../features/auth/presentation/providers/auth_provider.dart';

// Auth State Scaffolding
class AuthState {
  final bool isAuthenticated;
  final String? email;
  final String? displayName;

  AuthState({
    this.isAuthenticated = false,
    this.email,
    this.displayName,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void login(String email, String password) {
    state = AuthState(isAuthenticated: true, email: email, displayName: 'User');
  }

  void signup(String name, String email, String password) {
    state = AuthState(isAuthenticated: true, email: email, displayName: name);
  }

  void logout() {
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Vault Item Model Scaffolding
class VaultItem {
  final String id;
  final String title;
  final String type; // link, note, file, image
  final String content;
  final String collectionName;
  final DateTime createdAt;
  final List<String> tags;
  final String? category;

  VaultItem({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.collectionName,
    required this.createdAt,
    this.tags = const [],
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'content': content,
    'collectionName': collectionName,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'category': category,
  };

  factory VaultItem.fromJson(Map<String, dynamic> json) => VaultItem(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    content: json['content'],
    collectionName: json['collectionName'] ?? 'Personal Research',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    tags: List<String>.from(json['tags'] ?? []),
    category: json['category'],
  );

  IconData getIconData() {
    switch (type.toLowerCase()) {
      case 'note':
        return Icons.edit_note;
      case 'file':
        return Icons.upload_file;
      case 'image':
        return Icons.image;
      case 'link':
        switch (category?.toLowerCase()) {
          case 'github':
            return Icons.code;
          case 'youtube':
            return Icons.play_circle_outline;
          case 'instagram':
            return Icons.camera_alt;
          case 'website':
            return Icons.language;
          default:
            return Icons.link;
        }
      default:
        return Icons.insert_drive_file;
    }
  }
}

class VaultNotifier extends StateNotifier<List<VaultItem>> {
  final SharedPreferences _prefs;
  final String _key;

  VaultNotifier(this._prefs, {required String key}) : _key = key, super([]) {
    _loadItems();
  }

  void _loadItems() {
    final list = _prefs.getStringList(_key);
    if (list != null) {
      state = list.map((itemStr) => VaultItem.fromJson(jsonDecode(itemStr))).toList();
    }
  }

  Future<void> addItem(VaultItem item) async {
    state = [...state, item];
    await _saveItems();
  }

  Future<void> deleteItem(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _saveItems();
  }

  void reloadItems() {
    _loadItems();
  }

  Future<void> updateItem(VaultItem updatedItem) async {
    state = state.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
    await _saveItems();
  }

  Future<void> renameCollectionInItems(String oldName, String newName) async {
    state = state.map((item) {
      if (item.collectionName == oldName) {
        return VaultItem(
          id: item.id,
          title: item.title,
          type: item.type,
          content: item.content,
          collectionName: newName,
          createdAt: item.createdAt,
          tags: item.tags,
        );
      }
      return item;
    }).toList();
    await _saveItems();
  }

  Future<void> deleteItemsInCollection(String collectionName) async {
    state = state.where((item) => item.collectionName != collectionName).toList();
    await _saveItems();
  }

  Future<void> trashItem(VaultItem item, VaultNotifier trashNotifier, ReminderNotifier reminderNotifier) async {
    await trashNotifier.addItem(item);
    await deleteItem(item.id);
    final reminders = reminderNotifier.state;
    for (final r in reminders) {
      if (r.itemId == item.id) {
        await reminderNotifier.deleteReminder(r.id);
      }
    }
  }

  Future<void> _saveItems() async {
    final list = state.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, List<VaultItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return VaultNotifier(prefs, key: 'vault_items_$email');
});

// Collection Model & Notifier
class Collection {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  Collection({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'],
    name: json['name'],
    description: json['description'] ?? '',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}

class CollectionNotifier extends StateNotifier<List<Collection>> {
  final SharedPreferences _prefs;
  final String _key;

  CollectionNotifier(this._prefs, {required String key}) : _key = key, super([]) {
    _loadCollections();
  }

  void _loadCollections() {
    final list = _prefs.getStringList(_key);
    if (list != null) {
      state = list
          .map((itemStr) => Collection.fromJson(jsonDecode(itemStr)))
          .where((col) => !['col-1', 'col-2', 'col-3', 'col-4'].contains(col.id))
          .toList();
    } else {
      state = [];
      _saveCollections();
    }
  }

  void reloadCollections() {
    _loadCollections();
  }

  Future<void> addCollection(Collection collection) async {
    state = [...state, collection];
    await _saveCollections();
  }

  Future<void> createCollection(String name, {String description = ''}) async {
    final newCol = Collection(
      id: 'col-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    await addCollection(newCol);
  }

  Future<void> deleteCollection(String id) async {
    state = state.where((col) => col.id != id).toList();
    await _saveCollections();
  }

  Future<void> updateCollection(Collection updatedCol) async {
    state = state.map((col) => col.id == updatedCol.id ? updatedCol : col).toList();
    await _saveCollections();
  }

  Future<void> _saveCollections() async {
    final list = state.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }

  Future<void> trashCollection(Collection collection, List<VaultItem> items, VaultNotifier trashNotifier, VaultNotifier vaultNotifier, ReminderNotifier reminderNotifier) async {
    final trashedColItem = VaultItem(
      id: 'col-trash-${collection.id}',
      title: collection.name,
      type: 'collection',
      content: jsonEncode(collection.toJson()),
      collectionName: '',
      createdAt: DateTime.now(),
    );
    await trashNotifier.addItem(trashedColItem);

    final itemsInCol = items.where((item) => item.collectionName == collection.name).toList();
    for (final item in itemsInCol) {
      await trashNotifier.addItem(item);
      await vaultNotifier.deleteItem(item.id);
      final reminders = reminderNotifier.state;
      for (final r in reminders) {
        if (r.itemId == item.id) {
          await reminderNotifier.deleteReminder(r.id);
        }
      }
    }

    await deleteCollection(collection.id);
  }
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, List<Collection>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return CollectionNotifier(prefs, key: 'collections_$email');
});

// Reminder Model & Notifier
class Reminder {
  final String id;
  final String title;
  final String collectionName;
  final DateTime dateTime;
  final bool isCompleted;
  final String? itemId;

  Reminder({
    required this.id,
    required this.title,
    required this.collectionName,
    required this.dateTime,
    this.isCompleted = false,
    this.itemId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? collectionName,
    DateTime? dateTime,
    bool? isCompleted,
    String? itemId,
    bool clearItemId = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      collectionName: collectionName ?? this.collectionName,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      itemId: clearItemId ? null : (itemId ?? this.itemId),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'collectionName': collectionName,
    'dateTime': dateTime.toIso8601String(),
    'isCompleted': isCompleted,
    'itemId': itemId,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    collectionName: json['collectionName'] ?? 'Personal Research',
    dateTime: DateTime.parse(json['dateTime']),
    isCompleted: json['isCompleted'] ?? false,
    itemId: json['itemId'],
  );
}

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  final SharedPreferences _prefs;
  final String _key;

  ReminderNotifier(this._prefs, {required String key}) : _key = key, super([]) {
    _loadReminders();
  }

  void _loadReminders() {
    final list = _prefs.getStringList(_key);
    if (list != null) {
      state = list.map((itemStr) => Reminder.fromJson(jsonDecode(itemStr))).toList();
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    state = [...state, reminder];
    await _saveReminders();
  }

  Future<void> toggleReminder(String id) async {
    state = state.map((r) => r.id == id ? r.copyWith(isCompleted: !r.isCompleted) : r).toList();
    await _saveReminders();
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveReminders();
  }

  void reloadReminders() {
    _loadReminders();
  }

  Future<void> _saveReminders() async {
    final list = state.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }
}

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return ReminderNotifier(prefs, key: 'reminders_$email');
});

// Trash State Scaffolding
final trashProvider = StateNotifierProvider<VaultNotifier, List<VaultItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return VaultNotifier(prefs, key: 'trash_items_$email');
});

// Search Query Scaffolding
final searchQueryProvider = StateProvider<String>((ref) => '');

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return ThemeNotifier(prefs, key: 'theme_mode_$email');
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  final String _themeKey;

  ThemeNotifier(this._prefs, {required String key}) : _themeKey = key, super(ThemeMode.light) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final modeString = _prefs.getString(_themeKey);
    switch (modeString) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final targetMode = mode == ThemeMode.system ? ThemeMode.light : mode;
    state = targetMode;
    final modeString = targetMode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs.setString(_themeKey, modeString);
  }
}

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  final String _key;

  RecentSearchesNotifier(this._prefs, {required String key}) : _key = key, super([]) {
    _loadSearches();
  }

  void _loadSearches() {
    final list = _prefs.getStringList(_key);
    if (list != null) {
      state = list;
    }
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
    await _prefs.setStringList(_key, state);
  }

  Future<void> removeSearch(String query) async {
    state = state.where((item) => item != query).toList();
    await _prefs.setStringList(_key, state);
  }

  Future<void> clearAll() async {
    state = [];
    await _prefs.remove(_key);
  }
}

final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return RecentSearchesNotifier(prefs, key: 'recent_searches_$email');
});

class LinkCategoriesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  final String _key;

  LinkCategoriesNotifier(this._prefs, {required String key}) : _key = key, super(['GitHub', 'YouTube', 'Instagram', 'Website', 'Others']) {
    _loadCategories();
  }

  void _loadCategories() {
    final list = _prefs.getStringList(_key);
    if (list != null) {
      state = list;
    } else {
      state = ['GitHub', 'YouTube', 'Instagram', 'Website', 'Others'];
      _saveCategories();
    }
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
    await _saveCategories();
  }

  Future<void> _saveCategories() async {
    await _prefs.setStringList(_key, state);
  }
}

final linkCategoriesProvider = StateNotifierProvider<LinkCategoriesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return LinkCategoriesNotifier(prefs, key: 'custom_link_categories_$email');
});

// User Settings Model & Notifier for User Data Isolation
class UserSettings {
  final bool notificationsEnabled;
  final bool remindersEnabled;
  final bool autoSyncEnabled;

  UserSettings({
    this.notificationsEnabled = true,
    this.remindersEnabled = false,
    this.autoSyncEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'remindersEnabled': remindersEnabled,
    'autoSyncEnabled': autoSyncEnabled,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    notificationsEnabled: json['notificationsEnabled'] ?? true,
    remindersEnabled: json['remindersEnabled'] ?? false,
    autoSyncEnabled: json['autoSyncEnabled'] ?? true,
  );
}

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final SharedPreferences _prefs;
  final String _key;

  UserSettingsNotifier(this._prefs, {required String key}) : _key = key, super(UserSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final str = _prefs.getString(_key);
    if (str != null) {
      try {
        state = UserSettings.fromJson(jsonDecode(str));
      } catch (_) {}
    }
  }

  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? remindersEnabled,
    bool? autoSyncEnabled,
  }) async {
    state = UserSettings(
      notificationsEnabled: notificationsEnabled ?? state.notificationsEnabled,
      remindersEnabled: remindersEnabled ?? state.remindersEnabled,
      autoSyncEnabled: autoSyncEnabled ?? state.autoSyncEnabled,
    );
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return UserSettingsNotifier(prefs, key: 'user_settings_$email');
});
