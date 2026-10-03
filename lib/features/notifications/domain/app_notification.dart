import 'package:flutter/foundation.dart';

/// One row of `public.notifications`.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.emoji,
    required this.createdAt,
    this.actionDest,
    this.data = const {},
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String emoji;

  /// AppScreen name to open when tapped (e.g. `recipeDetail`).
  final String? actionDest;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  int? get recipeId => (data['recipe_id'] as num?)?.toInt();

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    emoji: emoji,
    createdAt: createdAt,
    actionDest: actionDest,
    data: data,
    readAt: readAt ?? DateTime.now(),
  );

  factory AppNotification.fromRow(Map<String, dynamic> r) => AppNotification(
    id: r['id'] as String,
    type: (r['type'] as String?) ?? 'system',
    title: (r['title'] as String?) ?? '',
    body: (r['body'] as String?) ?? '',
    emoji: (r['emoji'] as String?) ?? '🔔',
    actionDest: r['action_dest'] as String?,
    data: (r['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    readAt: r['read_at'] != null
        ? DateTime.tryParse(r['read_at'].toString())
        : null,
    createdAt:
        DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
  );
}
