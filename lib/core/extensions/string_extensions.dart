import 'package:intl/intl.dart';

/// String helpers shared across features.
extension StringX on String {
  /// Lowercases and strips characters outside `[a-z0-9_]` (username rules).
  String toUsernameSafe() =>
      toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');

  /// Strip a leading '@'.
  String withoutAt() => startsWith('@') ? substring(1) : this;

  bool get isBlank => trim().isEmpty;
}

/// DateTime helpers.
extension DateTimeX on DateTime {
  /// Friendly relative time ("5d ago", "3h ago") matching the JS `timeAgo`.
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(this);
  }

  /// Format as `yyyy-MM-dd` (used for `plan_date`, `dob`).
  String toIsoDate() => DateFormat('yyyy-MM-dd').format(this);
}

/// Iterable helpers.
extension IterableX<T> on Iterable<T> {
  /// Deduplicate while preserving order.
  List<T> unique() {
    final seen = <T>{};
    final result = <T>[];
    for (final item in this) {
      if (seen.add(item)) result.add(item);
    }
    return result;
  }
}
