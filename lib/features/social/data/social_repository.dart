import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/social_models.dart';

/// Feed posts, likes, comments, creators, events, mutes and reports.
class SocialRepository {
  SocialRepository({SupabaseClientProvider? provider})
      : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  List<Map<String, dynamic>> _rows(Object? res) =>
      (res as List).cast<Map<String, dynamic>>();

  // ── Feed ──

  /// Newest posts, optionally only by [handles].
  Future<List<FeedPost>> fetchFeed({List<String>? handles, int limit = 60}) async {
    if (handles != null && handles.isEmpty) return const [];
    var query = _client.from(TableNames.feedPosts).select(FeedPost.select);
    if (handles != null) query = query.inFilter('author_handle', handles);
    final res = await query.order('created_at', ascending: false).limit(limit);
    return _rows(res).map(FeedPost.fromRow).toList();
  }

  Future<Set<String>> fetchLikedPostIds(String userId, List<String> postIds) async {
    if (postIds.isEmpty) return {};
    final res = await _client
        .from(TableNames.postLikes)
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return _rows(res).map((r) => r['post_id'] as String).toSet();
  }

  Future<void> likePost(String userId, String postId) => _client
      .from(TableNames.postLikes)
      .upsert({'post_id': postId, 'user_id': userId}, onConflict: 'post_id,user_id');

  Future<void> unlikePost(String userId, String postId) => _client
      .from(TableNames.postLikes)
      .delete()
      .eq('user_id', userId)
      .eq('post_id', postId);

  Future<FeedPost> createPost({
    required String userId,
    required String handle,
    required String type,
    required String action,
    String target = '',
    String? rating,
    String? caption,
    String? photoUrl,
    int? recipeId,
  }) async {
    final res = await _client
        .from(TableNames.feedPosts)
        .insert({
          'user_id': userId,
          'author_handle': handle,
          'type': type,
          'action': action,
          'target': target,
          'rating': rating,
          'caption': caption,
          'photo_url': photoUrl,
          'has_photo': photoUrl != null,
          'recipe_id': recipeId,
        })
        .select(FeedPost.select)
        .single();
    return FeedPost.fromRow(res);
  }

  // ── Discover (For You / Trending) ──

  /// Recipes ranked by real engagement in the last [days] days.
  Future<List<TrendingRank>> fetchTrending({int days = 7, int limit = 10}) async {
    final res = await _client.rpc('trending_recipes', params: {'p_days': days, 'p_limit': limit});
    return _rows(res).map(TrendingRank.fromRow).toList();
  }

  /// Recipe ids picked for the signed-in user, best first.
  Future<List<int>> fetchForYou({int limit = 10}) async {
    final res = await _client.rpc('for_you_recipes', params: {'p_limit': limit});
    return _rows(res).map((r) => (r['recipe_id'] as num).toInt()).toList();
  }

  // ── Comments ──

  Future<List<PostComment>> fetchComments(String postId) async {
    final res = await _client
        .from(TableNames.postComments)
        .select(PostComment.select)
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(200);
    return _rows(res).map(PostComment.fromRow).toList();
  }

  Future<Set<String>> fetchLikedCommentIds(String userId, List<String> commentIds) async {
    if (commentIds.isEmpty) return {};
    final res = await _client
        .from(TableNames.commentLikes)
        .select('comment_id')
        .eq('user_id', userId)
        .inFilter('comment_id', commentIds);
    return _rows(res).map((r) => r['comment_id'] as String).toSet();
  }

  Future<PostComment> addComment({
    required String userId,
    required String handle,
    required String postId,
    required String body,
  }) async {
    final res = await _client
        .from(TableNames.postComments)
        .insert({
          'post_id': postId,
          'user_id': userId,
          'author_handle': handle,
          'body': body,
        })
        .select(PostComment.select)
        .single();
    return PostComment.fromRow(res);
  }

  Future<void> likeComment(String userId, String commentId) => _client
      .from(TableNames.commentLikes)
      .upsert({'comment_id': commentId, 'user_id': userId}, onConflict: 'comment_id,user_id');

  Future<void> unlikeComment(String userId, String commentId) => _client
      .from(TableNames.commentLikes)
      .delete()
      .eq('user_id', userId)
      .eq('comment_id', commentId);

  // ── Creators ──

  /// Featured creators first, then the most-followed real creators.
  Future<List<Creator>> fetchCreators({int limit = 40}) async {
    final res = await _client
        .from(TableNames.creators)
        .select(Creator.select)
        .or('is_featured.eq.true,is_suggested.eq.true,profile_id.not.is.null,recipes_count.gt.0')
        .order('sort_order')
        .order('followers_count', ascending: false)
        .limit(limit);
    return _rows(res).map(Creator.fromRow).toList();
  }

  Future<Creator?> fetchCreator(String handle) async {
    final res = await _client
        .from(TableNames.creators)
        .select(Creator.select)
        .eq('handle', handle)
        .maybeSingle();
    return res == null ? null : Creator.fromRow(res);
  }

  /// The signed-in user's own "@handle" (null until they pick a username).
  Future<String?> fetchMyHandle(String userId) async {
    final res = await _client
        .from(TableNames.creators)
        .select('handle')
        .eq('profile_id', userId)
        .maybeSingle();
    return res?['handle'] as String?;
  }

  // ── Events ──

  /// Upcoming events (started up to a day ago), soonest first.
  Future<List<SocialEvent>> fetchEvents() async {
    final since = DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String();
    final res = await _client
        .from(TableNames.events)
        .select()
        .gte('starts_at', since)
        .order('starts_at')
        .limit(50);
    return _rows(res).map(SocialEvent.fromRow).toList();
  }

  Future<Set<String>> fetchMyRsvps(String userId) async {
    final res = await _client
        .from(TableNames.eventRsvps)
        .select('event_id')
        .eq('user_id', userId);
    return _rows(res).map((r) => r['event_id'] as String).toSet();
  }

  /// Avatar URLs of real attendees, per event (up to 4 each).
  Future<Map<String, List<String>>> fetchAttendeeAvatars(List<String> eventIds) async {
    if (eventIds.isEmpty) return {};
    final res = await _client
        .from(TableNames.eventRsvps)
        .select('event_id, profile:profiles(avatar_url)')
        .inFilter('event_id', eventIds)
        .order('created_at', ascending: false)
        .limit(200);
    final out = <String, List<String>>{};
    for (final r in _rows(res)) {
      final url = (r['profile'] as Map?)?['avatar_url'] as String?;
      if (url == null || url.isEmpty) continue;
      final list = out.putIfAbsent(r['event_id'] as String, () => []);
      if (list.length < 4) list.add(url);
    }
    return out;
  }

  Future<void> rsvp(String userId, String eventId) => _client
      .from(TableNames.eventRsvps)
      .insert({'event_id': eventId, 'user_id': userId});

  Future<void> cancelRsvp(String userId, String eventId) => _client
      .from(TableNames.eventRsvps)
      .delete()
      .eq('user_id', userId)
      .eq('event_id', eventId);

  // ── Mute / block / report ──

  /// handle → 'mute' | 'block'
  Future<Map<String, String>> fetchMuted(String userId) async {
    final res = await _client
        .from(TableNames.mutedCreators)
        .select('creator_handle, kind')
        .eq('user_id', userId);
    return {for (final r in _rows(res)) r['creator_handle'] as String: r['kind'] as String};
  }

  Future<void> mute(String userId, String handle, {String kind = 'mute'}) => _client
      .from(TableNames.mutedCreators)
      .upsert(
        {'user_id': userId, 'creator_handle': handle, 'kind': kind},
        onConflict: 'user_id,creator_handle',
      );

  Future<void> unmute(String userId, String handle) => _client
      .from(TableNames.mutedCreators)
      .delete()
      .eq('user_id', userId)
      .eq('creator_handle', handle);

  Future<void> report({
    required String userId,
    required String targetType,
    required String targetId,
    String reason = '',
  }) =>
      _client.from(TableNames.reports).insert({
        'reporter_id': userId,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
      });
}
