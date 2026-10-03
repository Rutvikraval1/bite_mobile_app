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

  // ── Firebase (push notifications) ──
  // Values from the Firebase console → Project settings → Your apps.
  static const _fbApiKeyAndroid = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const _fbAppIdAndroid = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const _fbApiKeyIos = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _fbAppIdIos = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _fbIosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const _fbProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _fbSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _fbStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static String get firebaseAndroidApiKey =>
      _pick(_fbApiKeyAndroid, 'FIREBASE_ANDROID_API_KEY');
  static String get firebaseAndroidAppId =>
      _pick(_fbAppIdAndroid, 'FIREBASE_ANDROID_APP_ID');
  static String get firebaseIosApiKey =>
      _pick(_fbApiKeyIos, 'FIREBASE_IOS_API_KEY');
  static String get firebaseIosAppId => _pick(_fbAppIdIos, 'FIREBASE_IOS_APP_ID');
  static String get firebaseIosBundleId =>
      _pick(_fbIosBundleId, 'FIREBASE_IOS_BUNDLE_ID');
  static String get firebaseProjectId =>
      _pick(_fbProjectId, 'FIREBASE_PROJECT_ID');
  static String get firebaseMessagingSenderId =>
      _pick(_fbSenderId, 'FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseStorageBucket =>
      _pick(_fbStorageBucket, 'FIREBASE_STORAGE_BUCKET');

  // ── Support / sharing ──
  static const _supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const _inviteUrl = String.fromEnvironment('INVITE_URL');

  static String get supportEmail => _pick(_supportEmail, 'SUPPORT_EMAIL');
  static String get inviteUrl => _pick(_inviteUrl, 'INVITE_URL');

  /// Compile-time value wins; otherwise the runtime `.env` value.
  static String _pick(String compile, String name) =>
      compile.isNotEmpty ? compile : (_runtime(name) ?? '');

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
