import '../domain/profile_repository.dart';
import '../../../../core/services/supabase_service.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseService _supabaseService;
  final ProfileRepository _localRepository;

  SupabaseProfileRepository(this._supabaseService, this._localRepository);

  @override
  Future<void> updateProfile(String email, {String? displayName, String? profileImagePath, bool clearProfileImage = false}) async {
    // 1. Always update locally
    await _localRepository.updateProfile(
      email,
      displayName: displayName,
      profileImagePath: profileImagePath,
      clearProfileImage: clearProfileImage,
    );

    // 2. Synchronize with Supabase if online
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (displayName != null) {
          updates['full_name'] = displayName;
        }
        
        if (clearProfileImage) {
          updates['avatar_url'] = null;
        } else if (profileImagePath != null) {
          updates['avatar_url'] = profileImagePath;
        }

        if (updates.length > 1) { // has actual updates other than updated_at
          await _supabaseService.client
              .from('profiles')
              .update(updates)
              .eq('id', userId);
        }
      } catch (_) {
        // Fail silently offline
      }
    }
  }
}
