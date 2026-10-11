import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/tier_definitions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/floating_pill_nav.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/scrollable_tabs.dart';
import '../../../../core/widgets/social_proof_avatars.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/domain/entities/cook_entry.dart';
import '../../../content/domain/entities/saved_item.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../domain/social_models.dart';
import '../blocs/follow_cubit.dart';
import '../blocs/social_feed_cubit.dart';
import '../social_navigation.dart';
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

/// Events category chips → `events.category`.
const List<(String? id, String label)> _eventCategories = [
  (null, 'All'),
  ('tastings', '🍴 Tastings'),
  ('classes', '👨‍🍳 Classes'),
  ('competitions', '🏆 Competitions'),
  ('markets', '🛒 Markets'),
  ('wine', '🍷 Wine & Spirits'),
  ('farm', '🌱 Farm Tours'),
];

/// Card tints for grid cards and photo placeholders.
const List<Color> _palette = [
  AppColors.coral,
  AppColors.amber,
  AppColors.coralDark,
  AppColors.drinksBlue,
  AppColors.cyan,
  AppColors.placesPurple,
  Color(0xFF4CAF50),
  Color(0xFF64B5F6),
];

Color _tint(String key) => _palette[key.hashCode.abs() % _palette.length];

/// "12m ago" / "Just now".
String _ago(DateTime at) {
  final t = Formatters.timeAgo(at);
  return t == 'now' ? 'Just now' : '$t ago';
}

/// Main social hub — ports `SocialFeedScreen` from `screens-social.jsx`.
/// Reachable via the bottom [FloatingPillNav]; renders full-screen leaving
/// room for it, matching `SwipeDeckScreen`'s pattern. Data comes from
/// [SocialFeedCubit] (feed, creators, events) and [ContentCubit] (recipes).
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  Timer? _bannerTimer;

  String _activeFilter = 'feed';

  /// For You sub-section: picks | published | cooked | saved | drafts.
  String _forYouSection = 'picks';
  String? _eventCategory;
  bool _bannerDismissed = false;
  FeedPost? _commentPost;

  @override
  void initState() {
    super.initState();
    // Pick up posts made elsewhere since the tab was last opened.
    final feed = context.read<SocialFeedCubit>();
    if (!feed.state.loading) feed.refresh();
  }

  @override
  void dispose() {
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
    if (id == 'following') {
      context.read<SocialFeedCubit>().loadFollowing(context.read<FollowCubit>().state);
    }
    if (id == 'forYou' || id == 'trending') {
      // Rankings move with every save, cook, like and swipe.
      context.read<SocialFeedCubit>().loadDiscover();
    }
    if (id == 'forYou') {
      // The signed-in user's own recipes, cooks and saves.
      final content = context.read<ContentCubit>();
      content.reloadProfileContent();
      content.reloadSaved();
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
            p.xp != c.xp ||
            p.userCuisines != c.userCuisines,
        builder: (context, state) {
          final showBanner = state.sharedPost != null && !_bannerDismissed;
          _startBannerAutoDismiss(showBanner);
          final profile = context.watch<AuthCubit>().state.profile;
          final feed = context.watch<SocialFeedCubit>().state;

          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                bottom: false,
                // CustomScrollView + slivers so the (long) activity feed is
                // built lazily instead of every card at once.
                child: RefreshIndicator(
                  color: AppColors.coral,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () async {
                    final cubit = context.read<SocialFeedCubit>();
                    await Future.wait([cubit.refresh(), cubit.loadDiscover()]);
                    if (_activeFilter == 'following' && context.mounted) {
                      await cubit.loadFollowing(context.read<FollowCubit>().state);
                    }
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(state)),
                      if (feed.loading)
                        const SliverToBoxAdapter(
                          child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _FeedSkeleton()),
                        )
                      else ...[
                        if (showBanner && _activeFilter == 'feed')
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: _PointsBanner(
                                xp: state.xp,
                                earnedPts: state.sharedPost?.points ?? 0,
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
                        _buildTabContent(state, feed, profile),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 90,
                child: _CreateFab(onTap: () => context.read<FlowCubit>().setScreen(AppScreen.creatorCreate)),
              ),
              const FloatingPillNav(),
              if (_commentPost != null)
                CommentSheet(
                  post: _commentPost!,
                  myAvatarEmoji: profile?.avatarEmoji ?? '🧑‍🍳',
                  onClose: () => setState(() => _commentPost = null),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const SizedBox(height: 0),
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
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
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
  Widget _buildTabContent(AppState state, SocialFeedState feed, Profile? profile) {
    if (_activeFilter == 'feed') return _buildFeedTab(feed, profile);
    final recipes = context.watch<ContentCubit>().state.recipes;
    return SliverToBoxAdapter(
      child: switch (_activeFilter) {
        'forYou' => _buildForYouTab(state, feed, profile),
        'trending' =>
          feed.discoverLoaded
              ? _buildGridTab(_trendingCards(recipes, feed.trending), trending: true)
              : const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _FeedSkeleton()),
        'following' => _buildFollowingTab(feed),
        'creators' => _buildCreatorsTab(feed),
        'events' => _buildEventsTab(feed),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // ── FEED TAB ──

  void _openPost(FeedPost post) {
    final opensRecipe = post.type == 'cooked' || post.type == 'created' || post.type == 'rated';
    if (opensRecipe && openRecipe(context, post.recipeId)) return;
    openCreator(context, post.authorHandle);
  }

  void _openProfileOf(FeedPost post, Profile? profile) {
    if (post.userId != null && post.userId == profile?.id) {
      context.read<FlowCubit>().setScreen(AppScreen.profile);
    } else {
      openCreator(context, post.authorHandle);
    }
  }

  /// Returns a sliver — activity cards are built lazily.
  Widget _buildFeedTab(SocialFeedState feed, Profile? profile) {
    final all = feed.visiblePosts;
    final shared = all.where((p) => p.id == feed.justSharedPostId).firstOrNull;
    final posts = [
      for (final p in all)
        if (p.id != shared?.id) p,
    ];
    final hasShared = shared != null;
    final avatarEmoji = profile?.avatarEmoji ?? '🧑‍🍳';
    // "Cooks You Might Like" sits before the 5th card (or after the last).
    final suggestAt = posts.isEmpty ? -1 : (posts.length > 4 ? 4 : posts.length - 1);

    if (posts.isEmpty && !hasShared) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            if (feed.creators.isNotEmpty)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildSuggestedCreators(feed)),
            _EmptyBlock(
              emoji: feed.error != null ? '⚠️' : '🍳',
              title: feed.error ?? 'No activity yet',
              message: feed.error != null
                  ? 'Pull down to try again.'
                  : 'Cook something and share it to start the feed!',
            ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList.builder(
        itemCount: posts.length + (hasShared ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasShared && index == 0) {
            return ZoomIn(
              child: _YourPostCard(
                avatarEmoji: avatarEmoji,
                avatarUrl: profile?.avatarUrl,
                post: shared,
                liked: feed.likedPostIds.contains(shared.id),
                onToggleLike: () => context.read<SocialFeedCubit>().toggleLike(shared.id),
                onComment: () => setState(() => _commentPost = shared),
                onShare: () => context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
                onOpenProfile: () => context.read<FlowCubit>().setScreen(AppScreen.profile),
              ),
            );
          }
          final i = hasShared ? index - 1 : index;
          final post = posts[i];
          final card = ZoomIn(
            duration: Duration(milliseconds: 260 + (i % 12) * 20),
            child: _ActivityCard(
              index: i,
              post: post,
              liked: feed.likedPostIds.contains(post.id),
              onOpen: () => _openPost(post),
              onOpenProfile: () => _openProfileOf(post, profile),
              onToggleLike: () => context.read<SocialFeedCubit>().toggleLike(post.id),
              onComment: () => setState(() => _commentPost = post),
              onShare: () => context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
            ),
          );
          if (i != suggestAt) return card;
          final suggested = _buildSuggestedCreators(feed);
          return Column(children: i == 4 ? [suggested, card] : [card, suggested]);
        },
      ),
    );
  }

  Widget _buildSuggestedCreators(SocialFeedState feed) {
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
                const Text(
                  'Cooks You Might Like',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => _selectFilter('creators'),
                  child: const Text(
                    'See All',
                    style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _SuggestedCreatorCard.height,
            // Read follows here, not inside itemBuilder: provider forbids
            // context.select/watch in lazily built list items.
            child: BlocBuilder<FollowCubit, Set<String>>(
              builder: (context, follows) {
                // Freeze the list per session so tapping Follow keeps the
                // card (showing ✓) instead of removing it.
                final users = _suggested ?? feed.suggestedCreators(follows);
                if (feed.creators.isNotEmpty) _suggested ??= users;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return _SuggestedCreatorCard(
                      user: user,
                      followed: follows.contains(FollowCubit.normalize(user.handle)),
                      onFollow: () => context.read<FollowCubit>().toggle(user.handle),
                      onOpen: () => openCreator(context, user.handle),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Creator>? _suggested;

  // ── FOR YOU / TRENDING TAB ──

  /// For You: the signed-in user's own activity (published, cooked, saved,
  /// drafts) plus personal picks. Signed-out users only see picks.
  Widget _buildForYouTab(AppState state, SocialFeedState feed, Profile? profile) {
    final content = context.watch<ContentCubit>().state;
    final signedIn = profile != null;
    final published = content.publishedRecipes;
    final drafts = content.draftRecipes;
    final cooked = content.cookHistory;
    final saved = content.savedItems;
    final section = signedIn ? _forYouSection : 'picks';

    final sections = [
      ('picks', '✨', 'Picks', null),
      if (signedIn) ...[
        ('published', '📢', 'Published', published.length),
        ('cooked', '🍳', 'Cooked', cooked.length),
        ('saved', '🔖', 'Saved', saved.length),
        ('drafts', '📝', 'Drafts', drafts.length),
      ],
    ];

    final loadingOwn = section != 'picks' &&
        (section == 'saved' ? content.savedLoading : content.profileLoading);
    final Widget body;
    if (section == 'picks' && !feed.discoverLoaded) {
      body = const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _FeedSkeleton());
    } else if (loadingOwn &&
        switch (section) {
          'published' => published.isEmpty,
          'cooked' => cooked.isEmpty,
          'saved' => saved.isEmpty,
          _ => drafts.isEmpty,
        }) {
      body = const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _FeedSkeleton());
    } else {
      final cards = switch (section) {
        'published' => _ownRecipeCards(published),
        'cooked' => _cookedCards(cooked),
        'saved' => _savedCards(saved, content),
        'drafts' => _ownRecipeCards(drafts, draft: true),
        _ => _forYouCards(content.recipes, feed.forYouIds, state.userCuisines),
      };
      body = cards.isEmpty ? _forYouEmpty(section) : _buildGridTab(cards);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (signedIn)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                for (final (id, emoji, label, count) in sections.skip(1))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _ForYouStat(
                        emoji: emoji,
                        label: label,
                        count: count ?? 0,
                        selected: section == id,
                        onTap: () => setState(() => _forYouSection = id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final (id, emoji, label, count) in sections)
                _FilterPill(
                  label: count == null ? '$emoji $label' : '$emoji $label ($count)',
                  selected: section == id,
                  onTap: () => setState(() => _forYouSection = id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        body,
      ],
    );
  }

  Widget _forYouEmpty(String section) {
    final (emoji, title, message, cta, screen) = switch (section) {
      'published' => ('📢', 'No published recipes yet', 'Share your first recipe with the community.', 'Create a recipe', AppScreen.creatorCreate),
      'cooked' => ('🍳', 'Nothing cooked yet', 'Cook a recipe and it will show up here.', 'Find a recipe', AppScreen.swipeDeck),
      'saved' => ('🔖', 'Nothing saved yet', 'Swipe up on a card to save it.', 'Start swiping', AppScreen.swipeDeck),
      'drafts' => ('📝', 'No drafts', 'Recipes you save as a draft stay private here.', 'Create a recipe', AppScreen.creatorCreate),
      _ => ('🍽', 'Nothing here yet', 'Recipes will show up here soon.', null, null),
    };
    return Column(
      children: [
        _EmptyBlock(emoji: emoji, title: title, message: message),
        if (cta != null && screen != null)
          GestureDetector(
            onTap: () {
              if (screen == AppScreen.creatorCreate) context.read<AppStateCubit>().editRecipe(null);
              context.read<FlowCubit>().setScreen(screen);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
              child: Text(cta, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  /// The user's own recipes (published or drafts), newest first.
  List<_GridItem> _ownRecipeCards(List<BiteCard> recipes, {bool draft = false}) {
    return [
      for (final (i, r) in recipes.indexed)
        _GridItem(
          recipeId: r.id,
          title: r.title,
          user: '${r.cuisine} · ${r.time}',
          emoji: r.emoji,
          color: _palette[i % 4],
          big: i == 0,
          comment: draft
              ? '📝 Draft${r.createdAt != null ? ' · ${_ago(r.createdAt!)}' : ''}'
              : '❤️ ${r.hearts.isEmpty ? '0' : r.hearts} · 💬 ${r.comments}'
                  '${r.createdAt != null ? ' · ${_ago(r.createdAt!)}' : ''}',
          onTap: draft
              ? () {
                  // Drafts are private — open them in the editor.
                  context.read<AppStateCubit>().editRecipe(r);
                  context.read<FlowCubit>().setScreen(AppScreen.creatorCreate);
                }
              : null,
        ),
    ];
  }

  /// The user's cooking history, newest first.
  List<_GridItem> _cookedCards(List<CookEntry> cooked) {
    return [
      for (final (i, c) in cooked.indexed)
        _GridItem(
          recipeId: c.recipeId,
          title: c.title,
          user: 'Cooked ${_ago(c.cookedAt)}',
          emoji: c.emoji,
          color: _palette[(i + 1) % 4],
          big: i == 0,
          comment: c.rating != null ? '⭐' * c.rating!.clamp(1, 5) : null,
        ),
    ];
  }

  /// Saved recipes, drinks and places, newest first.
  List<_GridItem> _savedCards(List<SavedItem> saved, ContentState content) {
    return [
      for (final (i, s) in saved.indexed)
        _GridItem(
          title: s.title,
          user: [
            switch (s.itemType) { 'place' => '📍 Place', 'drink' => '🍸 Drink', _ => '🍽 Recipe' },
            if (s.cuisine != null && s.cuisine!.isNotEmpty) s.cuisine!,
          ].join(' · '),
          emoji: s.emoji,
          color: _palette[(i + 2) % 4],
          big: i == 0,
          comment: s.createdAt != null ? 'Saved ${_ago(s.createdAt!)}' : null,
          onTap: () => _openSaved(s, content),
        ),
    ];
  }

  void _openSaved(SavedItem item, ContentState content) {
    if (item.itemType == 'place') {
      final index = content.places.indexWhere((p) => p.id == item.itemId);
      if (index < 0) {
        ToastService.instance.show('This place is no longer available');
        return;
      }
      context.read<AppStateCubit>().setActiveCardIndex(index);
      context.read<FlowCubit>().setScreen(AppScreen.placeDetail);
      return;
    }
    final card = content.findCard(item.itemId, drink: item.itemType == 'drink');
    if (card == null) {
      ToastService.instance.show('This recipe is no longer available');
      return;
    }
    context.read<AppStateCubit>().viewRecipe(card);
    context.read<FlowCubit>().setScreen(AppScreen.recipeDetail);
  }

  /// Personal picks: the server's per-user ranking ([for_you_recipes]);
  /// falls back to profile cuisines + saves if the ranking isn't available.
  List<_GridItem> _forYouCards(List<BiteCard> recipes, List<int> rankedIds, List<String> cuisines) {
    final byId = {for (final r in recipes) r.id: r};
    final ranked = [for (final id in rankedIds) ?byId[id]];
    final wanted = {for (final c in cuisines) c.toLowerCase()};
    final sorted = ranked.isNotEmpty
        ? ranked
        : ([...recipes]..sort((a, b) {
            final am = wanted.contains(a.cuisine.toLowerCase()) ? 1 : 0;
            final bm = wanted.contains(b.cuisine.toLowerCase()) ? 1 : 0;
            if (am != bm) return bm - am;
            return Formatters.numOf(b.saved).compareTo(Formatters.numOf(a.saved));
          }));
    return [
      for (final (i, r) in sorted.take(10).indexed)
        _GridItem(
          recipeId: r.id,
          title: r.title,
          user: r.creator,
          emoji: r.emoji,
          color: _palette[i % 4],
          big: i == 0,
          comment: wanted.contains(r.cuisine.toLowerCase()) ? '🎯 ${r.cuisine} · you like this' : null,
        ),
    ];
  }

  /// Trending: ranked by real engagement this week ([trending_recipes]);
  /// falls back to all-time hearts if the ranking isn't available.
  List<_GridItem> _trendingCards(List<BiteCard> recipes, List<TrendingRank> ranking) {
    final fmt = NumberFormat.decimalPattern();
    final byId = {for (final r in recipes) r.id: r};
    final ranked = [
      for (final t in ranking)
        if (byId[t.recipeId] case final r?) (r, t),
    ];
    if (ranked.isNotEmpty) {
      return [
        for (final (i, (r, t)) in ranked.take(4).indexed)
          _GridItem(
            recipeId: r.id,
            title: r.title,
            user: r.creator,
            emoji: r.emoji,
            color: _palette[(i + 1) % 4],
            big: i == 0 || i == 3,
            trend: '#${i + 1}',
            comment: t.heartsWeek > 0
                ? '${fmt.format(t.heartsWeek)} hearts this week'
                : '${fmt.format(t.heartsTotal)} hearts',
          ),
      ];
    }
    final sorted = [...recipes]..sort((a, b) => Formatters.numOf(b.hearts).compareTo(Formatters.numOf(a.hearts)));
    return [
      for (final (i, r) in sorted.take(4).indexed)
        _GridItem(
          recipeId: r.id,
          title: r.title,
          user: r.creator,
          emoji: r.emoji,
          color: _palette[(i + 1) % 4],
          big: i == 0 || i == 3,
          trend: '#${i + 1}',
          comment: '${fmt.format(Formatters.numOf(r.hearts).round())} hearts',
        ),
    ];
  }

  Widget _buildGridTab(List<_GridItem> cards, {bool trending = false}) {
    if (cards.isEmpty) {
      return const _EmptyBlock(emoji: '🍽', title: 'Nothing here yet', message: 'Recipes will show up here soon.');
    }
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

  Widget _buildFollowingTab(SocialFeedState feed) {
    final posts = feed.visibleFollowingPosts;
    if (posts.isEmpty && feed.followingLoading) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _FeedSkeleton());
    }
    if (posts.isEmpty) {
      return const _EmptyBlock(
        emoji: '👥',
        title: 'Follow some creators!',
        message: 'Posts from people you follow will appear here.',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < posts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ZoomIn(
                duration: Duration(milliseconds: 240 + (i % 10) * 40),
                child: _RecipeGridCard(
                  card: _GridItem(
                    recipeId: posts[i].recipeId,
                    creatorHandle: posts[i].authorHandle,
                    title: posts[i].target.isNotEmpty ? posts[i].target : (posts[i].caption ?? ''),
                    user: posts[i].authorHandle,
                    emoji: posts[i].creator?.avatarEmoji ?? '🍽',
                    color: _tint(posts[i].id),
                    big: i == 0,
                    comment: '"${posts[i].caption ?? '${posts[i].target} night!'}" — ${_ago(posts[i].createdAt)}',
                  ),
                  height: i == 0 ? 180 : 140,
                  italicComment: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── CREATORS TAB ──

  Widget _buildCreatorsTab(SocialFeedState feed) {
    final creators = feed.creatorsTab;
    if (creators.isEmpty) {
      return const _EmptyBlock(emoji: '🧑‍🍳', title: 'No creators yet', message: 'Creators will show up here soon.');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < creators.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ZoomIn(
                duration: Duration(milliseconds: 240 + (i % 10) * 40),
                child: _CreatorRow(creator: creators[i], onTap: () => openCreator(context, creators[i].handle)),
              ),
            ),
        ],
      ),
    );
  }

  // ── EVENTS TAB ──

  Future<void> _toggleRsvp(SocialEvent event) async {
    final feed = context.read<SocialFeedCubit>();
    final going = feed.state.rsvps.contains(event.id);
    if (!going && event.soldOut) {
      ToastService.instance.show('😞 This event is sold out. Join the waitlist?');
      return;
    }
    final result = await feed.toggleRsvp(event);
    if (result == null) return;
    ToastService.instance.show(result ? '🎟 RSVP confirmed for ${event.title}!' : 'RSVP cancelled for ${event.title}');
  }

  void _shareEvent(SocialEvent event) {
    Clipboard.setData(ClipboardData(text: '${event.title} — ${_eventDate(event)} @ ${event.venue} on b🌶te'));
    ToastService.instance.show('📤 Share link copied!');
  }

  Widget _buildEventsTab(SocialFeedState feed) {
    final featured = feed.featuredEvent;
    final events = [
      for (final e in feed.otherEvents)
        if (_eventCategory == null || e.category == _eventCategory) e,
    ];
    List<String> avatarsFor(SocialEvent e) => [...?feed.attendeeAvatars[e.id], ...e.sampleAvatars].take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          if (featured != null) ...[
            _FeaturedEventCard(
              event: featured,
              going: feed.rsvps.contains(featured.id),
              avatars: avatarsFor(featured),
              onRsvp: () => _toggleRsvp(featured),
              onShare: () => _shareEvent(featured),
            ),
            const SizedBox(height: 16),
          ],
          ScrollableTabs(
            leftPad: 0,
            children: [
              for (final cat in _eventCategories)
                GestureDetector(
                  onTap: () => setState(() => _eventCategory = cat.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _eventCategory == cat.$1 ? AppColors.coral : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat.$2,
                      style: TextStyle(
                        color: _eventCategory == cat.$1 ? Colors.white : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (events.isEmpty)
            const _EmptyBlock(
              emoji: '🎪',
              title: 'No events here yet',
              message: 'Check back soon for local food events.',
            ),
          for (var i = 0; i < events.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ZoomIn(
                duration: Duration(milliseconds: 240 + i * 40),
                child: _EventRow(
                  event: events[i],
                  going: feed.rsvps.contains(events[i].id),
                  avatars: avatarsFor(events[i]).take(3).toList(),
                  onTap: () => _toggleRsvp(events[i]),
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
                          Text(
                            'Host an Event',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Cooking class, tasting, pop-up, or competition',
                            style: TextStyle(color: AppColors.muted, fontSize: 11),
                          ),
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
}

/// "Mar 12 · 6 PM" / "Mar 14 · 7:30 PM".
String _eventDate(SocialEvent e) {
  final t = e.startsAt;
  return '${DateFormat('MMM d').format(t)} · ${DateFormat(t.minute == 0 ? 'h a' : 'h:mm a').format(t)}';
}

/// "This Saturday · 11 AM – 3 PM" for the featured card.
String _featuredDate(SocialEvent e) {
  final t = e.startsAt;
  final today = DateUtils.dateOnly(DateTime.now());
  final days = DateUtils.dateOnly(t).difference(today).inDays;
  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    > 1 && < 7 => 'This ${DateFormat('EEEE').format(t)}',
    _ => DateFormat('MMM d').format(t),
  };
  String time(DateTime d) => DateFormat(d.minute == 0 ? 'h a' : 'h:mm a').format(d);
  final end = e.endsAt;
  return end == null ? '$day · ${time(t)}' : '$day · ${time(t)} – ${time(end)}';
}

/// A recipe-style card for the For You / Trending / Following tabs.
class _GridItem {
  const _GridItem({
    required this.title,
    required this.user,
    required this.emoji,
    required this.color,
    this.recipeId,
    this.creatorHandle,
    this.big = false,
    this.trend,
    this.comment,
    this.onTap,
  });

  final int? recipeId;

  /// Overrides the default open-recipe/creator behaviour.
  final VoidCallback? onTap;

  /// Opened when there's no recipe to show.
  final String? creatorHandle;
  final String title;
  final String user;
  final String emoji;
  final Color color;
  final bool big;
  final String? trend;
  final String? comment;
}

/// Tappable count tile at the top of the For You tab.
class _ForYouStat extends StatelessWidget {
  const _ForYouStat({
    required this.emoji,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral.withValues(alpha: 0.15) : AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.coral.withValues(alpha: 0.4) : AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: selected ? AppColors.coral : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.emoji, required this.title, required this.message});

  final String emoji;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.xp, required this.earnedPts, required this.onDismiss});

  final int xp;
  final int earnedPts;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // Same level ladder as everywhere else (loaded from `xp_tiers`).
    final tiers = TierDefinitions.all;
    final tier = TierDefinitions.tierFor(xp);
    final nextIndex = tiers.indexOf(tier) + 1;
    final next = nextIndex < tiers.length ? tiers[nextIndex] : null;
    final progress = TierDefinitions.progressInTier(xp);
    final current = (tier.name, tier.min, tier.emoji);

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
                    Text(
                      '+$earnedPts points earned!',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Cook +10 · Rate +5 · Photo +5 · Review +3 · Share +5',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
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
                        Text(
                          current.$1,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(next == null ? '$xp pts' : '$xp/${next.min} pts', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
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
    this.avatarUrl,
    required this.post,
    required this.liked,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
    required this.onOpenProfile,
  });

  final String avatarEmoji;
  final String? avatarUrl;
  final FeedPost post;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    const ratingLabels = {'🫑': 'Good 🫑', '🟠': 'Great 🟠', '🌶': 'Fire 🌶'};
    final rating = post.rating;
    final recipe = context.read<ContentCubit>().state.findCard(post.recipeId ?? -1);
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
            child: const Text(
              '🆕 YOUR POST',
              style: TextStyle(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.w700),
            ),
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
                  child: avatarUrl != null
                      ? AvatarImg(emoji: avatarEmoji, imageUrl: avatarUrl, size: 36, borderWidth: 0)
                      : Text(avatarEmoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onOpenProfile,
                      child: const Text(
                        'You',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(_ago(post.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              if (rating != null) Text(rating, style: const TextStyle(fontSize: 16)),
            ],
          ),
          if (post.hasPhoto) ...[
            const SizedBox(height: 10),
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [AppColors.coral.withValues(alpha: 0.2), AppColors.amber.withValues(alpha: 0.13)],
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: post.photoUrl != null
                  ? AppNetworkImage(
                      post.photoUrl!,
                      width: double.infinity,
                      height: 140,
                      errorBuilder: (_) =>
                          const Opacity(opacity: 0.4, child: Text('📸', style: TextStyle(fontSize: 40))),
                    )
                  : const Opacity(opacity: 0.4, child: Text('📸', style: TextStyle(fontSize: 40))),
            ),
          ],
          const SizedBox(height: 10),
          Text(post.caption ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          const SizedBox(height: 8),
          Text(
            '${recipe?.emoji ?? '🍽'} ${post.target}'
            '${rating != null && ratingLabels[rating] != null ? ' · ${ratingLabels[rating]}' : ''}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _EngagementButton(
                      icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: '${post.likesCount}',
                      color: liked ? AppColors.coral : AppColors.muted,
                      onTap: onToggleLike,
                    ),
                    const SizedBox(width: 12),
                    _EngagementButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${post.commentsCount}',
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
    required this.post,
    required this.liked,
    required this.onOpen,
    required this.onOpenProfile,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final int index;
  final FeedPost post;
  final bool liked;
  final VoidCallback onOpen;
  final VoidCallback onOpenProfile;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  static const _photoHeights = [160.0, 120.0, 180.0, 140.0, 200.0, 130.0];

  @override
  Widget build(BuildContext context) {
    final tier = TierDefinitions.tierFor(post.creator?.xp ?? 0);
    final avatarEmoji = post.creator?.avatarEmoji ?? '🧑‍🍳';
    final avatarUrl = post.creator?.avatarUrl;
    final photoColor = _tint(post.id);
    final isText = post.type == 'text';
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
                            colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.amber.withValues(alpha: 0.27)],
                          ),
                          border: Border.all(color: tier.color.withValues(alpha: 0.4), width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AvatarImg(emoji: avatarEmoji, imageUrl: avatarUrl, size: 32, borderWidth: 0),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tier.color,
                            border: Border.all(color: AppColors.bgDark, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(tier.emoji, style: const TextStyle(fontSize: 6)),
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
                                text: post.authorHandle,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              if (!isText) ...[
                                TextSpan(
                                  text: ' ${post.action} ',
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                                TextSpan(
                                  text: post.target,
                                  style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600),
                                ),
                                if (post.rating != null) TextSpan(text: ' ${post.rating}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Text(_ago(post.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            if (post.caption != null)
              Padding(
                padding: EdgeInsets.only(left: indent, top: isText ? 8 : 8, bottom: isText ? 4 : 8),
                child: Text(
                  post.caption!,
                  style: TextStyle(
                    color: isText ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.7),
                    fontSize: isText ? 15 : 13,
                    fontWeight: isText ? FontWeight.w500 : FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            if (post.hasPhoto)
              Padding(
                padding: EdgeInsets.only(left: indent, bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: _photoHeights[index % _photoHeights.length],
                    color: photoColor.withValues(alpha: 0.13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (post.photoUrl != null)
                          AppNetworkImage(
                            post.photoUrl!,
                            errorBuilder: (_) => Center(
                              child: Opacity(
                                opacity: 0.4,
                                child: Text(avatarEmoji, style: const TextStyle(fontSize: 36)),
                              ),
                            ),
                          )
                        else if (avatarUrl != null)
                          Opacity(
                            opacity: 0.6,
                            child: AvatarImg(emoji: avatarEmoji, imageUrl: avatarUrl, size: 999, borderWidth: 0),
                          )
                        else
                          Center(
                            child: Opacity(
                              opacity: 0.4,
                              child: Text(avatarEmoji, style: const TextStyle(fontSize: 36)),
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
                    label: '${post.likesCount}',
                    color: liked ? AppColors.coral : AppColors.muted,
                    onTap: onToggleLike,
                  ),
                  const SizedBox(width: 12),
                  _EngagementButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentsCount}',
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

  final Creator user;
  final bool followed;
  final VoidCallback onFollow;
  final VoidCallback onOpen;

  /// Fits avatar + 2 text lines + pill + buttons, with room for emoji
  /// (taller line height) in the handle / reason pill.
  static const double height = 188;

  @override
  Widget build(BuildContext context) {
    // Large system font sizes would overflow the fixed-height card.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
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
                  colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.amber.withValues(alpha: 0.27)],
                ),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.33)),
              ),
              clipBehavior: Clip.antiAlias,
              child: AvatarImg(emoji: user.avatarEmoji, imageUrl: user.avatarUrl, size: 48, borderWidth: 0),
            ),
            const SizedBox(height: 8),
            Text(
              user.handle,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${user.recipes} recipes · ${Formatters.compact(user.followers)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.13)),
              ),
              child: Text(
                user.reason.isNotEmpty
                    ? user.reason
                    : (user.specialties.isNotEmpty ? user.specialties.first : 'New on b🌶te'),
                style: const TextStyle(color: AppColors.cyan, fontSize: 9, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Buttons sit at the bottom so every card lines up.
            const Spacer(),
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
                      child: Text(
                        followed ? '✓' : 'Follow',
                        style: TextStyle(
                          color: followed ? const Color(0xFF4CAF50) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
      ),
    );
  }
}

class _RecipeGridCard extends StatelessWidget {
  const _RecipeGridCard({
    required this.card,
    this.trending = false,
    this.rank = false,
    this.height,
    this.italicComment = false,
  });

  final _GridItem card;
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
                child: Text(
                  card.trend!,
                  style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(color: Colors.white, fontSize: card.big ? 18 : 14, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
        onTap: () {
          if (card.onTap != null) return card.onTap!();
          if (openRecipe(context, card.recipeId)) return;
          final handle = card.creatorHandle;
          if (handle != null) {
            openCreator(context, handle);
          } else {
            ToastService.instance.show('This recipe is no longer available');
          }
        },
        child: rank ? Pulse(amount: 0.015, duration: const Duration(milliseconds: 2400), child: content) : content,
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creator, required this.onTap});

  final Creator creator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tier = TierDefinitions.tierFor(creator.xp);
    final badge = creator.badge.isNotEmpty ? creator.badge : '${tier.emoji} ${tier.name}';
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
            child: AvatarImg(emoji: creator.avatarEmoji, imageUrl: creator.avatarUrl, size: 48, borderWidth: 0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.name,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${creator.handle} · ${creator.recipes} recipes',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.compact(creator.followers),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Text('followers', style: TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard({
    required this.event,
    required this.going,
    required this.avatars,
    required this.onRsvp,
    required this.onShare,
  });

  final SocialEvent event;
  final bool going;
  final List<String> avatars;
  final VoidCallback onRsvp;
  final VoidCallback onShare;

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
              gradient: LinearGradient(
                colors: [
                  AppColors.coral.withValues(alpha: 0.2),
                  AppColors.amber.withValues(alpha: 0.13),
                  AppColors.coral.withValues(alpha: 0.07),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Opacity(opacity: 0.3, child: Text(event.emoji, style: const TextStyle(fontSize: 56))),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.87),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '📍 ${event.distance}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
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
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 14, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Text(
                      _featuredDate(event),
                      style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(event.description, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onRsvp,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]),
                          ),
                          child: Text(
                            going
                                ? '✓ Going'
                                : (event.price.toLowerCase().startsWith('free') ? 'RSVP Free 🎟' : 'RSVP 🎟'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onShare,
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
                      if (avatars.isNotEmpty) ...[
                        SocialProofAvatars(urls: avatars, count: avatars.length),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${event.attending} going'
                        '${event.interested > 0 ? ' · ${event.interested} interested' : ''}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
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
  const _EventRow({required this.event, required this.going, required this.avatars, required this.onTap});

  final SocialEvent event;
  final bool going;
  final List<String> avatars;
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
                  Text(
                    event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '📍 ${event.venue} · ${event.distance}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        '📅 ${_eventDate(event)}',
                        style: TextStyle(color: event.color, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const Text('·', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                      Text(
                        event.price,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        if (avatars.isNotEmpty) ...[
                          SocialProofAvatars(urls: avatars, count: avatars.length, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          going ? '✓ You + ${event.attending - 1} going' : '${event.attending} going',
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.soldOut
                                ? Colors.white.withValues(alpha: 0.06)
                                : event.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: event.soldOut
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : event.color.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            event.spotsLabel,
                            style: TextStyle(
                              color: event.soldOut ? AppColors.muted : event.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
          boxShadow: [
            BoxShadow(color: AppColors.coral.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4)),
          ],
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
