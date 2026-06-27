import '../domain/profile_repository.dart';
import '../../auth/domain/auth_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  final AuthRepository _authRepository;

  LocalProfileRepository(this._authRepository);

  @override
  Future<void> updateProfile(String email, {String? displayName, String? profileImagePath, bool clearProfileImage = false}) async {
    await _authRepository.updateProfile(
      displayName: displayName,
      profileImagePath: profileImagePath,
      clearProfileImage: clearProfileImage,
    );
  }
}
