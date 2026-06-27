import '../../../../core/models/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getSettings(String email);
  Future<void> updateSettings(String email, UserSettings settings);
  
  Future<List<String>> getRecentSearches(String email);
  Future<void> saveRecentSearches(String email, List<String> searches);
  
  Future<List<String>> getLinkCategories(String email);
  Future<void> saveLinkCategories(String email, List<String> categories);

  Future<String?> getThemeMode(String email);
  Future<void> saveThemeMode(String email, String mode);
}
