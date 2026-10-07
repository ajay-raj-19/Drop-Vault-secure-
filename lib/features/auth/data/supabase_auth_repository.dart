import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<Map<String, String?>> _getProfileData(String userId) async {
    try {
      final res = await _supabase.from('profiles').select('full_name, avatar_url').eq('id', userId).maybeSingle().timeout(const Duration(seconds: 10));
      if (res != null) {
        return {
          'full_name': res['full_name'] as String?,
          'avatar_url': res['avatar_url'] as String?,
        };
      }
    } catch (_) {}
    return {'full_name': null, 'avatar_url': null};
  }

  bool _disposed = false;
  bool _syncingProfile = false;
  int _sessionVersion = 0;

  void _emit(AuthState state) {
    if (_disposed) return;
    _state = state;
    _controller.add(state);
  }

  void _acceptSession(User? user) {
    final version = ++_sessionVersion;
    if (user == null) {
      _emit(AuthState.unauthenticated());
      return;
    }
    // Authentication must not wait for optional profile/storage requests.
    _emit(AuthState.authenticated(_mapSupabaseUser(
      user,
      fullName: _prefs.getString('cached_full_name_${user.email}'),
      avatarUrl: _prefs.getString('cached_avatar_url_${user.email}'),
    )));
    unawaited(_loadProfile(user, version));
  }

  void _init() {
    _acceptSession(_supabase.auth.currentUser);
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      _acceptSession(data.session?.user);
    }, onError: (Object error) {
      // A transient refresh failure must not discard a persisted session.
      if (_supabase.auth.currentSession == null) {
        _emit(AuthState.unauthenticated(errorMessage: 'Session expired. Please sign in again.'));
      }
    });
  }

  Future<void> _loadProfile(User user, int version) async {
    try {
      final profile = await _getProfileData(user.id);
      if (_disposed || version != _sessionVersion ||
          _supabase.auth.currentUser?.id != user.id) {
        return;
      }
      if (profile['full_name'] != null) {
        await _prefs.setString('cached_full_name_${user.email}', profile['full_name']!);
      }
      if (profile['avatar_url'] != null) {
        await _prefs.setString('cached_avatar_url_${user.email}', profile['avatar_url']!);
      }
      if (_disposed || version != _sessionVersion) return;
      _emit(AuthState.authenticated(_mapSupabaseUser(
        user,
        fullName: profile['full_name'] ?? _prefs.getString('cached_full_name_${user.email}'),
        avatarUrl: profile['avatar_url'] ?? _prefs.getString('cached_avatar_url_${user.email}'),
      )));
    } catch (_) {
      // Profile/cache failures do not invalidate authentication.
    }
  }

  Future<void> _afterSignIn(User user) async {
    try {
      if (_supabase.auth.currentUser?.id != user.id) return;
      if (user.email != null) await _migrateLocalData(user.email!);
      if (_supabase.auth.currentUser?.id != user.id) return;
      await _createProfileIfNotExists(
        userId: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? user.userMetadata?['display_name'] ?? '',
        avatarUrl: user.userMetadata?['avatar_url'],
      );
      if (_supabase.auth.currentUser?.id == user.id) await syncPendingProfileUpload();
    } catch (_) {
      // Best-effort migration must never turn a successful login into an error.
    }
  }

  AuthUser _mapSupabaseUser(User user, {String? fullName, String? avatarUrl}) {
    return AuthUser(
      email: user.email ?? '',
      displayName: fullName ?? user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'] ?? 'User',
      fullName: fullName ?? user.userMetadata?['full_name'] ?? user.userMetadata?['display_name'] ?? '',
      joinDate: DateTime.parse(user.createdAt),
      isVerified: user.emailConfirmedAt != null,
      profileImagePath: avatarUrl ?? user.userMetadata?['avatar_url'] ?? user.userMetadata?['profile_image_path'],
    );
  }

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  AuthState get currentAuthState => _state;

  @override
  Future<void> signIn(String email, String password) async {
    _emit(AuthState.loading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null || response.user == null) {
        throw const AuthException('No session returned. Please sign in again.');
      }
      _acceptSession(response.user);
      unawaited(_afterSignIn(response.user!));
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login credentials')) {
        msg = 'Incorrect password or account not found';
      }
      _state = AuthState.unauthenticated(errorMessage: msg);
      _emit(_state);
      throw Exception(msg);
    } catch (e) {
      final msg = e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable';
      _state = AuthState.unauthenticated(errorMessage: msg);
      _emit(_state);
      throw Exception(msg);
    }
  }

  @override
  Future<void> signUp(String email, String password, String displayName) async {
    _emit(AuthState.loading());
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: 'dropvault://login-callback',
        data: {
          'display_name': displayName.trim(),
          'full_name': displayName.trim(),
        },
      );
      if (response.session == null) {
        _emit(AuthState.unauthenticated());
        return; // Email confirmation is required before a session exists.
      }
      _acceptSession(response.user);
      if (response.user != null) unawaited(_afterSignIn(response.user!));
    } on AuthException catch (e) {
      _state = AuthState.unauthenticated(errorMessage: e.message);
      _emit(_state);
      throw Exception(e.message);
    } catch (e) {
      final msg = e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable';
      _state = AuthState.unauthenticated(errorMessage: msg);
      _emit(_state);
      throw Exception(msg);
    }
  }

  @override
  Future<void> signOut() async {
    _emit(AuthState.loading());
    try {
      await _supabase.auth.signOut();
      _state = AuthState.unauthenticated();
      _emit(_state);
    } catch (e) {
      _state = AuthState.unauthenticated();
      _emit(_state);
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'dropvault://reset-password',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString().contains('SocketException') ? 'Network unavailable' : 'Server unavailable');
    }
  }

  @override
  Future<void> updatePassword(String email, String newPassword) async {
    try {
      debugPrint('=== UPDATE PASSWORD ===');
      debugPrint('Updating password for: $email');
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('Password update success. Signing out of temporary recovery session...');
      await _supabase.auth.signOut();
      debugPrint('Password Update Done');
      debugPrint('=======================');
    } on AuthException catch (e) {
      debugPrint('Password Update Failure (AuthException): ${e.message}');
      debugPrint('===================================================');
      throw Exception(e.message);
    } catch (e, stack) {
      debugPrint('Password Update Failure (Exception): $e\n$stack');
      debugPrint('===============================================');
      throw Exception('Failed to update password. Please try again.');
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
    _emit(AuthState.loading());
    try {
      final bool isWindows = !kIsWeb && Platform.isWindows;
      if (isWindows) {
        await _pickGoogleAccountWindows();
        _acceptSession(_supabase.auth.currentUser);
        return; // The callback establishes the session.
      }

      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final String currentPlatform = kIsWeb ? 'Web' : Platform.operatingSystem;
      final bool isAndroid = !kIsWeb && Platform.isAndroid;

      // Platform-specific GoogleSignIn configuration
      // Android: Do NOT pass clientId — it causes DEVELOPER_ERROR.
      //          Android uses Google Play Services config and needs serverClientId.
      // iOS/Web: Use clientId (the Web Client ID).
      final GoogleSignIn googleSignIn;
      if (isAndroid) {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: webClientId,
        );
      } else {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: webClientId,
        );
      }

      // Pre-signIn diagnostics
      debugPrint('=== GOOGLE SIGN-IN PRE-FLIGHT ===');
      debugPrint('Platform: $currentPlatform');
      debugPrint('clientId value: $webClientId');
      debugPrint('GoogleSignIn config: isAndroid=$isAndroid, using ${isAndroid ? "serverClientId" : "clientId"}');
      debugPrint('Package Name: com.example.drop_vault');
      debugPrint('SHA-1: (configured in Firebase/Google Cloud Console)');
      debugPrint('=================================');

      final account = await googleSignIn.signIn();
      if (account == null) {
        _state = AuthState.unauthenticated(errorMessage: 'Google Sign-In was cancelled.');
        _emit(_state);
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

      if (response.session == null || response.user == null) {
        throw const AuthException('Google Sign-In did not return a session.');
      }
      _acceptSession(response.user);
      unawaited(_afterSignIn(response.user!));
    } on AuthException catch (e, stackTrace) {
      debugPrint('=== GOOGLE SIGN-IN FAILURE (AuthException) ===');
      debugPrint('Error: ${e.message}');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('===============================================');
      _state = AuthState.unauthenticated(errorMessage: e.message);
      _emit(_state);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      debugPrint('=== GOOGLE SIGN-IN FAILURE ===');
      debugPrint('Error: $e');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('==============================');
      final msg = e.toString().contains('SocketException') ? 'Network unavailable' : e.toString();
      _state = AuthState.unauthenticated(errorMessage: msg);
      _emit(_state);
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
    if (user == null || _syncingProfile) return;
    _syncingProfile = true;
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
      
    } catch (_) {
      // Keep failed uploads queued for a later retry.
    } finally {
      _syncingProfile = false;
    }
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

        final profileData = await _getProfileData(response.user!.id);

        // Cache the profile details
        final email = response.user!.email;
        if (email != null) {
          if (profileData['full_name'] != null) {
            await _prefs.setString('cached_full_name_$email', profileData['full_name']!);
          }
          if (clearProfileImage) {
            await _prefs.remove('cached_avatar_url_$email');
          } else if (profileData['avatar_url'] != null) {
            await _prefs.setString('cached_avatar_url_$email', profileData['avatar_url']!);
          }
        }

        final cachedFullName = email != null ? _prefs.getString('cached_full_name_$email') : null;
        final cachedAvatarUrl = email != null ? _prefs.getString('cached_avatar_url_$email') : null;

        final authUser = _mapSupabaseUser(
          response.user!,
          fullName: profileData['full_name'] ?? cachedFullName ?? displayName ?? response.user!.userMetadata?['full_name'],
          avatarUrl: clearProfileImage ? null : (profileData['avatar_url'] ?? cachedAvatarUrl ?? activeProfilePath),
        );
        _state = AuthState.authenticated(authUser);
        _emit(_state);
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
      final bool isWindows = !kIsWeb && Platform.isWindows;
      if (isWindows) {
        return await _pickGoogleAccountWindows();
      }

      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final bool isAndroid = !kIsWeb && Platform.isAndroid;

      // Platform-specific GoogleSignIn configuration
      final GoogleSignIn googleSignIn;
      if (isAndroid) {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: webClientId,
        );
      } else {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: webClientId,
        );
      }

      debugPrint('=== PICK GOOGLE ACCOUNT PRE-FLIGHT ===');
      debugPrint('Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
      debugPrint('Using ${isAndroid ? "serverClientId" : "clientId"}: $webClientId');
      debugPrint('=======================================');

      final account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In was cancelled.');
      }
      return account.email;
    } catch (e, stackTrace) {
      debugPrint('=== PICK GOOGLE ACCOUNT FAILURE ===');
      debugPrint('Error: $e');
      debugPrint('Stack Trace:\n$stackTrace');
      debugPrint('===================================');
      if (e.toString().contains('sign_in_failed') || e.toString().contains('DEVELOPER_ERROR')) {
        throw Exception('Google Sign-In developer error: verify your GOOGLE_WEB_CLIENT_ID and package SHA-1 keys.');
      }
      rethrow;
    }
  }

  Future<String?> _pickGoogleAccountWindows() async {
    try {
      debugPrint('[Windows Google Sign-In] Launching OAuth in browser with custom URI scheme redirect...');
      const redirectUrl = 'dropvault://google-callback';
      
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      
      if (!response) {
        throw Exception('Failed to launch the browser for Google Sign-In.');
      }
      
      debugPrint('[Windows Google Sign-In] Browser launched successfully. Waiting for deep link callback...');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Windows Google Sign-In] Exception in flow: $e\n$stackTrace');
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
    _acceptSession(_supabase.auth.currentUser);
  }

  @override
  Future<void> exchangeCodeForSession(String code) async {
    final response = await _supabase.auth.exchangeCodeForSession(code);
    _acceptSession(response.session.user);
    unawaited(_afterSignIn(response.session.user));
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
      final existing = await _supabase.from('profiles').select('id').eq('id', userId).maybeSingle().timeout(const Duration(seconds: 10));
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
    _disposed = true;
    ++_sessionVersion;
    _authSub?.cancel();
    _controller.close();
  }
}
