import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, AuthUser;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../../../core/services/cache_manager.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase;
  final _controller = StreamController<AuthState>.broadcast();
  AuthState _state = AuthState.initial();
  StreamSubscription? _authSub;

  SupabaseAuthRepository(this._prefs, this._supabase) {
    _init();
  }

  void _init() {
    // Listen to Supabase auth changes
    _authSub = _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final user = session?.user;
      if (user != null) {
        final authUser = _mapSupabaseUser(user);
        _state = AuthState.authenticated(authUser);
        await _migrateLocalData(user.email!);
        await syncPendingProfileUpload();
      } else {
        _state = AuthState.unauthenticated();
      }
      _controller.add(_state);
    });

    // Check initial session
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _state = AuthState.authenticated(_mapSupabaseUser(user));
      syncPendingProfileUpload();
    } else {
      _state = AuthState.unauthenticated();
    }
    _controller.add(_state);
  }

  AuthUser _mapSupabaseUser(User user) {
    return AuthUser(
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'] ?? 'User',
      fullName: user.userMetadata?['full_name'] ?? user.userMetadata?['display_name'] ?? '',
      joinDate: DateTime.parse(user.createdAt),
      isVerified: user.emailConfirmedAt != null,
      profileImagePath: user.userMetadata?['avatar_url'] ?? user.userMetadata?['profile_image_path'],
    );
  }

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  AuthState get currentAuthState => _state;

  @override
  Future<void> signIn(String email, String password) async {
    _controller.add(AuthState.loading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        final authUser = _mapSupabaseUser(response.user!);
        _state = AuthState.authenticated(authUser);
        _controller.add(_state);
        await _migrateLocalData(response.user!.email!);
        await syncPendingProfileUpload();
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login credentials')) {
        msg = 'Incorrect password or account not found';
      }
      _state = AuthState.unauthenticated(errorMessage: msg);
      _controller.add(_state);
      throw Exception(msg);
    } catch (e) {
      final msg = e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable';
      _state = AuthState.unauthenticated(errorMessage: msg);
      _controller.add(_state);
      throw Exception(msg);
    }
  }

  @override
  Future<void> signUp(String email, String password, String displayName) async {
    _controller.add(AuthState.loading());
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': displayName.trim(),
          'full_name': displayName.trim(),
        },
      );
      if (response.user != null) {
        final authUser = _mapSupabaseUser(response.user!);

        // Create profile record in database as fallback
        await _createProfileIfNotExists(
          userId: response.user!.id,
          email: response.user!.email!,
          fullName: displayName.trim(),
        );

        _state = AuthState.authenticated(authUser);
        _controller.add(_state);
        await _migrateLocalData(response.user!.email!);
        await syncPendingProfileUpload();
      }
    } on AuthException catch (e) {
      _state = AuthState.unauthenticated(errorMessage: e.message);
      _controller.add(_state);
      throw Exception(e.message);
    } catch (e) {
      final msg = e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable';
      _state = AuthState.unauthenticated(errorMessage: msg);
      _controller.add(_state);
      throw Exception(msg);
    }
  }

  @override
  Future<void> signOut() async {
    _controller.add(AuthState.loading());
    try {
      await _supabase.auth.signOut();
      _state = AuthState.unauthenticated();
      _controller.add(_state);
    } catch (e) {
      _state = AuthState.unauthenticated();
      _controller.add(_state);
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable');
    }
  }

  @override
  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Verification failed or server unavailable');
    }
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.signup,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Verification failed or server unavailable');
    }
  }

  @override
  Future<void> signInWithGoogle(String email, String displayName, {String? profileImagePath}) async {
    _controller.add(AuthState.loading());
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        _state = AuthState.unauthenticated(errorMessage: 'Google Sign-In was cancelled.');
        _controller.add(_state);
        throw Exception('Google Sign-In was cancelled.');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null) {
        throw Exception('Google Sign-In failed: No ID Token found.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        final authUser = _mapSupabaseUser(response.user!);

        // Create profile record in database as fallback
        await _createProfileIfNotExists(
          userId: response.user!.id,
          email: response.user!.email!,
          fullName: account.displayName ?? displayName,
          avatarUrl: account.photoUrl ?? profileImagePath,
        );

        _state = AuthState.authenticated(authUser);
        _controller.add(_state);
        await _migrateLocalData(response.user!.email!);
        await syncPendingProfileUpload();
      }
    } on AuthException catch (e) {
      _state = AuthState.unauthenticated(errorMessage: e.message);
      _controller.add(_state);
      throw Exception(e.message);
    } catch (e) {
      final msg = e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable';
      _state = AuthState.unauthenticated(errorMessage: msg);
      _controller.add(_state);
      throw Exception(msg);
    }
  }

  Future<void> _queueProfileUpload(String filePath) async {
    try {
      final queue = _prefs.getStringList('pending_profile_uploads') ?? [];
      if (!queue.contains(filePath)) {
        queue.add(filePath);
        await _prefs.setStringList('pending_profile_uploads', queue);
      }
    } catch (_) {}
  }

  Future<void> syncPendingProfileUpload() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final queue = _prefs.getStringList('pending_profile_uploads') ?? [];
      if (queue.isEmpty) return;

      final filePath = queue.first;
      final file = File(filePath);
      if (await file.exists()) {
        final extension = filePath.split('.').last;
        final path = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        await _supabase.storage.from('profile-images').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );
        
        final remoteUrl = _supabase.storage.from('profile-images').getPublicUrl(path);
        
        final bytes = await file.readAsBytes();
        await CacheManager.instance.saveFile(remoteUrl, bytes);

        await _supabase.auth.updateUser(
          UserAttributes(data: {
            'profile_image_path': remoteUrl,
            'avatar_url': remoteUrl,
          }),
        );
        await _supabase.from('profiles').update({
          'avatar_url': remoteUrl,
        }).eq('id', user.id);
      }
      
      queue.removeAt(0);
      await _prefs.setStringList('pending_profile_uploads', queue);
      
      if (queue.isNotEmpty) {
        await syncPendingProfileUpload();
      }
    } catch (_) {}
  }

  @override
  Future<void> updateProfile({String? displayName, String? profileImagePath, bool clearProfileImage = false}) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['display_name'] = displayName;
        updates['full_name'] = displayName;
      }

      String? activeProfilePath = profileImagePath;

      if (clearProfileImage) {
        updates['profile_image_path'] = null;
        updates['avatar_url'] = null;
      } else if (profileImagePath != null) {
        if (!profileImagePath.startsWith('http://') && !profileImagePath.startsWith('https://')) {
          // It's a local file path, attempt to upload to storage
          try {
            final file = File(profileImagePath);
            if (await file.exists()) {
              final user = _supabase.auth.currentUser;
              if (user != null) {
                final extension = profileImagePath.split('.').last;
                final path = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
                
                await _supabase.storage.from('profile-images').upload(
                  path,
                  file,
                  fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
                );
                
                final remoteUrl = _supabase.storage.from('profile-images').getPublicUrl(path);
                
                // Cache locally
                final bytes = await file.readAsBytes();
                await CacheManager.instance.saveFile(remoteUrl, bytes);

                activeProfilePath = remoteUrl;
              }
            }
          } catch (_) {
            // Upload failed (e.g. offline). Queue for later sync but proceed with local path
            await _queueProfileUpload(profileImagePath);
          }
        }
        updates['profile_image_path'] = activeProfilePath;
        updates['avatar_url'] = activeProfilePath;
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      if (response.user != null) {
        try {
          await _supabase.from('profiles').update({
            if (displayName != null) 'full_name': displayName,
            if (clearProfileImage) 'avatar_url': null,
            if (!clearProfileImage && activeProfilePath != null) 'avatar_url': activeProfilePath,
          }).eq('id', response.user!.id);
        } catch (_) {}

        final authUser = _mapSupabaseUser(response.user!);
        _state = AuthState.authenticated(authUser);
        _controller.add(_state);
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Update failed or server unavailable');
    }
  }

  @override
  Future<String?> pickGoogleAccount() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In was cancelled.');
      }
      return account.email;
    } catch (e) {
      if (e.toString().contains('sign_in_failed') || e.toString().contains('DEVELOPER_ERROR')) {
        throw Exception('Google Sign-In developer error: verify your GOOGLE_WEB_CLIENT_ID and package SHA-1 keys.');
      }
      rethrow;
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> reloadSession() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _state = AuthState.authenticated(_mapSupabaseUser(user));
      _controller.add(_state);
    }
  }

  @override
  Future<void> deleteAccount(String email) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiles').delete().eq('id', user.id);
      }
      await signOut();

      final lowercaseEmail = email.toLowerCase();
      await _prefs.remove('vault_items_$lowercaseEmail');
      await _prefs.remove('collections_$lowercaseEmail');
      await _prefs.remove('reminders_$lowercaseEmail');
      await _prefs.remove('trash_items_$lowercaseEmail');
      await _prefs.remove('recent_searches_$lowercaseEmail');
      await _prefs.remove('custom_link_categories_$lowercaseEmail');
      await _prefs.remove('theme_mode_$lowercaseEmail');
      await _prefs.remove('user_settings_$lowercaseEmail');
    } catch (_) {}
  }

  Future<void> _createProfileIfNotExists({
    required String userId,
    required String email,
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final existing = await _supabase.from('profiles').select('id').eq('id', userId).maybeSingle();
      if (existing == null) {
        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': fullName,
          'email': email,
          'avatar_url': avatarUrl,
          'join_date': DateTime.now().toIso8601String(),
          'settings': {
            'notificationsEnabled': true,
            'remindersEnabled': false,
            'autoSyncEnabled': true,
          },
        });
      }
    } catch (_) {}
  }

  Future<void> _migrateLocalData(String authenticatedEmail) async {
    final lowercaseEmail = authenticatedEmail.toLowerCase();

    const anonItemsKey = 'vault_items_anonymous';
    const anonColsKey = 'collections_anonymous';
    const anonRemindersKey = 'reminders_anonymous';
    const anonTrashKey = 'trash_items_anonymous';
    const anonSearchesKey = 'recent_searches_anonymous';
    const anonCategoriesKey = 'custom_link_categories_anonymous';
    const anonThemeKey = 'theme_mode_anonymous';
    const anonSettingsKey = 'user_settings_anonymous';

    // 1. Vault Items
    final anonItemsList = _prefs.getStringList(anonItemsKey) ?? [];
    if (anonItemsList.isNotEmpty) {
      final userItemsKey = 'vault_items_$lowercaseEmail';
      final userItemsList = _prefs.getStringList(userItemsKey) ?? [];

      final anonItems = anonItemsList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userItems = userItemsList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userIds = userItems.map((item) => item['id']).toSet();

      for (final item in anonItems) {
        if (!userIds.contains(item['id'])) {
          userItems.add(item);
        }
      }
      await _prefs.setStringList(userItemsKey, userItems.map((item) => jsonEncode(item)).toList());
    }

    // 2. Collections
    final anonColsList = _prefs.getStringList(anonColsKey) ?? [];
    if (anonColsList.isNotEmpty) {
      final userColsKey = 'collections_$lowercaseEmail';
      final userColsList = _prefs.getStringList(userColsKey) ?? [];
      final anonCols = anonColsList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userCols = userColsList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userColIds = userCols.map((c) => c['id']).toSet();

      for (final col in anonCols) {
        if (!userColIds.contains(col['id'])) {
          userCols.add(col);
        }
      }
      await _prefs.setStringList(userColsKey, userCols.map((c) => jsonEncode(c)).toList());
    }

    // 3. Reminders
    final anonRemindersList = _prefs.getStringList(anonRemindersKey) ?? [];
    if (anonRemindersList.isNotEmpty) {
      final userRemindersKey = 'reminders_$lowercaseEmail';
      final userRemindersList = _prefs.getStringList(userRemindersKey) ?? [];
      final anonReminders = anonRemindersList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userReminders = userRemindersList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userReminderIds = userReminders.map((r) => r['id']).toSet();

      for (final r in anonReminders) {
        if (!userReminderIds.contains(r['id'])) {
          userReminders.add(r);
        }
      }
      await _prefs.setStringList(userRemindersKey, userReminders.map((r) => jsonEncode(r)).toList());
    }

    // 4. Trash Items
    final anonTrashList = _prefs.getStringList(anonTrashKey) ?? [];
    if (anonTrashList.isNotEmpty) {
      final userTrashKey = 'trash_items_$lowercaseEmail';
      final userTrashList = _prefs.getStringList(userTrashKey) ?? [];
      final anonTrash = anonTrashList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userTrash = userTrashList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
      final userTrashIds = userTrash.map((item) => item['id']).toSet();

      for (final item in anonTrash) {
        if (!userTrashIds.contains(item['id'])) {
          userTrash.add(item);
        }
      }
      await _prefs.setStringList(userTrashKey, userTrash.map((item) => jsonEncode(item)).toList());
    }

    // 5. Recent Searches
    final anonSearches = _prefs.getStringList(anonSearchesKey) ?? [];
    if (anonSearches.isNotEmpty) {
      final userSearchesKey = 'recent_searches_$lowercaseEmail';
      final userSearches = _prefs.getStringList(userSearchesKey) ?? [];
      final mergedSearches = {...userSearches, ...anonSearches}.toList();
      await _prefs.setStringList(userSearchesKey, mergedSearches);
    }

    // 6. Custom Link Categories
    final anonCategories = _prefs.getStringList(anonCategoriesKey) ?? [];
    if (anonCategories.isNotEmpty) {
      final userCategoriesKey = 'custom_link_categories_$lowercaseEmail';
      final userCategories = _prefs.getStringList(userCategoriesKey) ?? [];
      final mergedCategories = {...userCategories, ...anonCategories}.toList();
      await _prefs.setStringList(userCategoriesKey, mergedCategories);
    }

    // 7. Theme Mode
    final anonTheme = _prefs.getString(anonThemeKey);
    if (anonTheme != null) {
      final userThemeKey = 'theme_mode_$lowercaseEmail';
      if (_prefs.getString(userThemeKey) == null) {
        await _prefs.setString(userThemeKey, anonTheme);
      }
    }

    // 8. User Settings
    final anonSettings = _prefs.getString(anonSettingsKey);
    if (anonSettings != null) {
      final userSettingsKey = 'user_settings_$lowercaseEmail';
      if (_prefs.getString(userSettingsKey) == null) {
        await _prefs.setString(userSettingsKey, anonSettings);
      }
    }

    // Clear anonymous local-only cache
    await _prefs.remove(anonItemsKey);
    await _prefs.remove(anonColsKey);
    await _prefs.remove(anonRemindersKey);
    await _prefs.remove(anonTrashKey);
    await _prefs.remove(anonSearchesKey);
    await _prefs.remove(anonCategoriesKey);
    await _prefs.remove(anonThemeKey);
    await _prefs.remove(anonSettingsKey);
  }

  void dispose() {
    _authSub?.cancel();
  }
}
