import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../data/social_repository.dart';
import '../../domain/social_models.dart';

@immutable
class SocialFeedState {
  const SocialFeedState({
    this.loading = true,
    this.error,
    this.posts = const [],
    this.followingPosts = const [],
    this.followingLoading = false,
    this.likedPostIds = const {},
    this.creators = const [],
    this.events = const [],
    this.rsvps = const {},
    this.attendeeAvatars = const {},
    this.muted = const {},
    this.myHandle,
    this.justSharedPostId,
    this.trending = const [],
    this.forYouIds = const [],
    this.discoverLoaded = false,
  });

  final bool loading;
  final String? error;
  final List<FeedPost> posts;
  final List<FeedPost> followingPosts;
  final bool followingLoading;
  final Set<String> likedPostIds;
  final List<Creator> creators;
  final List<SocialEvent> events;

  /// Event ids the user RSVP'd to.
  final Set<String> rsvps;

  /// Real attendee avatar URLs per event id.
  final Map<String, List<String>> attendeeAvatars;

  /// handle → 'mute' | 'block'
  final Map<String, String> muted;

  /// The signed-in user's "@handle" (null until a username is set).
  final String? myHandle;

  /// Post created by "Share to Feed" this session — shown as "YOUR POST".
  final String? justSharedPostId;

  /// 🔥 Trending ranking from real engagement.
  final List<TrendingRank> trending;

  /// For You recipe ids, best first.
  final List<int> forYouIds;

  /// True once the rankings have loaded (or failed — tabs then fall back).
  final bool discoverLoaded;

  bool _visible(FeedPost p) => !muted.containsKey(p.authorHandle);

  List<FeedPost> get visiblePosts => posts.where(_visible).toList();
  List<FeedPost> get visibleFollowingPosts => followingPosts.where(_visible).toList();

  List<Creator> get featuredCreators => creators.where((c) => c.isFeatured).toList();

  /// "Cooks You Might Like": curated picks + other real creators.
  List<Creator> suggestedCreators(Set<String> following) => [
        ...creators.where((c) => c.isSuggested),
        ...creators.where((c) =>
            !c.isSuggested && !c.isFeatured && c.profileId != null && c.handle != myHandle && !following.contains(c.handle)),
      ].where((c) => !muted.containsKey(c.handle)).take(8).toList();

  /// Creators tab: featured first, then everyone else by followers.
  List<Creator> get creatorsTab {
    final rest = creators.where((c) => !c.isFeatured && !c.isSuggested && c.handle != myHandle).toList()
      ..sort((a, b) => b.followers.compareTo(a.followers));
    return [...featuredCreators, ...rest].where((c) => !muted.containsKey(c.handle)).take(20).toList();
  }

  SocialEvent? get featuredEvent => events.where((e) => e.isFeatured).firstOrNull;
  List<SocialEvent> get otherEvents => events.where((e) => !e.isFeatured).toList();

  SocialFeedState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<FeedPost>? posts,
    List<FeedPost>? followingPosts,
    bool? followingLoading,
    Set<String>? likedPostIds,
    List<Creator>? creators,
    List<SocialEvent>? events,
    Set<String>? rsvps,
    Map<String, List<String>>? attendeeAvatars,
    Map<String, String>? muted,
    String? myHandle,
    String? justSharedPostId,
    List<TrendingRank>? trending,
    List<int>? forYouIds,
    bool? discoverLoaded,
  }) {
    return SocialFeedState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      posts: posts ?? this.posts,
      followingPosts: followingPosts ?? this.followingPosts,
      followingLoading: followingLoading ?? this.followingLoading,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      creators: creators ?? this.creators,
      events: events ?? this.events,
      rsvps: rsvps ?? this.rsvps,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      muted: muted ?? this.muted,
      myHandle: myHandle ?? this.myHandle,
      justSharedPostId: justSharedPostId ?? this.justSharedPostId,
      trending: trending ?? this.trending,
      forYouIds: forYouIds ?? this.forYouIds,
      discoverLoaded: discoverLoaded ?? this.discoverLoaded,
    );
  }
}

/// Social tab data: Activity feed, likes, creators, events, mutes.
/// Comments are loaded per post by [CommentSheet] via [repository].
class SocialFeedCubit extends Cubit<SocialFeedState> {
  SocialFeedCubit(this.repository) : super(const SocialFeedState());

  final SocialRepository repository;
  String? _userId;
  String? get userId => _userId;

  Future<void> bind(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (isClosed) return;
    emit(const SocialFeedState());
    if (userId != null) await Future.wait([refresh(), loadDiscover()]);
  }

  /// Reloads the For You + Trending rankings (they shift with every save,
  /// cook, like and swipe).
  Future<void> loadDiscover() async {
    final userId = _userId;
    if (userId == null || isClosed) return;
    try {
      final (trending, forYou) = await (
        repository.fetchTrending(),
        repository.fetchForYou(),
      ).wait;
      if (isClosed || userId != _userId) return;
      emit(state.copyWith(trending: trending, forYouIds: forYou, discoverLoaded: true));
    } catch (e) {
      debugPrint('[social] discover failed: $e');
      if (!isClosed && userId == _userId) emit(state.copyWith(discoverLoaded: true));
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null || isClosed) return;
    try {
      final (posts, creators, events, rsvps, muted, handle) = await (
        repository.fetchFeed(),
        repository.fetchCreators(),
        repository.fetchEvents(),
        repository.fetchMyRsvps(userId),
        repository.fetchMuted(userId),
        repository.fetchMyHandle(userId),
      ).wait;
      final (liked, avatars) = await (
        repository.fetchLikedPostIds(userId, [for (final p in posts) p.id]),
        repository.fetchAttendeeAvatars([for (final e in events) e.id]),
      ).wait;
      if (isClosed || userId != _userId) return;
      emit(state.copyWith(
        loading: false,
        clearError: true,
        posts: posts,
        likedPostIds: liked,
        creators: creators,
        events: events,
        rsvps: rsvps,
        attendeeAvatars: avatars,
        muted: muted,
        myHandle: handle,
      ));
    } catch (e) {
      debugPrint('[social] refresh failed: $e');
      if (isClosed || userId != _userId) return;
      emit(state.copyWith(loading: false, error: "Couldn't load the feed"));
    }
  }

  /// Posts by creators the user follows.
  Future<void> loadFollowing(Set<String> handles) async {
    final userId = _userId;
    if (userId == null || isClosed) return;
    emit(state.copyWith(followingLoading: true));
    try {
      final posts = await repository.fetchFeed(handles: handles.toList(), limit: 40);
      final missing = [for (final p in posts) if (!state.posts.any((q) => q.id == p.id)) p.id];
      final liked = await repository.fetchLikedPostIds(userId, missing);
      if (isClosed || userId != _userId) return;
      emit(state.copyWith(
        followingPosts: posts,
        followingLoading: false,
        likedPostIds: {...state.likedPostIds, ...liked},
      ));
    } catch (e) {
      debugPrint('[social] following failed: $e');
      if (!isClosed) emit(state.copyWith(followingLoading: false));
    }
  }

  List<FeedPost> _mapPost(List<FeedPost> list, String id, FeedPost Function(FeedPost) f) =>
      [for (final p in list) p.id == id ? f(p) : p];

  void _updatePost(String id, FeedPost Function(FeedPost) f) {
    emit(state.copyWith(
      posts: _mapPost(state.posts, id, f),
      followingPosts: _mapPost(state.followingPosts, id, f),
    ));
  }

  /// Optimistic like/unlike; reverts and toasts on failure.
  Future<void> toggleLike(String postId) async {
    final userId = _userId;
    if (userId == null) return;
    final wasLiked = state.likedPostIds.contains(postId);
    void apply(bool like) {
      emit(state.copyWith(
        likedPostIds: like ? {...state.likedPostIds, postId} : ({...state.likedPostIds}..remove(postId)),
      ));
      _updatePost(postId, (p) => p.copyWith(likesCount: (p.likesCount + (like ? 1 : -1)).clamp(0, 1 << 31)));
    }

    apply(!wasLiked);
    try {
      if (wasLiked) {
        await repository.unlikePost(userId, postId);
      } else {
        await repository.likePost(userId, postId);
      }
    } catch (e) {
      debugPrint('[social] like failed: $e');
      if (isClosed || userId != _userId) return;
      apply(wasLiked);
      ToastService.instance.show("⚠️ Couldn't update like. Try again.");
    }
  }

  /// Keeps the card's comment count in sync with [CommentSheet].
  void setCommentCount(String postId, int count) {
    _updatePost(postId, (p) => p.copyWith(commentsCount: count));
  }

  /// Ensures [SocialFeedState.myHandle] is loaded (username may be new).
  Future<String?> ensureHandle() async {
    final userId = _userId;
    if (state.myHandle != null || userId == null) return state.myHandle;
    try {
      final handle = await repository.fetchMyHandle(userId);
      if (!isClosed && handle != null) emit(state.copyWith(myHandle: handle));
      return handle;
    } catch (e) {
      debugPrint('[social] handle failed: $e');
      return null;
    }
  }

  /// "Share to Feed" from Post-Cook. Uploads [photo] (if any) first.
  Future<FeedPost?> sharePost({
    required String caption,
    required String dishTitle,
    String? rating,
    XFile? photo,
    int? recipeId,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    final handle = await ensureHandle();
    if (handle == null) {
      ToastService.instance.show('⚠️ Pick a username in Edit Profile to post.');
      return null;
    }
    try {
      String? photoUrl;
      if (photo != null) {
        photoUrl = await ImageUploadService.instance.upload(
          bucket: ImageBuckets.recipeImages,
          userId: userId,
          file: photo,
        );
      }
      final post = await repository.createPost(
        userId: userId,
        handle: handle,
        type: 'cooked',
        action: 'cooked',
        target: dishTitle,
        rating: rating,
        caption: caption,
        photoUrl: photoUrl,
        recipeId: recipeId,
      );
      if (isClosed || userId != _userId) return post;
      emit(state.copyWith(posts: [post, ...state.posts], justSharedPostId: post.id));
      return post;
    } catch (e) {
      debugPrint('[social] share failed: $e');
      ToastService.instance.show("⚠️ Couldn't share your post. Try again.");
      return null;
    }
  }

  /// RSVP or cancel. Returns the new going state, or null on failure.
  Future<bool?> toggleRsvp(SocialEvent event) async {
    final userId = _userId;
    if (userId == null) return null;
    final going = state.rsvps.contains(event.id);
    if (!going && event.soldOut) return null;
    void apply(bool rsvp) {
      emit(state.copyWith(
        rsvps: rsvp ? {...state.rsvps, event.id} : ({...state.rsvps}..remove(event.id)),
        events: [
          for (final e in state.events)
            e.id == event.id ? e.copyWith(attending: (e.attending + (rsvp ? 1 : -1)).clamp(0, 1 << 31)) : e,
        ],
      ));
    }

    apply(!going);
    try {
      if (going) {
        await repository.cancelRsvp(userId, event.id);
      } else {
        await repository.rsvp(userId, event.id);
      }
      return !going;
    } catch (e) {
      debugPrint('[social] rsvp failed: $e');
      if (isClosed || userId != _userId) return null;
      apply(going);
      final soldOut = e.toString().contains('event_sold_out');
      ToastService.instance.show(soldOut ? '😞 This event just sold out.' : "⚠️ Couldn't update RSVP. Try again.");
      return null;
    }
  }

  /// Mute or block a creator (hides their posts). Returns success.
  Future<bool> mute(String handle, {String kind = 'mute'}) async {
    final userId = _userId;
    if (userId == null) return false;
    final before = state.muted;
    emit(state.copyWith(muted: {...before, handle: kind}));
    try {
      await repository.mute(userId, handle, kind: kind);
      return true;
    } catch (e) {
      debugPrint('[social] mute failed: $e');
      if (!isClosed) emit(state.copyWith(muted: before));
      return false;
    }
  }

  Future<void> unmute(String handle) async {
    final userId = _userId;
    if (userId == null) return;
    final before = state.muted;
    emit(state.copyWith(muted: {...before}..remove(handle)));
    try {
      await repository.unmute(userId, handle);
    } catch (e) {
      debugPrint('[social] unmute failed: $e');
      if (!isClosed) emit(state.copyWith(muted: before));
    }
  }

  Future<bool> report(String targetType, String targetId, {String reason = ''}) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await repository.report(userId: userId, targetType: targetType, targetId: targetId, reason: reason);
      return true;
    } catch (e) {
      debugPrint('[social] report failed: $e');
      return false;
    }
  }
}
