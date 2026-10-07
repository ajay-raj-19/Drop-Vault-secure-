import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class MockAuthService implements AuthRepository {
  final SharedPreferences _prefs;
  final _controller = StreamController<AuthState>.broadcast();
  AuthState _state = AuthState.unauthenticated();

  static const String _authKey = 'auth_state_user';

  MockAuthService(this._prefs) {
    _loadPersistedSession();
  }

  String _hashPassword(String password) {
    if (password == 'GOOGLE_ACCOUNT_NO_PASSWORD') return password;
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    if (password.length < 6) return false;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_#@]').hasMatch(password);
    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  Map<String, Map<String, dynamic>> _loadRegisteredUsers() {
    final jsonStr = _prefs.getString('registered_users_db');
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonStr);
      return parsed.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRegisteredUsers(Map<String, Map<String, dynamic>> db) async {
    await _prefs.setString('registered_users_db', jsonEncode(db));
  }

  void _loadPersistedSession() {
    final authJson = _prefs.getString(_authKey);
    if (authJson != null) {
      try {
        final Map<String, dynamic> mapData = jsonDecode(authJson);
        final user = AuthUser(
          email: mapData['email'],
          displayName: mapData['displayName'],
          fullName: mapData['fullName'] ?? mapData['displayName'] ?? '',
          joinDate: mapData['joinDate'] != null ? DateTime.parse(mapData['joinDate']) : DateTime.now(),
          isVerified: mapData['isVerified'] ?? true,
          profileImagePath: mapData['profileImagePath'],
        );
        _state = AuthState.authenticated(user);
      } catch (e) {
        _state = AuthState.unauthenticated();
      }
    } else {
      _state = AuthState.unauthenticated();
    }
    // Broadcast initial state
    scheduleMicrotask(() {
      _controller.add(_state);
    });
  }

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  AuthState get currentAuthState => _state;

  void _updateState(AuthState newState) {
    _state = newState;
    _controller.add(_state);
    _saveSession();
  }

  Future<void> _saveSession() async {
    if (_state.status == AuthStatus.authenticated && _state.user != null) {
      final user = _state.user!;
      final authJson = jsonEncode({
        'email': user.email,
        'displayName': user.displayName,
        'fullName': user.fullName,
        'joinDate': user.joinDate.toIso8601String(),
        'isVerified': user.isVerified,
        'profileImagePath': user.profileImagePath,
      });
      await _prefs.setString(_authKey, authJson);
    } else {
      await _prefs.remove(_authKey);
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    _updateState(AuthState.loading());
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final lowercaseEmail = email.trim().toLowerCase();
    if (!_isValidEmail(lowercaseEmail)) {
      _updateState(AuthState.unauthenticated(errorMessage: 'Invalid Email Format'));
      throw Exception('Invalid Email Format');
    }

    final db = _loadRegisteredUsers();
    
    if (db.containsKey(lowercaseEmail)) {
      final userDetails = db[lowercaseEmail]!;
      final hashedInput = _hashPassword(password);
      if (userDetails['password'] == hashedInput) {
        final isVerified = userDetails['isVerified'] ?? false;
        if (!isVerified) {
          final verificationCode = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
          await _prefs.setString('verification_code_$lowercaseEmail', verificationCode);
          
          debugPrint("====================================");
          debugPrint("EMAIL SIMULATOR: New code sent to $lowercaseEmail is $verificationCode");
          debugPrint("====================================");
          
          _updateState(AuthState.unauthenticated(errorMessage: 'Unverified Account'));
          throw Exception('Unverified Account');
        }

        final savedDisplayName = _prefs.getString('display_name_$lowercaseEmail') ?? userDetails['displayName'] ?? userDetails['fullName'] ?? 'User';
        final savedProfileImage = _prefs.getString('profile_image_$lowercaseEmail') ?? userDetails['profileImagePath'];
        
        final user = AuthUser(
          email: email.trim(),
          displayName: savedDisplayName,
          fullName: userDetails['fullName'] ?? savedDisplayName,
          joinDate: userDetails['joinDate'] != null ? DateTime.parse(userDetails['joinDate']) : DateTime.now(),
          isVerified: true,
          profileImagePath: savedProfileImage,
        );
        _updateState(AuthState.authenticated(user));
        return;
      } else {
        _updateState(AuthState.unauthenticated(errorMessage: 'Wrong Password'));
        throw Exception('Wrong Password');
      }
    }
    
    _updateState(AuthState.unauthenticated(errorMessage: 'Account Not Found'));
    throw Exception('Account Not Found');
  }

  @override
  Future<void> signUp(String email, String password, String displayName) async {
    _updateState(AuthState.loading());
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final lowercaseEmail = email.trim().toLowerCase();
    if (!_isValidEmail(lowercaseEmail)) {
      _updateState(AuthState.unauthenticated(errorMessage: 'Invalid Email Format'));
      throw Exception('Invalid Email Format');
    }
    if (!_isValidPassword(password)) {
      _updateState(AuthState.unauthenticated(errorMessage: 'Password does not meet safety criteria'));
      throw Exception('Password does not meet safety criteria');
    }
    
    final db = _loadRegisteredUsers();
    
    if (db.containsKey(lowercaseEmail)) {
      _updateState(AuthState.unauthenticated(errorMessage: 'An account with this email already exists.'));
      throw Exception('An account with this email already exists.');
    }
    
    final joinDate = DateTime.now();
    
    db[lowercaseEmail] = {
      'email': email.trim(),
      'password': _hashPassword(password),
      'displayName': displayName.trim(),
      'fullName': displayName.trim(),
      'joinDate': joinDate.toIso8601String(),
      'profileImagePath': null,
      'isVerified': true,
    };
    await _saveRegisteredUsers(db);
    
    final user = AuthUser(
      email: email.trim(),
      displayName: displayName.trim(),
      fullName: displayName.trim(),
      joinDate: joinDate,
      isVerified: true,
      profileImagePath: null,
    );
    _updateState(AuthState.authenticated(user));
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    final lowercaseEmail = email.trim().toLowerCase();
    final savedCode = _prefs.getString('verification_code_$lowercaseEmail');
    if (savedCode != code) {
      throw Exception("Invalid verification code.");
    }
    
    final db = _loadRegisteredUsers();
    if (!db.containsKey(lowercaseEmail)) {
      throw Exception("Account not found.");
    }
    
    db[lowercaseEmail]!['isVerified'] = true;
    await _saveRegisteredUsers(db);
    await _prefs.remove('verification_code_$lowercaseEmail');
    
    final userDetails = db[lowercaseEmail]!;
    final user = AuthUser(
      email: userDetails['email'],
      displayName: userDetails['displayName'] ?? userDetails['fullName'] ?? 'User',
      fullName: userDetails['fullName'] ?? '',
      joinDate: DateTime.parse(userDetails['joinDate']),
      isVerified: true,
      profileImagePath: userDetails['profileImagePath'],
    );
    _updateState(AuthState.authenticated(user));
  }

  @override
  Future<void> signInWithGoogle(String email, String displayName, {String? profileImagePath}) async {
    _updateState(AuthState.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    
    String? selectedEmail;
    try {
      selectedEmail = await const MethodChannel('com.example.drop_vault/google_sign_in')
          .invokeMethod<String>('pickGoogleAccount');
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') {
        _updateState(AuthState.unauthenticated(errorMessage: 'Google Sign-In was cancelled.'));
        throw Exception('Google Sign-In was cancelled.');
      }
      selectedEmail = email.isNotEmpty ? email : 'ajayraj@gmail.com';
    } catch (_) {
      selectedEmail = email.isNotEmpty ? email : 'ajayraj@gmail.com';
    }

    if (selectedEmail == null || selectedEmail.isEmpty) {
      _updateState(AuthState.unauthenticated(errorMessage: 'No Google account selected.'));
      throw Exception('No Google account selected.');
    }

    final lowercaseEmail = selectedEmail.trim().toLowerCase();
    if (!_isValidEmail(lowercaseEmail)) {
      _updateState(AuthState.unauthenticated(errorMessage: 'Invalid Email Format'));
      throw Exception('Invalid Email Format');
    }
    
    final db = _loadRegisteredUsers();
    AuthUser user;

    if (!db.containsKey(lowercaseEmail)) {
      String parsedName = '';
      if (lowercaseEmail == 'ajay@gmail.com') {
        parsedName = 'Ajay';
      } else if (lowercaseEmail == 'ajayraj@gmail.com') {
        parsedName = 'Ajay Raj';
      } else if (lowercaseEmail == 'college@gmail.com') {
        parsedName = 'College';
      } else {
        final username = lowercaseEmail.split('@')[0];
        final parts = username.split(RegExp(r'[._\-]'));
        parsedName = parts.map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        }).join(' ');
      }

      const defaultPhoto = 'https://lh3.googleusercontent.com/aida-public/AB6AXuDsxLur2JxojRH4GAHT8Pb--Pxk-EM3bSmhJnZ8tcwojyKvMMmhsJZBtmTXNGxEDx-dCNVys75Gbte9Xubx8SqzJ1wZNyJR5ytLMWqP00lenJo7j4CUEkd5Wz9iU0MxHYEOUgbjARPMFUikH68gaiFhD5Ofy2q_QUe-A8syC47kJ_hUClS6_gcYh2k1Fq74ZQ-nGX-eicZGvAi1cYWykMjasXdVA4lSjDd0HacLMxxeCHPuekCvjzgSyHv6hRy_76v1coRXp-dEhqyT';
      final joinDate = DateTime.now();

      db[lowercaseEmail] = {
        'email': selectedEmail.trim(),
        'password': 'GOOGLE_ACCOUNT_NO_PASSWORD',
        'displayName': parsedName,
        'fullName': parsedName,
        'joinDate': joinDate.toIso8601String(),
        'profileImagePath': defaultPhoto,
        'isVerified': true,
      };
      await _saveRegisteredUsers(db);
      
      user = AuthUser(
        email: selectedEmail.trim(),
        displayName: parsedName,
        fullName: parsedName,
        joinDate: joinDate,
        isVerified: true,
        profileImagePath: defaultPhoto,
      );
    } else {
      final userDetails = db[lowercaseEmail]!;
      user = AuthUser(
        email: userDetails['email'],
        displayName: userDetails['displayName'] ?? userDetails['fullName'] ?? 'User',
        fullName: userDetails['fullName'] ?? '',
        joinDate: DateTime.parse(userDetails['joinDate']),
        isVerified: true,
        profileImagePath: userDetails['profileImagePath'],
      );
    }
    
    _updateState(AuthState.authenticated(user));
  }

  @override
  Future<void> recoverPassword(String email) async {
    _updateState(AuthState.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    
    final lowercaseEmail = email.trim().toLowerCase();
    if (!_isValidEmail(lowercaseEmail)) {
      _updateState(AuthState.unauthenticated());
      throw Exception("Invalid Email Format");
    }

    final db = _loadRegisteredUsers();
    if (!db.containsKey(lowercaseEmail)) {
      _updateState(AuthState.unauthenticated());
      throw Exception("Account Not Found");
    }
    
    final resetCode = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
    await _prefs.setString('reset_code_$lowercaseEmail', resetCode);
    
    debugPrint("====================================");
    debugPrint("EMAIL SIMULATOR: Reset link for $lowercaseEmail is:");
    debugPrint("dropvault://reset-password?code=$resetCode");
    debugPrint("====================================");
    
    _updateState(AuthState.unauthenticated());
  }



  @override
  Future<void> updatePassword(String email, String newPassword) async {
    if (!_isValidPassword(newPassword)) {
      throw Exception("Password does not meet safety criteria");
    }
    final lowercaseEmail = email.trim().toLowerCase();
    final db = _loadRegisteredUsers();
    if (!db.containsKey(lowercaseEmail)) {
      throw Exception("Account not found.");
    }
    
    db[lowercaseEmail]!['password'] = _hashPassword(newPassword);
    db[lowercaseEmail]!['isVerified'] = true;
    await _saveRegisteredUsers(db);
    await _prefs.remove('reset_code_$lowercaseEmail');
  }

  @override
  Future<void> exchangeCodeForSession(String code) async {
    final db = _loadRegisteredUsers();
    String? foundEmail;
    
    for (final email in db.keys) {
      final savedCode = _prefs.getString('reset_code_$email');
      if (savedCode == code) {
        foundEmail = email;
        break;
      }
    }
    
    if (foundEmail == null) {
      if (code == 'mock-google-code') {
        foundEmail = 'testuser@gmail.com';
        if (!db.containsKey(foundEmail)) {
          db[foundEmail] = {
            'email': foundEmail,
            'password': _hashPassword('password123'),
            'displayName': 'Test User',
            'fullName': 'Test User',
            'joinDate': DateTime.now().toIso8601String(),
            'isVerified': true,
          };
          await _saveRegisteredUsers(db);
        }
      } else {
        throw Exception('Invalid or expired code.');
      }
    }
    
    final userDetails = db[foundEmail]!;
    final user = AuthUser(
      email: userDetails['email'],
      displayName: userDetails['displayName'] ?? userDetails['fullName'] ?? 'User',
      fullName: userDetails['fullName'] ?? '',
      joinDate: DateTime.parse(userDetails['joinDate']),
      isVerified: true,
      profileImagePath: userDetails['profileImagePath'],
    );
    _updateState(AuthState.authenticated(user));
  }

  @override
  Future<void> deleteAccount(String email) async {
    final lowercaseEmail = email.trim().toLowerCase();
    final db = _loadRegisteredUsers();
    if (db.containsKey(lowercaseEmail)) {
      db.remove(lowercaseEmail);
      await _saveRegisteredUsers(db);
    }
    // Delete personal details
    await _prefs.remove('display_name_$lowercaseEmail');
    await _prefs.remove('profile_image_$lowercaseEmail');
    
    // Delete user-scoped database keys
    await _prefs.remove('vault_items_$lowercaseEmail');
    await _prefs.remove('collections_$lowercaseEmail');
    await _prefs.remove('reminders_$lowercaseEmail');
    await _prefs.remove('trash_items_$lowercaseEmail');
    await _prefs.remove('recent_searches_$lowercaseEmail');
    await _prefs.remove('custom_link_categories_$lowercaseEmail');
    await _prefs.remove('theme_mode_$lowercaseEmail');
    await _prefs.remove('user_settings_$lowercaseEmail');
    
    await signOut();
  }

  @override
  Future<void> signOut() async {
    _updateState(AuthState.loading());
    await Future.delayed(const Duration(milliseconds: 500));
    _updateState(AuthState.unauthenticated());
  }

  @override
  Future<void> updateProfile({String? displayName, String? profileImagePath, bool clearProfileImage = false}) async {
    if (_state.status != AuthStatus.authenticated || _state.user == null) {
      throw Exception('Not authenticated.');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentUser = _state.user!;
    final updatedUser = currentUser.copyWith(
      displayName: displayName,
      profileImagePath: profileImagePath,
      clearProfileImage: clearProfileImage,
    );
    
    final lowercaseEmail = currentUser.email.toLowerCase();
    final db = _loadRegisteredUsers();
    if (db.containsKey(lowercaseEmail)) {
      if (displayName != null) {
        db[lowercaseEmail]!['displayName'] = displayName;
        await _prefs.setString('display_name_$lowercaseEmail', displayName);
      }
      if (clearProfileImage) {
        db[lowercaseEmail]!['profileImagePath'] = null;
        await _prefs.remove('profile_image_$lowercaseEmail');
      } else if (profileImagePath != null) {
        db[lowercaseEmail]!['profileImagePath'] = profileImagePath;
        await _prefs.setString('profile_image_$lowercaseEmail', profileImagePath);
      }
      await _saveRegisteredUsers(db);
    }
    
    _updateState(AuthState.authenticated(updatedUser));
  }

  @override
  Future<String?> pickGoogleAccount() async {
    try {
      final email = await const MethodChannel('com.example.drop_vault/google_sign_in')
          .invokeMethod<String>('pickGoogleAccount');
      return email;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') {
        throw Exception('Google Sign-In was cancelled.');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    final db = _loadRegisteredUsers();
    return db.containsKey(email.trim().toLowerCase());
  }

  @override
  Future<void> reloadSession() async {
    _loadPersistedSession();
  }
}
