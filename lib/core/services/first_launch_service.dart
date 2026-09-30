import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the app has been opened before, so the welcome gate is
/// shown only on the very first launch.
class FirstLaunchService {
  FirstLaunchService._();

  static final FirstLaunchService instance = FirstLaunchService._();

  static const _key = 'welcome_seen';

  bool _isFirstLaunch = false;

  /// Valid after [load]. Defaults to false if prefs can't be read.
  bool get isFirstLaunch => _isFirstLaunch;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstLaunch = !(prefs.getBool(_key) ?? false);
    } catch (e) {
      debugPrint('[bite] FirstLaunchService.load failed: $e');
    }
  }

  Future<void> markWelcomeSeen() async {
    _isFirstLaunch = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      debugPrint('[bite] FirstLaunchService.markWelcomeSeen failed: $e');
    }
  }
}
