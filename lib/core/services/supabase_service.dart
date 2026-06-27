import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _initialized = false;
  String? _initError;

  bool get isInitialized => _initialized;
  String? get initError => _initError;

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase is not initialized. Check connection or .env config.');
    }
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception('Missing SUPABASE_URL in .env');
      }
      if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw Exception('Missing SUPABASE_ANON_KEY in .env');
      }

      // Simple URI parse to avoid crash in SDK on malformed strings
      final uri = Uri.tryParse(supabaseUrl);
      if (uri == null || !uri.hasAbsolutePath || !supabaseUrl.startsWith('http')) {
        throw Exception('Invalid SUPABASE_URL format: $supabaseUrl');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey, // ignore: deprecated_member_use
      );
      _initialized = true;
      _initError = null;
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      _initialized = false;
      _initError = e.toString();
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  // Common getters
  GoTrueClient get auth => client.auth;
  SupabaseQueryBuilder from(String table) => client.from(table);
  SupabaseStorageClient get storage => client.storage;
  RealtimeClient get realtime => client.realtime;
}
