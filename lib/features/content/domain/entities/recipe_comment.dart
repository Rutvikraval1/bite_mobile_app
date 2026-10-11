import 'package:flutter/foundation.dart';

/// A comment on a recipe or drink (`public.recipe_comments`).
@immutable
class RecipeComment {
  const RecipeComment({
    required this.id,
    required this.userId,
    required this.authorHandle,
    required this.body,
    required this.createdAt,
    this.avatarEmoji = '🧑‍🍳',
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String authorHandle;
  final String body;
  final DateTime createdAt;
  final String avatarEmoji;
  final String? avatarUrl;

  static const String select =
      'id, user_id, author_handle, body, created_at, creator:creators(avatar_emoji, avatar_url)';

  factory RecipeComment.fromRow(Map<String, dynamic> r) {
    final creator = (r['creator'] as Map?)?.cast<String, dynamic>();
    final emoji = creator?['avatar_emoji'] as String?;
    return RecipeComment(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      authorHandle: r['author_handle'] as String,
      body: (r['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      avatarEmoji: (emoji == null || emoji.isEmpty) ? '🧑‍🍳' : emoji,
      avatarUrl: creator?['avatar_url'] as String?,
    );
  }
}
