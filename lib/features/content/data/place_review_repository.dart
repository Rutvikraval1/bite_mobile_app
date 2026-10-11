import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/entities/place_review.dart';
import '../domain/repositories/content_repository.dart';

/// Reads and writes b🌶te reviews of places (`public.place_reviews`).
/// One review per user per place — posting again updates it.
class PlaceReviewRepository {
  PlaceReviewRepository({SupabaseClientProvider? provider})
      : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  String? get currentUserId =>
      _provider.isInitialized ? _client.auth.currentUser?.id : null;

  List<Map<String, dynamic>> _rows(Object? res) =>
      (res as List).cast<Map<String, dynamic>>();

  /// Newest reviews of [placeId] (author embedded).
  Future<List<PlaceReview>> fetchReviews(int placeId, {int limit = 50}) async {
    final res = await _client
        .from(TableNames.placeReviews)
        .select(PlaceReview.select)
        .eq('place_id', placeId)
        .order('created_at', ascending: false)
        .limit(limit);
    return _rows(res).map(PlaceReview.fromRow).toList();
  }

  /// Average rating + total count across every review of [placeId].
  Future<PlaceReviewStats> fetchStats(int placeId) async {
    final res = await _client
        .from(TableNames.placeReviewStats)
        .select('avg_rating, review_count')
        .eq('place_id', placeId)
        .maybeSingle();
    if (res == null) return PlaceReviewStats.empty;
    return PlaceReviewStats(
      average: (res['avg_rating'] as num?)?.toDouble(),
      count: (res['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Creates or replaces the signed-in user's review of [placeId].
  Future<ContentWriteResult<PlaceReview>> upsertReview({
    required int placeId,
    required int rating,
    required String body,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      return const ContentWriteResult.failure('Not authenticated');
    }
    try {
      final row = await _client
          .from(TableNames.placeReviews)
          .upsert({
            'place_id': placeId,
            'user_id': userId,
            'rating': rating.clamp(1, 5),
            'body': body.trim(),
          }, onConflict: 'place_id,user_id')
          .select(PlaceReview.select)
          .single();
      return ContentWriteResult.ok(PlaceReview.fromRow(row));
    } catch (e) {
      debugPrint('[place_reviews] upsert failed: $e');
      return ContentWriteResult.failure(e.toString());
    }
  }

  /// Deletes the signed-in user's review [reviewId].
  Future<ContentWriteResult> deleteReview(String reviewId) async {
    final userId = currentUserId;
    if (userId == null) {
      return const ContentWriteResult.failure('Not authenticated');
    }
    try {
      await _client
          .from(TableNames.placeReviews)
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId);
      return const ContentWriteResult.ok();
    } catch (e) {
      debugPrint('[place_reviews] delete failed: $e');
      return ContentWriteResult.failure(e.toString());
    }
  }
}
