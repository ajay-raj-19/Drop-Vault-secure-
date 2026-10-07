import 'auth_state.dart';

abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String displayName);
  Future<void> signOut();
  Future<void> recoverPassword(String email);
  Future<void> updateProfile({String? displayName, String? profileImagePath, bool clearProfileImage});
  Future<void> reloadSession();
  Future<void> verifyEmail(String email, String code);
  Future<void> signInWithGoogle(String email, String displayName, {String? profileImagePath});
  Future<void> updatePassword(String email, String newPassword);
  Future<void> exchangeCodeForSession(String code);
  Future<void> deleteAccount(String email);
  Future<String?> pickGoogleAccount();
  Future<bool> isEmailRegistered(String email);
  Stream<AuthState> get authStateChanges;
  AuthState get currentAuthState;
}
