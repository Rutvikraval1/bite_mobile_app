import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads configuration from two sources:
///
/// 1. Build-time `--dart-define-from-file=.env` (values land in
///    `String.fromEnvironment`).
/// 2. Runtime `.env` loaded from the asset bundle via [dotenv], so the app
///    works even when launched without the compile-time flag (e.g. from an
///    IDE that isn't configured to pass it).
///
/// Compile-time values win when present; otherwise the runtime values are used.
///
/// Secrets must never be committed. Only the anon/public Supabase key is used
/// at runtime; the real security boundary is the database RLS policies.
abstract final class AppEnv {
  static const String _compileUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _compileAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get supabaseUrl {
    final fromEnv = _runtime('SUPABASE_URL');
    return _compileUrl.isNotEmpty ? _compileUrl : (fromEnv ?? '');
  }

  static String get supabaseAnonKey {
    final fromEnv = _runtime('SUPABASE_ANON_KEY');
    return _compileAnonKey.isNotEmpty ? _compileAnonKey : (fromEnv ?? '');
  }

  static const String _compileTermsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: '',
  );

  static const String _compilePrivacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '',
  );

  static String get termsUrl {
    final fromEnv = _runtime('TERMS_URL');
    return _compileTermsUrl.isNotEmpty ? _compileTermsUrl : (fromEnv ?? '');
  }

  static String get privacyPolicyUrl {
    final fromEnv = _runtime('PRIVACY_POLICY_URL');
    return _compilePrivacyPolicyUrl.isNotEmpty
        ? _compilePrivacyPolicyUrl
        : (fromEnv ?? '');
  }

  /// Runtime lookup that tolerates a missing/failed `.env` load (dotenv
  /// throws NotInitializedError when read before a successful load).
  static String? _runtime(String name) =>
      dotenv.isInitialized ? dotenv.maybeGet(name) : null;

  static const String demoKey = String.fromEnvironment(
    'DEMO_KEY',
    defaultValue: 'bite.me2026',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Fail loudly in debug when misconfigured so issues surface immediately.
  static void validate() {
    if (!hasSupabaseConfig) {
      debugPrint(
        '[bite] Missing Supabase env vars. Set SUPABASE_URL and '
        'SUPABASE_ANON_KEY in .env and pass --dart-define-from-file=.env',
      );
    }
  }
}
