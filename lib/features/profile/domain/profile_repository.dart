abstract class ProfileRepository {
  Future<void> updateProfile(String email, {String? displayName, String? profileImagePath, bool clearProfileImage});
}
