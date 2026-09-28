import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../config/app_env.dart';
import '../errors/app_exception.dart';

/// Owns the single [SupabaseClient] instance for the app.
/// No other module may create a Supabase client directly.
class SupabaseClientProvider {
  SupabaseClientProvider._();

  static final SupabaseClientProvider instance = SupabaseClientProvider._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initializes the singleton. Safe to call once at startup.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!AppEnv.hasSupabaseConfig) {
      throw const AuthException(
        'Missing Supabase env vars. Set SUPABASE_URL and '
        'SUPABASE_ANON_KEY via --dart-define-from-file=.env',
      );
    }
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabaseAnonKey,
      debug: false,
    );
    _initialized = true;
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError('SupabaseClientProvider.initialize() must be called first.');
    }
    return Supabase.instance.client;
  }

  GoTrueClient get auth => client.auth;
}
