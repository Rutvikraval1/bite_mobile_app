import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Parses a CSS `linear-gradient(...)` string (as stored in seed data /
/// Supabase rows) into a Flutter [LinearGradient].
///
/// Example input:
/// `linear-gradient(160deg, #1a0505 0%, #4a0a0a 30%, #8B1A1A 60%, #CC3333 100%)`
class GradientSpec {
  GradientSpec._(this.angleDeg, this.stops);

  final double angleDeg;
  final List<(Color, double)> stops;

  static final Map<String, GradientSpec> _cache = {};

  /// Returns the parsed spec, or `null` when [css] isn't a parseable gradient.
  static GradientSpec? tryParse(String css) {
    if (css.isEmpty) return null;
    final cached = _cache[css];
    if (cached != null) return cached;

    final match = RegExp(
      r'linear-gradient\(\s*([-\d.]+)deg\s*,\s*(.+)\)',
    ).firstMatch(css);
    if (match == null) return null;

    final angle = double.tryParse(match.group(1)!);
    if (angle == null) return null;

    final stops = <(Color, double)>[];
    final stopPattern = RegExp(
      r'#([0-9A-Fa-f]{6})\s*([\d.]+)?%?',
    );
    for (final part in match.group(2)!.split(',')) {
      final m = stopPattern.firstMatch(part.trim());
      if (m == null) continue;
      final color = Color(int.parse(m.group(1)!, radix: 16) | 0xFF000000);
      final stop = double.tryParse(m.group(2) ?? '');
      stops.add((color, stop ?? 0));
    }
    if (stops.isEmpty) return null;

    // Sort by position and sanitize.
    stops.sort((a, b) => a.$2.compareTo(b.$2));
    final spec = GradientSpec._(angle, stops);
    _cache[css] = spec;
    return spec;
  }

  /// Converts to a Flutter gradient. CSS angle maps: 0° = to-top, 90° = to-right.
  LinearGradient toLinear({List<Color>? overrideColors}) {
    final rad = angleDeg * math.pi / 180;
    final dx = math.cos(rad);
    final dy = math.sin(rad);
    final colors = overrideColors ?? [for (final s in stops) s.$1];
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: colors,
      stops: [for (final s in stops) s.$2 / 100],
    );
  }
}
