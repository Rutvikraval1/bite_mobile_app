import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/floating_pill_nav.dart';
import '../../../../core/widgets/glass.dart';
import '../../../content/domain/entities/saved_item.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../../../core/widgets/app_network_image.dart';

/// The "Saved" tab — favorites, liked items, personal cookbook, collections,
/// recently-passed recall and the Family Kitchen Requests teaser.
/// Ports `SavedScreen` from `screens-profile.jsx`.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _activeFilter = 'all';
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-sync with the DB each time the Saved tab mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContentCubit>().reloadSaved();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          BlocBuilder<AppStateCubit, AppState>(
            buildWhen: (p, c) => p.isPremium != c.isPremium,
            builder: (context, appState) {
              return BlocBuilder<ContentCubit, ContentState>(
                buildWhen: (p, c) =>
                    p.savedItems != c.savedItems ||
                    p.savedLoading != c.savedLoading ||
                    p.error != c.error,
                builder: (context, content) {
                  return _buildBody(
                    context,
                    appState.isPremium,
                    content.savedItems,
                    savedLoading: content.savedLoading,
                    error: content.error,
                  );
                },
              );
            },
          ),
          const FloatingPillNav(),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isPremium,
    List<SavedItem> savedItems, {
    required bool savedLoading,
    required String? error,
  }) {
    final maxFavs = isPremium ? 15 : 5;
    final expireDays = isPremium ? 15 : 5;

    final baseFiltered = switch (_activeFilter) {
      'favorites' => savedItems.where((i) => i.favorited).toList(),
      'liked' => savedItems.where((i) => i.liked && !i.favorited).toList(),
      _ => savedItems,
    };
    final query = _searchQuery.toLowerCase();
    final filteredItems = query.isEmpty
        ? baseFiltered
        : baseFiltered
            .where((i) =>
                i.title.toLowerCase().contains(query) ||
                i.creator.toLowerCase().contains(query))
            .toList();

    final favCount = savedItems.where((i) => i.favorited).length;

    final myRecipeCount = context.select<ContentCubit, int>((c) => c.state.myRecipes.length);
    final filters = [
      ('all', 'All (${savedItems.length})'),
      ('myrecipes', '🍳 My Recipes ($myRecipeCount)'),
    ];

    final showGrid = _activeFilter == 'all' || _activeFilter == 'favorites' || _activeFilter == 'liked';

    // Slivers so a large saved-items grid is built lazily rather than as a
    // shrink-wrapped GridView inside a ListView.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _showSearch = !_showSearch),
                            child: Icon(Icons.search, size: 20, color: _showSearch ? AppColors.coral : AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search saved recipes, drinks, places...',
                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.glass,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _searchQuery.isNotEmpty ? AppColors.coral.withValues(alpha: 0.27) : AppColors.glassBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _searchQuery.isNotEmpty ? AppColors.coral.withValues(alpha: 0.27) : AppColors.glassBorder,
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (var i = 0; i < filters.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ZoomIn(
                          duration: Duration(milliseconds: 260 + i * 30),
                          child: _FilterPill(
                            label: filters[i].$2,
                            active: _activeFilter == filters[i].$1,
                            onTap: () => setState(() => _activeFilter = filters[i].$1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showGrid)
          ..._buildGridSection(
            context,
            filteredItems,
            savedItems,
            favCount,
            maxFavs,
            expireDays,
            isPremium,
            savedLoading: savedLoading,
            error: error,
          ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_activeFilter == 'myrecipes') _buildMyRecipes(context),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }

  List<Widget> _buildGridSection(
    BuildContext context,
    List<SavedItem> filteredItems,
    List<SavedItem> savedItems,
    int favCount,
    int maxFavs,
    int expireDays,
    bool isPremium, {
    required bool savedLoading,
    required String? error,
  }) {
    final subtitle = _activeFilter == 'favorites'
        ? '$favCount of $maxFavs favorite slots · Favorites never expire'
        : _activeFilter == 'liked'
            ? 'Liked items expire after $expireDays days — favorite to keep'
            : '${savedItems.length} saved items';

    // Only treat this as loading/error while nothing has arrived yet — once
    // items exist, a background refresh shouldn't wipe the list off screen.
    final stillLoading = savedLoading && savedItems.isEmpty;
    final hasError = error != null && savedItems.isEmpty;

    // Returns slivers.
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      ),
      if (stillLoading)
        const SliverToBoxAdapter(child: LoadingState(label: 'Loading your saved items…', height: 240))
      else if (hasError)
        SliverToBoxAdapter(
          child: ErrorState(
            message: error,
            onRetry: () => context.read<ContentCubit>().reloadSaved(),
          ),
        )
      else if (filteredItems.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            emoji: '🍽',
            title: 'Nothing here yet',
            message: _activeFilter == 'favorites'
                ? 'Swipe up on a recipe, then tap ⭐ to favorite it'
                : _activeFilter == 'liked'
                    ? 'Swipe up on recipes you love to save them here'
                    : 'Start swiping to build your collection!',
            action: GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.swipeDeck),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                child: const Text('Start Swiping 🌶', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: _SavedItemGrid(items: filteredItems),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
          child: Glass(
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(isPremium ? Icons.lock_open_rounded : Icons.lock_rounded, size: 18, color: isPremium ? AppColors.cyan : AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Undo Passed Recipes', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        isPremium ? 'Tap any passed card to bring it back' : 'Bring back cards you swiped away',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
                    ),
                    child: const Text('Unlocked ✓', style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w600)),
                  )
                else
                  GestureDetector(
                    onTap: () => PremiumGateService.instance.show(
                      'Undo Passed Recipes',
                      'premium',
                      'Accidentally swiped past a recipe? Premium lets you undo and bring back any card you passed.',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                      child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildMyRecipes(BuildContext context) {
    final recipes = context.watch<ContentCubit>().state.myRecipes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text('Your personal cookbook — recipes you created', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          GestureDetector(
            onTap: () => context.read<FlowCubit>().setScreen(AppScreen.creatorCreate),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.coral.withValues(alpha: 0.13)),
                    ),
                    child: const Icon(Icons.add, size: 20, color: AppColors.coral),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Recipe', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('Photo, ingredients & steps — publish or keep as draft', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (recipes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text("You haven't created any recipes yet", textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          for (final r in recipes)
            GestureDetector(
              onTap: () {
                context.read<AppStateCubit>().viewRecipe(r);
                context.read<FlowCubit>().setScreen(AppScreen.recipeDetail);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.glassBorder)),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                      child: r.image != null && r.image!.isNotEmpty
                          ? AppNetworkImage(r.image!, width: 44, height: 44)
                          : Text(r.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            '${r.isDraft ? '📝 Draft' : '✅ Published'} · ${r.cuisine} · ${r.time}',
                            style: TextStyle(color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.coral : AppColors.glass,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }
}

class _SavedItemGrid extends StatelessWidget {
  const _SavedItemGrid({required this.items});

  final List<SavedItem> items;

  Color _typeColor(SavedItem item) {
    if (item.color != null) return Color(item.color!);
    return switch (item.itemType) {
      'drink' => AppColors.drinksBlue,
      'place' => AppColors.placesPurple,
      _ => AppColors.coral,
    };
  }

  String _typeEmoji(String type) => switch (type) {
        'place' => '📍',
        'drink' => '🍸',
        _ => '🍽',
      };

  /// Returns a sliver so grid cards are built lazily as they scroll in.
  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SavedCard(item: items[0], color: _typeColor(items[0]), height: 160, titleSize: 16, emojiSize: 40, typeEmoji: _typeEmoji(items[0].itemType)),
            ),
          ),
        if (items.length > 1)
          SliverGrid.builder(
            itemCount: items.length - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final item = items[i + 1];
              return _SavedCard(item: item, color: _typeColor(item), height: 120, titleSize: 13, emojiSize: 28, typeEmoji: _typeEmoji(item.itemType));
            },
          ),
      ],
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.item,
    required this.color,
    required this.height,
    required this.titleSize,
    required this.emojiSize,
    required this.typeEmoji,
  });

  final SavedItem item;
  final Color color;
  final double height;
  final double titleSize;
  final double emojiSize;
  final String typeEmoji;

  @override
  Widget build(BuildContext context) {
    final urgent = item.daysLeft != null && item.daysLeft! <= 1;
    final soon = item.daysLeft != null && item.daysLeft! <= 3;
    return GestureDetector(
      onTap: () {
        if (item.itemType == 'recipe') {
          final card = context.read<ContentCubit>().state.findCard(item.itemId);
          if (card != null) context.read<AppStateCubit>().viewRecipe(card);
        }
        context.read<FlowCubit>().setScreen(
              item.itemType == 'place'
                  ? AppScreen.placeDetail
                  : AppScreen.recipeDetail,
            );
      },
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: urgent
              ? Border.all(color: AppColors.coral.withValues(alpha: 0.35))
              : soon
                  ? Border.all(color: AppColors.amber.withValues(alpha: 0.25))
                  : Border.all(color: AppColors.glassBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.13), AppColors.bgCard],
          ),
        ),
        child: Stack(
          children: [
            if (item.imageUrl != null)
              Positioned.fill(
                child: AppNetworkImage(item.imageUrl!),
              ),
            if (item.imageUrl != null)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A000000), Color(0x99000000)],
                    ),
                  ),
                ),
              ),
            if (item.imageUrl == null)
              Positioned(
                top: height * 0.3,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(opacity: 0.3, child: Text(item.emoji, style: TextStyle(fontSize: emojiSize))),
                ),
              ),
            if (item.daysLeft != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: urgent ? AppColors.coral.withValues(alpha: 0.13) : AppColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: urgent ? AppColors.coral.withValues(alpha: 0.27) : AppColors.amber.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    urgent ? '⚠️ Expires today' : '${item.daysLeft}d left',
                    style: TextStyle(color: urgent ? AppColors.coral : AppColors.amber, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (item.favorited)
              const Positioned(top: 8, left: 8, child: Icon(Icons.star_rounded, size: 14, color: AppColors.amber)),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  HapticsService.selection();
                  context.read<ContentCubit>().removeSavedItem(item.id);
                },
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.creator, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ),
                      Text(typeEmoji, style: const TextStyle(fontSize: 10)),
                    ],
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

