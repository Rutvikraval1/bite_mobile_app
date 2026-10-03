import 'package:flutter/foundation.dart';

/// A menu highlight on a place card.
@immutable
class MenuHighlight {
  const MenuHighlight({required this.name, required this.price});

  final String name;
  final String price;
}

/// Unified content card — recipes, drinks and places (mirrors JS `BiteCard`).
@immutable
class BiteCard {
  const BiteCard({
    required this.id,
    required this.title,
    required this.creator,
    required this.time,
    required this.diff,
    required this.serves,
    required this.heat,
    required this.saved,
    required this.hearts,
    required this.comments,
    required this.emoji,
    required this.cuisine,
    required this.gradient,
    this.image,
    this.tags = const [],
    this.address,
    this.phone,
    this.rating,
    this.reviewCount,
    this.priceLevel,
    this.hours,
    this.status,
    this.distance,
    this.photos = const [],
    this.menuHighlights = const [],
    this.authorId,
    this.description = '',
    this.ingredients = const [],
    this.steps = const [],
    this.publishStatus = 'published',
    this.createdAt,
  });

  final int id;
  final String title;
  final String creator;
  final String time;
  final String diff;
  final int serves;
  final int heat;

  /// Display string, e.g. "2.4K".
  final String saved;
  final String hearts;
  final int comments;
  final String emoji;
  final String? image;
  final String cuisine;

  /// Raw CSS `linear-gradient(...)` string.
  final String gradient;
  final List<String> tags;

  // ── Place-only fields ──
  final String? address;
  final String? phone;
  final double? rating;
  final int? reviewCount;
  final String? priceLevel;
  final String? hours;
  final String? status;
  final String? distance;
  final List<String> photos;
  final List<MenuHighlight> menuHighlights;

  // ── User-created recipe fields ──
  /// Profile id of the creator; null for catalog recipes.
  final String? authorId;
  final String description;
  final List<String> ingredients;
  final List<String> steps;

  /// `draft` or `published`.
  final String publishStatus;
  final DateTime? createdAt;

  bool get isPlace => address != null;
  bool get isDraft => publishStatus == 'draft';
}
