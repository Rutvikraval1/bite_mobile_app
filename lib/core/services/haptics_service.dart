import 'package:flutter/services.dart';

/// Thin wrapper around platform haptics.
abstract final class HapticsService {
  static Future<void> light() => HapticFeedback.lightImpact();

  static Future<void> medium() => HapticFeedback.mediumImpact();

  static Future<void> heavy() => HapticFeedback.heavyImpact();

  static Future<void> selection() => HapticFeedback.selectionClick();
}
