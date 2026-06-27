import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_repository.dart';
import '../../../../core/models/user_settings.dart';

class LocalSettingsRepository implements SettingsRepository {
  final SharedPreferences _prefs;

  LocalSettingsRepository(this._prefs);

  String _getSettingsKey(String email) => 'user_settings_$email';
  String _getRecentSearchesKey(String email) => 'recent_searches_$email';
  String _getLinkCategoriesKey(String email) => 'custom_link_categories_$email';
  String _getThemeKey(String email) => 'theme_mode_$email';

  @override
  Future<UserSettings> getSettings(String email) async {
    final str = _prefs.getString(_getSettingsKey(email));
    if (str != null) {
      try {
        return UserSettings.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return UserSettings();
  }

  @override
  Future<void> updateSettings(String email, UserSettings settings) async {
    await _prefs.setString(_getSettingsKey(email), jsonEncode(settings.toJson()));
  }

  @override
  Future<List<String>> getRecentSearches(String email) async {
    return _prefs.getStringList(_getRecentSearchesKey(email)) ?? [];
  }

  @override
  Future<void> saveRecentSearches(String email, List<String> searches) async {
    await _prefs.setStringList(_getRecentSearchesKey(email), searches);
  }

  @override
  Future<List<String>> getLinkCategories(String email) async {
    return _prefs.getStringList(_getLinkCategoriesKey(email)) ?? ['GitHub', 'YouTube', 'Instagram', 'Website', 'Others'];
  }

  @override
  Future<void> saveLinkCategories(String email, List<String> categories) async {
    await _prefs.setStringList(_getLinkCategoriesKey(email), categories);
  }

  @override
  Future<String?> getThemeMode(String email) async {
    return _prefs.getString(_getThemeKey(email));
  }

  @override
  Future<void> saveThemeMode(String email, String mode) async {
    await _prefs.setString(_getThemeKey(email), mode);
  }
}
