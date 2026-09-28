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
