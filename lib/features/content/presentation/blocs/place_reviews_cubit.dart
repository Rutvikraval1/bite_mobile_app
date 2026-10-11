import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/place_review_repository.dart';
import '../../domain/entities/place_review.dart';
import '../../domain/repositories/content_repository.dart';

class PlaceReviewsState {
  const PlaceReviewsState({
    this.placeId,
    this.reviews = const [],
    this.stats = PlaceReviewStats.empty,
    this.loading = false,
    this.error,
    this.submitting = false,
  });

  final int? placeId;
  final List<PlaceReview> reviews;
  final PlaceReviewStats stats;
  final bool loading;
  final String? error;
  final bool submitting;

  PlaceReview? mine(String? userId) => userId == null
      ? null
      : reviews.where((r) => r.userId == userId).firstOrNull;

  PlaceReviewsState copyWith({
    int? placeId,
    List<PlaceReview>? reviews,
    PlaceReviewStats? stats,
    bool? loading,
    String? Function()? error,
    bool? submitting,
  }) {
    return PlaceReviewsState(
      placeId: placeId ?? this.placeId,
      reviews: reviews ?? this.reviews,
      stats: stats ?? this.stats,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
      submitting: submitting ?? this.submitting,
    );
  }
}

/// Loads / posts / deletes b🌶te reviews for the place on Place Detail.
class PlaceReviewsCubit extends Cubit<PlaceReviewsState> {
  PlaceReviewsCubit([PlaceReviewRepository? repository])
      : _repository = repository ?? PlaceReviewRepository(),
        super(const PlaceReviewsState());

  final PlaceReviewRepository _repository;

  String? get currentUserId => _repository.currentUserId;

  /// Loads [placeId] unless it is already shown (pass [force] to reload).
  Future<void> load(int placeId, {bool force = false}) async {
    if (!force && state.placeId == placeId && state.error == null) return;
    final switching = state.placeId != placeId;
    emit(PlaceReviewsState(
      placeId: placeId,
      reviews: switching ? const [] : state.reviews,
      stats: switching ? PlaceReviewStats.empty : state.stats,
      loading: true,
    ));
    try {
      final (reviews, stats) = await (
        _repository.fetchReviews(placeId),
        _repository.fetchStats(placeId),
      ).wait;
      if (isClosed || state.placeId != placeId) return;
      emit(state.copyWith(
        reviews: reviews,
        stats: stats,
        loading: false,
        error: () => null,
      ));
    } catch (e) {
      debugPrint('[place_reviews] load failed: $e');
      if (isClosed || state.placeId != placeId) return;
      emit(state.copyWith(
        loading: false,
        error: () => "Couldn't load reviews.",
      ));
    }
  }

  Future<ContentWriteResult> submit({
    required int rating,
    required String body,
  }) async {
    final placeId = state.placeId;
    if (placeId == null) return const ContentWriteResult.failure('No place');
    emit(state.copyWith(submitting: true));
    final result = await _repository.upsertReview(
      placeId: placeId,
      rating: rating,
      body: body,
    );
    if (isClosed) return result;
    emit(state.copyWith(submitting: false));
    if (result.isSuccess) await _refreshAfterWrite(placeId);
    return result;
  }

  Future<ContentWriteResult> delete(String reviewId) async {
    final placeId = state.placeId;
    if (placeId == null) return const ContentWriteResult.failure('No place');
    final result = await _repository.deleteReview(reviewId);
    if (result.isSuccess && !isClosed) await _refreshAfterWrite(placeId);
    return result;
  }

  Future<void> _refreshAfterWrite(int placeId) async {
    try {
      final (reviews, stats) = await (
        _repository.fetchReviews(placeId),
        _repository.fetchStats(placeId),
      ).wait;
      if (isClosed || state.placeId != placeId) return;
      emit(state.copyWith(reviews: reviews, stats: stats, error: () => null));
    } catch (e) {
      debugPrint('[place_reviews] refresh failed: $e');
    }
  }
}
