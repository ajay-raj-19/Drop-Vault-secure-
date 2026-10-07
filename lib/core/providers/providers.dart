import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../services/sync_service.dart';

// Repository interfaces
import '../../features/vault/domain/collection_repository.dart';
import '../../features/vault/domain/item_repository.dart';
import '../../features/reminder/domain/reminder_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/profile/domain/profile_repository.dart';

// Models
export '../models/vault_item.dart';
export '../models/collection.dart';
export '../models/reminder.dart';
export '../models/user_settings.dart';

// Repositories
export '../../features/vault/domain/collection_repository.dart';
export '../../features/vault/domain/item_repository.dart';
export '../../features/reminder/domain/reminder_repository.dart';
export '../../features/settings/domain/settings_repository.dart';
export '../../features/profile/domain/profile_repository.dart';

// Repository implementations
import '../../features/vault/data/local_collection_repository.dart';
import '../../features/vault/data/supabase_collection_repository.dart';
import '../../features/vault/data/local_item_repository.dart';
import '../../features/vault/data/supabase_item_repository.dart';
import '../../features/reminder/data/local_reminder_repository.dart';
import '../../features/reminder/data/supabase_reminder_repository.dart';
import '../../features/settings/data/local_settings_repository.dart';
import '../../features/settings/data/supabase_settings_repository.dart';
import '../../features/profile/data/local_profile_repository.dart';
import '../../features/profile/data/supabase_profile_repository.dart';

// Providers
export 'vault_provider.dart';
export 'collection_provider.dart';
export 'reminder_provider.dart';
export 'theme_provider.dart';
export 'settings_provider.dart';
export 'undo_provider.dart';

// Sync Service
export '../services/sync_service.dart';

// Shared SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// Supabase Service Providers
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final supabaseErrorProvider = Provider<String?>((ref) {
  return ref.watch(supabaseServiceProvider).initError;
});

// Dual Source Flag
final useCloudProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final isInitialized = ref.watch(supabaseServiceProvider).isInitialized;
  return isInitialized && authState.user != null;
});

// Collection Repository Providers
final localCollectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalCollectionRepository(prefs);
});

final supabaseCollectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  final local = ref.watch(localCollectionRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SupabaseCollectionRepository(svc, local, prefs);
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final useCloud = ref.watch(useCloudProvider);
  if (useCloud) {
    return ref.watch(supabaseCollectionRepositoryProvider);
  } else {
    return ref.watch(localCollectionRepositoryProvider);
  }
});

// Item Repository Providers
final localItemRepositoryProvider = Provider<ItemRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalItemRepository(prefs);
});

final supabaseItemRepositoryProvider = Provider<ItemRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  final local = ref.watch(localItemRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SupabaseItemRepository(svc, local, prefs);
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final useCloud = ref.watch(useCloudProvider);
  if (useCloud) {
    return ref.watch(supabaseItemRepositoryProvider);
  } else {
    return ref.watch(localItemRepositoryProvider);
  }
});

// Reminder Repository Providers
final localReminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalReminderRepository(prefs);
});

final supabaseReminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  final local = ref.watch(localReminderRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SupabaseReminderRepository(svc, local, prefs);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final useCloud = ref.watch(useCloudProvider);
  if (useCloud) {
    return ref.watch(supabaseReminderRepositoryProvider);
  } else {
    return ref.watch(localReminderRepositoryProvider);
  }
});

// Settings Repository Providers
final localSettingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalSettingsRepository(prefs);
});

final supabaseSettingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  final local = ref.watch(localSettingsRepositoryProvider);
  return SupabaseSettingsRepository(svc, local);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final useCloud = ref.watch(useCloudProvider);
  if (useCloud) {
    return ref.watch(supabaseSettingsRepositoryProvider);
  } else {
    return ref.watch(localSettingsRepositoryProvider);
  }
});

// Profile Repository Providers
final localProfileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return LocalProfileRepository(authRepo);
});

final supabaseProfileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  final local = ref.watch(localProfileRepositoryProvider);
  return SupabaseProfileRepository(svc, local);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final useCloud = ref.watch(useCloudProvider);
  if (useCloud) {
    return ref.watch(supabaseProfileRepositoryProvider);
  } else {
    return ref.watch(localProfileRepositoryProvider);
  }
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final syncService = SyncService.instance;
  syncService.initialize(ref);
  ref.onDispose(syncService.dispose);
  return syncService;
});

final isOfflineProvider = StateProvider<bool>((ref) => false);

