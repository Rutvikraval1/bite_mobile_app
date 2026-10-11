/// One b🌶te user review of a place (`public.place_reviews`), with the
/// author's public profile fields embedded.
class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.authorName = '',
    this.authorUsername = '',
    this.authorEmoji = '🧑‍🍳',
    this.authorAvatarUrl,
  });

  /// PostgREST select with the author embedded from `profiles`.
  static const String select =
      '*, author:profiles(display_name, username, avatar_emoji, avatar_url)';

  final String id;
  final int placeId;
  final String userId;
  final int rating;
  final String body;
  final DateTime createdAt;
  final String authorName;
  final String authorUsername;
  final String authorEmoji;
  final String? authorAvatarUrl;

  /// "@username" when the author picked one — opens their creator profile.
  String? get authorHandle =>
      authorUsername.isEmpty ? null : '@${authorUsername.toLowerCase()}';

  String get displayName {
    if (authorName.isNotEmpty) return authorName;
    return authorHandle ?? 'b🌶te user';
  }

  factory PlaceReview.fromRow(Map<String, dynamic> r) {
    final author = r['author'] as Map<String, dynamic>?;
    final avatarUrl = author?['avatar_url'] as String?;
    final emoji = author?['avatar_emoji'] as String?;
    return PlaceReview(
      id: r['id'] as String,
      placeId: (r['place_id'] as num).toInt(),
      userId: r['user_id'] as String,
      rating: ((r['rating'] as num?)?.toInt() ?? 0).clamp(1, 5),
      body: (r['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      authorName: (author?['display_name'] as String?)?.trim() ?? '',
      authorUsername: (author?['username'] as String?)?.trim() ?? '',
      authorEmoji: (emoji == null || emoji.isEmpty) ? '🧑‍🍳' : emoji,
      authorAvatarUrl:
          (avatarUrl == null || avatarUrl.isEmpty) ? null : avatarUrl,
    );
  }
}

/// Average rating + count of b🌶te reviews for one place.
class PlaceReviewStats {
  const PlaceReviewStats({this.average, this.count = 0});

  static const PlaceReviewStats empty = PlaceReviewStats();

  final double? average;
  final int count;
}
