import 'package:flutter/material.dart';

import 'app_env.dart';

/// Central place for app-wide non-secret configuration.
abstract final class AppConfig {
  static const String appName = 'b🌶te';

  static const String tagline = 'swipe. taste. share.';

  static const String versionLabel = 'v1.0 PROTOTYPE';

  /// Max prototype canvas width (mirrors the web app's 430px frame).
  static const double maxFrameWidth = 430;

  /// Rounded corners applied when the frame is displayed on wide screens.
  static const double frameRadius = 32;

  /// Public anon key (safe to embed; RLS is the security boundary).
  static String get supabaseUrl => AppEnv.supabaseUrl;

  static String get supabaseAnonKey => AppEnv.supabaseAnonKey;

  static String get demoKey => AppEnv.demoKey;

  /// Shared demo unlock flag key for the demo gate.
  static String demoUnlockFlag() => 'bite_demo_unlocked_$demoKey';

  static const List<Color> brandGradientColors = [
    Color(0xFFF5A623),
    Color(0xFFFF6B6B),
  ];
}
