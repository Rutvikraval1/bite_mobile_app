import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/supabase_client_provider.dart';
import 'table_names.dart';

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

/// The XP level ladder. Loaded from the `xp_tiers` table at startup
/// ([load]), cached on the device, and falling back to [defaults] when the
/// table is unreachable or empty.
abstract final class TierDefinitions {
  static const List<XpTier> defaults = [
    XpTier(min: 0, max: 10, level: 1, name: 'Curious', emoji: '👀', color: Color(0xFF64B5F6)),
    XpTier(min: 10, max: 30, level: 2, name: 'Beginner', emoji: '🥄', color: Color(0xFF4CAF50)),
    XpTier(min: 30, max: 75, level: 3, name: 'Home Cook', emoji: '🍳', color: AppColors.coral),
    XpTier(min: 75, max: 150, level: 4, name: 'Sous Chef', emoji: '🧑‍🍳', color: AppColors.placesPurple),
    XpTier(min: 150, max: 300, level: 5, name: 'Chef', emoji: '👨‍🍳', color: AppColors.amber),
    XpTier(min: 300, max: 600, level: 6, name: 'Master Chef', emoji: '⭐', color: Color(0xFF9C27B0)),
    XpTier(min: 600, max: 99999, level: 7, name: 'b🌶te Legend', emoji: '🔥', color: Color(0xFFFFD700)),
  ];

  static const String _cacheKey = 'xp_tiers_v1';

  static List<XpTier> _all = defaults;

  /// Every level, lowest first.
  static List<XpTier> get all => _all;

  /// Bumped whenever the ladder changes, so widgets can rebuild.
  static final ValueNotifier<int> version = ValueNotifier(0);

  /// Applies the device cache right away, then refreshes from Supabase.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        _apply(fromRows((jsonDecode(cached) as List).cast<Map<String, dynamic>>()));
      }
      final rows = await SupabaseClientProvider.instance.client
          .from(TableNames.xpTiers)
          .select('level, name, emoji, min_xp, color')
          .order('min_xp');
      final list = (rows as List).cast<Map<String, dynamic>>();
      if (_apply(fromRows(list))) {
        await prefs.setString(_cacheKey, jsonEncode(list));
      }
    } catch (e) {
      // Table missing (migration not applied) or offline — keep what we have.
      debugPrint('[tiers] load failed, using ${_all == defaults ? 'defaults' : 'cache'}: $e');
    }
  }

  /// Builds the ladder from `xp_tiers` rows; each level ends where the next
  /// begins. Invalid rows are skipped; returns empty if nothing usable.
  @visibleForTesting
  static List<XpTier> fromRows(List<Map<String, dynamic>> rows) {
    final parsed = <({int level, String name, String emoji, int min, Color color})>[];
    for (final r in rows) {
      final level = (r['level'] as num?)?.toInt();
      final min = (r['min_xp'] as num?)?.toInt();
      final name = (r['name'] as String?)?.trim() ?? '';
      if (level == null || min == null || min < 0 || name.isEmpty) continue;
      parsed.add((
        level: level,
        name: name,
        emoji: (r['emoji'] as String?) ?? '⭐',
        min: min,
        color: _parseColor(r['color'] as String?) ?? AppColors.coral,
      ));
    }
    parsed.sort((a, b) => a.min.compareTo(b.min));
    if (parsed.isEmpty || parsed.first.min != 0) return const [];
    return [
      for (var i = 0; i < parsed.length; i++)
        XpTier(
          min: parsed[i].min,
          max: i + 1 < parsed.length ? parsed[i + 1].min : 99999,
          level: parsed[i].level,
          name: parsed[i].name,
          emoji: parsed[i].emoji,
          color: parsed[i].color,
        ),
    ];
  }

  static bool _apply(List<XpTier> tiers) {
    if (tiers.isEmpty) return false;
    _all = List.unmodifiable(tiers);
    version.value++;
    return true;
  }

  static Color? _parseColor(String? hex) {
    final h = hex?.replaceFirst('#', '');
    if (h == null || h.length != 6) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

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
