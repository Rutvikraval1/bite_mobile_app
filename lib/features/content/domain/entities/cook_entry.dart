import 'package:flutter/foundation.dart';

/// One row of `cook_history` — a recipe the user marked as cooked.
@immutable
class CookEntry {
  const CookEntry({
    required this.id,
    required this.title,
    required this.emoji,
    required this.cookedAt,
    this.recipeId,
    this.imageUrl,
    this.rating,
  });

  final String id;
  final int? recipeId;
  final String title;
  final String emoji;
  final String? imageUrl;
  final int? rating;
  final DateTime cookedAt;

  factory CookEntry.fromRow(Map<String, dynamic> r) => CookEntry(
    id: r['id'] as String,
    recipeId: (r['recipe_id'] as num?)?.toInt(),
    title: (r['title'] as String?) ?? '',
    emoji: (r['emoji'] as String?) ?? '🍽',
    imageUrl: r['image_url'] as String?,
    rating: (r['rating'] as num?)?.toInt(),
    cookedAt:
        DateTime.tryParse(r['cooked_at']?.toString() ?? '') ?? DateTime.now(),
  );
}
