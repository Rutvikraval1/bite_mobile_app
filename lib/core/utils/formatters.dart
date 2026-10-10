/// Display formatters shared across features.
abstract final class Formatters {
  /// Parse a compact count like `"1.2K"` or `"890"` to a double.
  static double numOf(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) return 0;
    if (trimmed.endsWith('K')) {
      return (double.tryParse(trimmed.substring(0, trimmed.length - 1)) ?? 0) *
          1000;
    }
    if (trimmed.endsWith('M')) {
      return (double.tryParse(trimmed.substring(0, trimmed.length - 1)) ?? 0) *
          1000000;
    }
    return double.tryParse(trimmed) ?? 0;
  }

  /// Compact count: 890 → "890", 2100 → "2.1K", 1200000 → "1.2M".
  static String compact(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  /// Short relative age: "now", "12m", "3h", "2d", "5w".
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}w';
  }

  /// mm:ss from seconds.
  static String mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Convert seconds to a compact "3m 20s" string.
  static String duration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  /// Grade for pace ratio: fast vs slow chef.
  static String paceGrade(double ratio) {
    if (ratio <= 0.8) return 'Lightning Chef';
    if (ratio <= 1.0) return 'Right on Pace';
    return 'Slow & Steady';
  }
}
