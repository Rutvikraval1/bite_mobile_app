import 'package:flutter/foundation.dart';

/// Form payload for creating a user recipe (Profile → New Recipe).
@immutable
class RecipeDraft {
  const RecipeDraft({
    required this.title,
    this.description = '',
    this.imageUrl,
    this.emoji = '🍽',
    this.cuisine = 'Various',
    this.timeMin = '',
    this.difficulty = 'Easy',
    this.serves = 2,
    this.heatLevel = 0,
    this.tags = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.publish = true,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final String emoji;
  final String cuisine;
  final String timeMin;
  final String difficulty;
  final int serves;
  final int heatLevel;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;

  /// false saves as a private draft.
  final bool publish;

  Map<String, dynamic> toRow({
    required String authorId,
    required String creator,
  }) => {
    'author_id': authorId,
    'creator': creator,
    'title': title.trim(),
    'description': description.trim(),
    'image_url': imageUrl,
    'emoji': emoji,
    'cuisine': cuisine,
    'time_min': timeMin,
    'difficulty': difficulty,
    'serves': serves,
    'heat_level': heatLevel,
    'tags': tags,
    'ingredients': ingredients,
    'steps': steps,
    'status': publish ? 'published' : 'draft',
  };
}
