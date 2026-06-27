import '../domain/settings_repository.dart';
import '../../../../core/models/user_settings.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/uuid_helper.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseService _supabaseService;
  final SettingsRepository _localRepository;

  SupabaseSettingsRepository(this._supabaseService, this._localRepository);

  Future<Map<String, dynamic>?> _fetchOrInitRemoteSettings(String email) async {
    if (!_supabaseService.isInitialized || _supabaseService.client.auth.currentUser == null) return null;

    try {
      final userId = _supabaseService.client.auth.currentUser!.id;
      final response = await _supabaseService.client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        final localSettings = await _localRepository.getSettings(email);
        final localSearches = await _localRepository.getRecentSearches(email);
        final localCats = await _localRepository.getLinkCategories(email);
        final localTheme = await _localRepository.getThemeMode(email);

        final settingsId = toUuid('${userId}_settings');
        final data = {
          'id': settingsId,
          'user_id': userId,
          'notifications_enabled': localSettings.notificationsEnabled,
          'reminders_enabled': localSettings.remindersEnabled,
          'auto_sync_enabled': localSettings.autoSyncEnabled,
          'recent_searches': localSearches,
          'link_categories': localCats,
          'theme_mode': localTheme ?? 'system',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabaseService.client.from('user_settings').insert(data);
        return data;
      }
      return response;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserSettings> getSettings(String email) async {
    final remote = await _fetchOrInitRemoteSettings(email);
    if (remote != null) {
      final localSettings = UserSettings(
        notificationsEnabled: remote['notifications_enabled'] ?? true,
        remindersEnabled: remote['reminders_enabled'] ?? false,
        autoSyncEnabled: remote['auto_sync_enabled'] ?? true,
      );
      await _localRepository.updateSettings(email, localSettings);
    }
    return _localRepository.getSettings(email);
  }

  @override
  Future<void> updateSettings(String email, UserSettings settings) async {
    await _localRepository.updateSettings(email, settings);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('user_settings').upsert({
          'id': toUuid('${userId}_settings'),
          'user_id': userId,
          'notifications_enabled': settings.notificationsEnabled,
          'reminders_enabled': settings.remindersEnabled,
          'auto_sync_enabled': settings.autoSyncEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<List<String>> getRecentSearches(String email) async {
    final remote = await _fetchOrInitRemoteSettings(email);
    if (remote != null) {
      final searches = List<String>.from(remote['recent_searches'] ?? []);
      await _localRepository.saveRecentSearches(email, searches);
    }
    return _localRepository.getRecentSearches(email);
  }

  @override
  Future<void> saveRecentSearches(String email, List<String> searches) async {
    await _localRepository.saveRecentSearches(email, searches);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('user_settings').upsert({
          'id': toUuid('${userId}_settings'),
          'user_id': userId,
          'recent_searches': searches,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<List<String>> getLinkCategories(String email) async {
    final remote = await _fetchOrInitRemoteSettings(email);
    if (remote != null) {
      final cats = List<String>.from(remote['link_categories'] ?? []);
      await _localRepository.saveLinkCategories(email, cats);
    }
    return _localRepository.getLinkCategories(email);
  }

  @override
  Future<void> saveLinkCategories(String email, List<String> categories) async {
    await _localRepository.saveLinkCategories(email, categories);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('user_settings').upsert({
          'id': toUuid('${userId}_settings'),
          'user_id': userId,
          'link_categories': categories,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<String?> getThemeMode(String email) async {
    final remote = await _fetchOrInitRemoteSettings(email);
    if (remote != null) {
      final theme = remote['theme_mode'] as String?;
      if (theme != null) {
        await _localRepository.saveThemeMode(email, theme);
      }
    }
    return _localRepository.getThemeMode(email);
  }

  @override
  Future<void> saveThemeMode(String email, String mode) async {
    await _localRepository.saveThemeMode(email, mode);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('user_settings').upsert({
          'id': toUuid('${userId}_settings'),
          'user_id': userId,
          'theme_mode': mode,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }
}
