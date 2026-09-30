import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/floating_pill_nav.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/scrollable_tabs.dart';
import '../../../../core/widgets/social_proof_avatars.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../data/mock_social_data.dart';
import '../widgets/comment_sheet.dart';

/// Filter/sub-nav pills for the activity wall.
const List<(String id, String label)> _filters = [
  ('feed', '📱 Feed'),
  ('forYou', 'For You'),
  ('trending', '🔥 Trending'),
  ('following', 'Following'),
  ('creators', 'Creators'),
  ('events', '🎪 Events'),
];

/// Gamification level thresholds — ports the `levels` array in the JS.
const List<(String name, int min, String emoji)> _levels = [
  ('Curious', 0, '🥄'),
  ('Beginner', 10, '🍳'),
  ('Home Cook', 30, '🥘'),
  ('Sous Chef', 75, '👨‍🍳'),
  ('Chef', 150, '🧑‍🍳'),
  ('Master Chef', 300, '⭐'),
  ('b🌶te Legend', 600, '🔥'),
];

/// Main social hub — ports `SocialFeedScreen` from `screens-social.jsx`.
/// Reachable via the bottom [FloatingPillNav]; renders full-screen leaving
/// room for it, matching `SwipeDeckScreen`'s pattern.
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  bool _loading = true;
  Timer? _loadTimer;
  Timer? _bannerTimer;

  String _activeFilter = 'feed';
  bool _bannerDismissed = false;
  final Set<int> _likedPosts = {};
  int? _commentSheetIndex; // -1 = the user's own shared post
  final Map<int, List<String>> _postedComments = {};
  bool _myPostLiked = false;
  final Set<String> _followedSuggested = {};

  @override
  void initState() {
    super.initState();
    _loadTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerAutoDismiss(bool showing) {
    if (!showing || _bannerDismissed || _bannerTimer != null) return;
    _bannerTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _bannerDismissed = true);
    });
  }

  void _selectFilter(String id) {
    setState(() => _activeFilter = id);
    if (id != 'trending') {
      context.read<AppStateCubit>().setTrendingMode(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: BlocBuilder<AppStateCubit, AppState>(
        buildWhen: (p, c) =>
            p.sharedPost != c.sharedPost ||
            p.notificationCount != c.notificationCount ||
            p.xp != c.xp,
        builder: (context, state) {
          final showBanner = state.sharedPost != null && !_bannerDismissed;
          _startBannerAutoDismiss(showBanner);
          final profile = context.watch<AuthCubit>().state.profile;

          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                bottom: false,
                // CustomScrollView + slivers so the (long) activity feed is
                // built lazily instead of every card at once.
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(state)),
                    if (_loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _FeedSkeleton(),
                        ),
                      )
                    else ...[
                      if (showBanner && _activeFilter == 'feed')
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: _PointsBanner(
                              xp: state.xp,
                              onDismiss: () => setState(() => _bannerDismissed = true),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: ScrollableTabs(
                          children: [
                            for (final f in _filters)
                              _FilterPill(
                                label: f.$2,
                                selected: _activeFilter == f.$1,
                                onTap: () => _selectFilter(f.$1),
                              ),
                          ],
                        ),
                      ),
                      _buildTabContent(state, profile),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 90,
                child: _CreateFab(
                  onTap: () => context.read<FlowCubit>().setScreen(AppScreen.creatorCreate),
                ),
              ),
              const FloatingPillNav(),
              if (_commentSheetIndex != null)
                _buildCommentOverlay(state, profile?.avatarEmoji ?? '🧑‍🍳'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    final title = switch (_activeFilter) {
      'feed' => 'Activity',
      'trending' => '🔥 Trending',
      'creators' => 'Creators',
      'events' => 'Local Events',
      _ => 'Feed',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          GestureDetector(
            onTap: () => context.read<FlowCubit>().setScreen(AppScreen.notifications),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded, size: 22, color: AppColors.muted),
                if (state.notificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.bgDark, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.notificationCount > 99 ? '99+' : '${state.notificationCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a sliver.
  Widget _buildTabContent(AppState state, dynamic profile) {
    if (_activeFilter == 'feed') return _buildFeedTab(state, profile);
    return SliverToBoxAdapter(
      child: switch (_activeFilter) {
        'forYou' => _buildGridTab(mockForYouCards),
        'trending' => _buildGridTab(mockTrendingCards, trending: true),
        'following' => _buildFollowingTab(),
        'creators' => _buildCreatorsTab(),
        'events' => _buildEventsTab(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // ── FEED TAB ──

  /// Returns a sliver — activity cards are built lazily.
  Widget _buildFeedTab(AppState state, dynamic profile) {
    final sharedPost = state.sharedPost;
    final avatarEmoji = profile?.avatarEmoji ?? '🧑‍🍳';
    final hasShared = sharedPost != null;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList.builder(
        itemCount: mockActivityFeed.length + (hasShared ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasShared && index == 0) {
            return ZoomIn(
              child: _YourPostCard(
                avatarEmoji: avatarEmoji,
                sharedPost: sharedPost,
                liked: _myPostLiked,
                commentCount: _postedComments[-1]?.length ?? 0,
                onToggleLike: () => setState(() => _myPostLiked = !_myPostLiked),
                onComment: () => setState(() => _commentSheetIndex = -1),
                onShare: () => context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
                onOpenProfile: () => context.read<FlowCubit>().setScreen(AppScreen.profile),
              ),
            );
          }
          final i = hasShared ? index - 1 : index;
          final card = ZoomIn(
            duration: Duration(milliseconds: 260 + i * 20),
            child: _ActivityCard(
              index: i,
              activity: mockActivityFeed[i],
              liked: _likedPosts.contains(i),
              extraComments: _postedComments[i]?.length ?? 0,
              onOpen: () {
                final flow = context.read<FlowCubit>();
                final type = mockActivityFeed[i].type;
                if (type == 'text') {
                  flow.setScreen(AppScreen.creatorProfile);
                } else if (type == 'cooked' || type == 'created') {
                  flow.setScreen(AppScreen.recipeDetail);
                } else {
                  flow.setScreen(AppScreen.creatorProfile);
                }
              },
              onOpenProfile: () => context.read<FlowCubit>().setScreen(AppScreen.creatorProfile),
              onToggleLike: () => setState(() {
                if (_likedPosts.contains(i)) {
                  _likedPosts.remove(i);
                } else {
                  _likedPosts.add(i);
                }
              }),
              onComment: () => setState(() => _commentSheetIndex = i),
              onShare: () => context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
            ),
          );
          if (i != 4) return card;
          return Column(children: [_buildSuggestedCreators(), card]);
        },
      ),
    );
  }

  Widget _buildSuggestedCreators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cooks You Might Like',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => ToastService.instance.show('📋 See all suggestions'),
                  child: const Text('See All',
                      style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockSuggestedCreators.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final user = mockSuggestedCreators[i];
                final followed = _followedSuggested.contains(user.handle);
                return _SuggestedCreatorCard(
                  user: user,
                  followed: followed,
                  onFollow: () {
                    setState(() {
                      if (followed) {
                        _followedSuggested.remove(user.handle);
                      } else {
                        _followedSuggested.add(user.handle);
                      }
                    });
                    ToastService.instance
                        .show(followed ? 'Unfollowed ${user.handle}' : '✅ Following ${user.handle}!');
                  },
                  onOpen: () => context.read<FlowCubit>().setScreen(AppScreen.creatorProfile),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── FOR YOU / TRENDING TAB ──

  Widget _buildGridTab(List<FeedCard> cards, {bool trending = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < cards.length; i++)
            SizedBox(
              width: cards[i].big
                  ? MediaQuery.sizeOf(context).width - 24
                  : (MediaQuery.sizeOf(context).width - 24 - 12) / 2,
              child: ZoomIn(
                duration: Duration(milliseconds: 260 + i * 40),
                child: _RecipeGridCard(card: cards[i], trending: trending, rank: i == 0 && trending),
              ),
            ),
        ],
      ),
    );
  }

  // ── FOLLOWING TAB ──

  Widget _buildFollowingTab() {
    if (mockFollowingCards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Text('👥', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Follow some creators!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('Posts from people you follow will appear here.',
                style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < mockFollowingCards.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ZoomIn(
                duration: Duration(milliseconds: 240 + i * 40),
                child: _RecipeGridCard(card: mockFollowingCards[i], height: mockFollowingCards[i].big ? 180 : 140, italicComment: true),
              ),
            ),
        ],
      ),
    );
  }

  // ── CREATORS TAB ──

  Widget _buildCreatorsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < mockCreatorCards.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ZoomIn(
                duration: Duration(milliseconds: 240 + i * 40),
                child: _CreatorRow(
                  creator: mockCreatorCards[i],
                  onTap: () => context.read<FlowCubit>().setScreen(AppScreen.creatorProfile),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── EVENTS TAB ──

  Widget _buildEventsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const _FeaturedEventCard(),
          const SizedBox(height: 16),
          ScrollableTabs(
            leftPad: 0,
            children: [
              for (final (i, cat) in [
                'All',
                '🍴 Tastings',
                '👨‍🍳 Classes',
                '🏆 Competitions',
                '🛒 Markets',
                '🍷 Wine & Spirits',
                '🌱 Farm Tours',
              ].indexed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.coral : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat,
                      style: TextStyle(
                          color: i == 0 ? Colors.white : AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          for (var i = 0; i < mockEvents.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ZoomIn(
                duration: Duration(milliseconds: 240 + i * 40),
                child: _EventRow(
                  event: mockEvents[i],
                  onTap: () {
                    if (mockEvents[i].soldOut) {
                      ToastService.instance.show('😞 This event is sold out. Join the waitlist?');
                    } else {
                      ToastService.instance.show('🎟 RSVP confirmed for ${mockEvents[i].title}!');
                    }
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => ToastService.instance.show('🎪 Event creation coming in Phase 2!'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.2), style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.add_rounded, color: AppColors.coral, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Host an Event',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('Cooking class, tasting, pop-up, or competition',
                              style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentOverlay(AppState state, String avatarEmoji) {
    final idx = _commentSheetIndex!;
    return CommentSheet(
      myAvatarEmoji: avatarEmoji,
      initialUserComments: _postedComments[idx] ?? const [],
      onClose: () => setState(() => _commentSheetIndex = null),
      onPosted: (comments) => setState(() => _postedComments[idx] = comments),
    );
  }
}

// ── Header pieces ──

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.xp, required this.onDismiss});

  final int xp;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    var current = _levels.first;
    for (final l in _levels) {
      if (xp >= l.$2) current = l;
    }
    final nextIndex = _levels.indexOf(current) + 1;
    final next = nextIndex < _levels.length ? _levels[nextIndex] : current;
    final progress = next == current ? 1.0 : ((xp - current.$2) / (next.$2 - current.$2)).clamp(0.0, 1.0);
    const earnedPts = 65;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.coral.withValues(alpha: 0.15), AppColors.amber.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('+$earnedPts points earned!',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const Text('Cook +10 · Rate +5 · Photo +5 · Review +3 · Share +5',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(current.$3, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(current.$1,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('$xp/${next.$2} pts', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(AppColors.coral),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Feed cards ──

class _YourPostCard extends StatelessWidget {
  const _YourPostCard({
    required this.avatarEmoji,
    required this.sharedPost,
    required this.liked,
    required this.commentCount,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
    required this.onOpenProfile,
  });

  final String avatarEmoji;
  final SharedPost sharedPost;
  final bool liked;
  final int commentCount;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    const ratingLabels = ['', 'Good 🫑', 'Great 🟠', 'Fire 🌶'];
    const ratingEmojis = ['', '🫑', '🟠', '🌶'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
            ),
            child: const Text('🆕 YOUR POST',
                style: TextStyle(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onOpenProfile,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.coral, AppColors.amber]),
                  ),
                  alignment: Alignment.center,
                  child: Text(avatarEmoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onOpenProfile,
                      child: const Text('You',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    const Text('Just now', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              if (sharedPost.rating > 0) Text(ratingEmojis[sharedPost.rating], style: const TextStyle(fontSize: 16)),
            ],
          ),
          if (sharedPost.photo != null) ...[
            const SizedBox(height: 10),
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                    colors: [AppColors.coral.withValues(alpha: 0.2), AppColors.amber.withValues(alpha: 0.13)]),
              ),
              alignment: Alignment.center,
              child: const Opacity(opacity: 0.4, child: Text('📸', style: TextStyle(fontSize: 40))),
            ),
          ],
          const SizedBox(height: 10),
          Text(sharedPost.comment, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          const SizedBox(height: 8),
          Text(
            '${sharedPost.emoji} ${sharedPost.name.isEmpty ? 'Gochujang Glazed Fried Chicken' : sharedPost.name}'
            '${sharedPost.rating > 0 ? ' · ${ratingLabels[sharedPost.rating]}' : ''}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DecoratedBox(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _EngagementButton(
                      icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: '${liked ? 2 : 1}',
                      color: liked ? AppColors.coral : AppColors.muted,
                      onTap: onToggleLike,
                    ),
                    const SizedBox(width: 12),
                    _EngagementButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '$commentCount',
                      color: AppColors.muted,
                      onTap: onComment,
                    ),
                    const SizedBox(width: 12),
                    _EngagementButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      color: AppColors.muted,
                      onTap: onShare,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.index,
    required this.activity,
    required this.liked,
    required this.extraComments,
    required this.onOpen,
    required this.onOpenProfile,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final int index;
  final FeedActivity activity;
  final bool liked;
  final int extraComments;
  final VoidCallback onOpen;
  final VoidCallback onOpenProfile;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  static const _photoHeights = [160.0, 120.0, 180.0, 140.0, 200.0, 130.0];

  String get _tierBadgeEmoji {
    if (activity.tierColor == const Color(0xFF9C27B0)) return '⭐';
    if (activity.tierColor == AppColors.amber) return '👨‍🍳';
    if (activity.tierColor == AppColors.coral) return '🍳';
    if (activity.tierColor == AppColors.placesPurple) return '🧑‍🍳';
    return '🥄';
  }

  @override
  Widget build(BuildContext context) {
    final isText = activity.type == 'text';
    final indent = isText ? 0.0 : 46.0;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onOpenProfile,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.amber.withValues(alpha: 0.27)]),
                          border: Border.all(color: activity.tierColor.withValues(alpha: 0.4), width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AvatarImg(emoji: activity.avatarEmoji, imageUrl: activity.avatarUrl, size: 32, borderWidth: 0),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activity.tierColor,
                            border: Border.all(color: AppColors.bgDark, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(_tierBadgeEmoji, style: const TextStyle(fontSize: 6)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, height: 1.4),
                            children: [
                              TextSpan(
                                  text: activity.user,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              if (!isText) ...[
                                TextSpan(text: ' ${activity.action} ', style: const TextStyle(color: AppColors.muted)),
                                TextSpan(
                                    text: activity.target,
                                    style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600)),
                                if (activity.rating != null) TextSpan(text: ' ${activity.rating}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Text('${activity.time} ago', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            if (activity.caption != null)
              Padding(
                padding: EdgeInsets.only(left: indent, top: isText ? 8 : 8, bottom: isText ? 4 : 8),
                child: Text(
                  activity.caption!,
                  style: TextStyle(
                    color: isText ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.7),
                    fontSize: isText ? 15 : 13,
                    fontWeight: isText ? FontWeight.w500 : FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            if (activity.hasPhoto)
              Padding(
                padding: EdgeInsets.only(left: indent, bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: _photoHeights[index % _photoHeights.length],
                    color: activity.photoColor.withValues(alpha: 0.13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (activity.avatarUrl != null)
                          Opacity(
                            opacity: 0.6,
                            child: AvatarImg(emoji: activity.avatarEmoji, imageUrl: activity.avatarUrl, size: 999, borderWidth: 0),
                          )
                        else
                          Center(
                            child: Opacity(
                              opacity: 0.4,
                              child: Text(activity.avatarEmoji, style: const TextStyle(fontSize: 36)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(left: indent),
              child: Row(
                children: [
                  _EngagementButton(
                    icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: '${activity.likes + (liked ? 1 : 0)}',
                    color: liked ? AppColors.coral : AppColors.muted,
                    onTap: onToggleLike,
                  ),
                  const SizedBox(width: 12),
                  _EngagementButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${activity.comments + extraComments}',
                    color: AppColors.muted,
                    onTap: onComment,
                  ),
                  const SizedBox(width: 12),
                  _EngagementButton(icon: Icons.ios_share_rounded, label: 'Share', color: AppColors.muted, onTap: onShare),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementButton extends StatelessWidget {
  const _EngagementButton({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SuggestedCreatorCard extends StatelessWidget {
  const _SuggestedCreatorCard({
    required this.user,
    required this.followed,
    required this.onFollow,
    required this.onOpen,
  });

  final SuggestedCreator user;
  final bool followed;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.amber.withValues(alpha: 0.27)]),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.33)),
            ),
            clipBehavior: Clip.antiAlias,
            child: AvatarImg(emoji: user.avatarEmoji, imageUrl: user.avatarUrl, size: 48, borderWidth: 0),
          ),
          const SizedBox(height: 8),
          Text(user.handle,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('${user.recipes} recipes · ${user.followers}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.13)),
            ),
            child: Text(user.reason,
                style: const TextStyle(color: AppColors.cyan, fontSize: 9, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onFollow,
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: followed ? const Color(0x1F4CAF50) : AppColors.coral,
                      borderRadius: BorderRadius.circular(100),
                      border: followed ? Border.all(color: const Color(0x4D4CAF50)) : null,
                    ),
                    child: Text(followed ? '✓' : 'Follow',
                        style: TextStyle(
                            color: followed ? const Color(0xFF4CAF50) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onOpen,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecipeGridCard extends StatelessWidget {
  const _RecipeGridCard({required this.card, this.trending = false, this.rank = false, this.height, this.italicComment = false});

  final FeedCard card;
  final bool trending;
  final bool rank;
  final double? height;
  final bool italicComment;

  @override
  Widget build(BuildContext context) {
    final h = height ?? (card.big ? 180.0 : 140.0);
    final content = Container(
      height: h,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [card.color.withValues(alpha: 0.2), card.color.withValues(alpha: 0.07)],
        ),
      ),
      alignment: Alignment.bottomLeft,
      child: Stack(
        children: [
          Positioned(
            top: h * 0.35 - (card.big ? 24 : 18),
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.25,
                child: Text(card.emoji, style: TextStyle(fontSize: card.big ? 48 : 36)),
              ),
            ),
          ),
          if (trending && card.trend != null)
            Positioned(
              top: 10,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.27)),
                ),
                child: Text(card.trend!,
                    style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title,
                    style: TextStyle(color: Colors.white, fontSize: card.big ? 18 : 14, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(card.user, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                if (card.comment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      card.comment!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontStyle: italicComment ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
        child: rank
            ? Pulse(amount: 0.015, duration: const Duration(milliseconds: 2400), child: content)
            : content,
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creator, required this.onTap});

  final CreatorCard creator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.27)),
            ),
            clipBehavior: Clip.antiAlias,
            child: AvatarImg(emoji: creator.emoji, imageUrl: creator.avatarUrl, size: 48, borderWidth: 0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(creator.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${creator.handle} · ${creator.recipes} recipes',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
                  ),
                  child: Text(creator.badge,
                      style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(creator.followers, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const Text('followers', style: TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.coral.withValues(alpha: 0.2),
                AppColors.amber.withValues(alpha: 0.13),
                AppColors.coral.withValues(alpha: 0.07),
              ]),
            ),
            child: Stack(
              children: [
                const Center(child: Opacity(opacity: 0.3, child: Text('🎪', style: TextStyle(fontSize: 56)))),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.87), borderRadius: BorderRadius.circular(100)),
                    child: const Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(100)),
                    child: const Text('📍 2.4 mi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available_rounded, size: 14, color: AppColors.amber),
                    SizedBox(width: 8),
                    Text('This Saturday · 11 AM – 3 PM',
                        style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Downtown Farmers Market & Food Fest',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '50+ local vendors, live cooking demos, tastings from top b🌶te creators, and a kids cooking workshop.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ToastService.instance.show('🎟 RSVP confirmed! Added to your calendar.'),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]),
                          ),
                          child: const Text('RSVP Free 🎟',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ToastService.instance.show('📤 Share link copied!'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.ios_share_rounded, size: 16, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      SocialProofAvatars(
                        urls: [
                          SocialAvatars.urlFor('@chefpriya') ?? '',
                          SocialAvatars.urlFor('@sarah_bakes') ?? '',
                          SocialAvatars.urlFor('@marco.eats') ?? '',
                          SocialAvatars.urlFor('@bangkokbites') ?? '',
                        ],
                        count: 4,
                      ),
                      const SizedBox(width: 6),
                      const Text('234 going · 89 interested', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});

  final LocalEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: event.soldOut ? 0.5 : 1,
      child: Glass(
        onTap: onTap,
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        borderColor: event.soldOut ? Colors.white.withValues(alpha: 0.04) : event.color.withValues(alpha: 0.08),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: event.color.withValues(alpha: 0.15)),
              ),
              alignment: Alignment.center,
              child: Text(event.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('📍 ${event.venue} · ${event.distance}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text('📅 ${event.date}', style: TextStyle(color: event.color, fontSize: 11, fontWeight: FontWeight.w600)),
                      const Text('·', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                      Text(event.price, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        SocialProofAvatars(
                          urls: [
                            SocialAvatars.urlFor('@chefpriya') ?? '',
                            SocialAvatars.urlFor('@marco.eats') ?? '',
                            SocialAvatars.urlFor('@sarah_bakes') ?? '',
                          ],
                          count: 3,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text('${event.attending} going', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.soldOut ? Colors.white.withValues(alpha: 0.06) : event.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: event.soldOut ? Colors.white.withValues(alpha: 0.06) : event.color.withValues(alpha: 0.15)),
                          ),
                          child: Text(event.spots,
                              style: TextStyle(
                                  color: event.soldOut ? AppColors.muted : event.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]),
          boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Shimmer(
                        baseColor: Colors.white.withValues(alpha: 0.03),
                        highlightColor: Colors.white.withValues(alpha: 0.06),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 10, width: 120, color: Colors.white.withValues(alpha: 0.06)),
                            const SizedBox(height: 6),
                            Container(height: 8, width: 70, color: Colors.white.withValues(alpha: 0.04)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Shimmer(
                    baseColor: Colors.white.withValues(alpha: 0.02),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
