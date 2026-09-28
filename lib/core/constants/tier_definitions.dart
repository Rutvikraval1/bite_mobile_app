import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// XP tier ladder — ported from the prototype shell.
class XpTier {
  const XpTier({
    required this.min,
    required this.max,
    required this.level,
    required this.name,
    required this.emoji,
    required this.color,
  });

  final int min;
  final int max;
  final int level;
  final String name;
  final String emoji;
  final Color color;
}

abstract final class TierDefinitions {
  static const List<XpTier> all = [
    XpTier(min: 0, max: 10, level: 1, name: 'Curious', emoji: '👀', color: Color(0xFF64B5F6)),
    XpTier(min: 10, max: 30, level: 2, name: 'Beginner', emoji: '🥄', color: Color(0xFF4CAF50)),
    XpTier(min: 30, max: 75, level: 3, name: 'Home Cook', emoji: '🍳', color: AppColors.coral),
    XpTier(min: 75, max: 150, level: 4, name: 'Sous Chef', emoji: '🧑‍🍳', color: AppColors.placesPurple),
    XpTier(min: 150, max: 300, level: 5, name: 'Chef', emoji: '👨‍🍳', color: AppColors.amber),
    XpTier(min: 300, max: 600, level: 6, name: 'Master Chef', emoji: '⭐', color: Color(0xFF9C27B0)),
    XpTier(min: 600, max: 99999, level: 7, name: 'b🌶te Legend', emoji: '🔥', color: Color(0xFFFFD700)),
  ];

  static XpTier tierFor(int xp) {
    for (final tier in all) {
      if (xp >= tier.min && xp < tier.max) return tier;
    }
    return all.last;
  }

  /// Progress (0..1) of [xp] within its current tier.
  static double progressInTier(int xp) {
    final tier = tierFor(xp);
    final span = (tier.max - tier.min).toDouble();
    if (span <= 0) return 1;
    return ((xp - tier.min) / span).clamp(0.0, 1.0);
  }
}
