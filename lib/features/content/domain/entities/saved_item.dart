import 'package:flutter/foundation.dart';

/// A user's saved item — mirrors the `saved_items` table.
@immutable
class SavedItem {
  const SavedItem({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.title,
    required this.emoji,
    this.imageUrl,
    this.cuisine,
    this.createdAt,
    this.creator = '',
    this.color,
    this.liked = true,
    this.favorited = false,
    this.daysLeft,
  });

  final String id;
  final String itemType; // food | drink | place
  final int itemId;
  final String title;
  final String emoji;
  final String? imageUrl;
  final String? cuisine;
  final DateTime? createdAt;

  // ── Demo-only fields (seed saved items) ──
  final String creator;
  final int? color;
  final bool liked;
  final bool favorited;
  final int? daysLeft;

  SavedItem copyWith({
    String? itemType,
    String? title,
    bool? liked,
    bool? favorited,
    int? daysLeft,
  }) {
    return SavedItem(
      id: id,
      itemType: itemType ?? this.itemType,
      itemId: itemId,
      title: title ?? this.title,
      emoji: emoji,
      imageUrl: imageUrl,
      cuisine: cuisine,
      createdAt: createdAt,
      creator: creator,
      color: color,
      liked: liked ?? this.liked,
      favorited: favorited ?? this.favorited,
      daysLeft: daysLeft ?? this.daysLeft,
    );
  }
}
