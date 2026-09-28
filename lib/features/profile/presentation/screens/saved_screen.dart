import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/floating_pill_nav.dart';
import '../../../../core/widgets/glass.dart';
import '../../../content/domain/entities/saved_item.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../data/mock_profile_data.dart';

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
            builder: (context, appState) {
              return BlocBuilder<ContentCubit, ContentState>(
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
    final filteredItems = _searchQuery.isEmpty
        ? baseFiltered
        : baseFiltered
            .where((i) =>
                i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                i.creator.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final favCount = savedItems.where((i) => i.favorited).length;

    final filters = [
      ('all', 'All (${savedItems.length})'),
      ('favorites', '⭐ Favorites ($favCount/$maxFavs)'),
      ('liked', '❤️ Liked'),
      ('myrecipes', '📸 My Recipes'),
      ('collections', '📦 Collections'),
    ];

    final showGrid = _activeFilter == 'all' || _activeFilter == 'favorites' || _activeFilter == 'liked';

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
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
                    if (isPremium)
                      GestureDetector(
                        onTap: () {
                          setState(() => _activeFilter = 'collections');
                          context.showToast('📝 Name your new list!');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: AppColors.coral),
                              SizedBox(width: 4),
                              Text('New List', style: TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
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
        if (!isPremium && showGrid)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: ZoomIn(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.09)),
                ),
                child: Row(
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Free tier: ',
                              style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: '$maxFavs favorites · Liked expire in ${expireDays}d',
                              style: TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.premium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('Upgrade', style: TextStyle(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
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
        if (_activeFilter == 'myrecipes') _buildMyRecipes(context),
        if (_activeFilter == 'collections') _buildCollections(context, isPremium),
        _buildRecentlyPassed(context, isPremium),
        _buildKitchenRequests(context),
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

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ),
      if (stillLoading)
        const LoadingState(label: 'Loading your saved items…', height: 240)
      else if (hasError)
        ErrorState(
          message: error,
          onRetry: () => context.read<ContentCubit>().reloadSaved(),
        )
      else if (filteredItems.isEmpty)
        EmptyState(
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
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _SavedItemGrid(items: filteredItems),
        ),
      Padding(
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
    ];
  }

  Widget _buildMyRecipes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text('Your personal cookbook — scanned and uploaded recipes', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          GestureDetector(
            onTap: () => context.read<FlowCubit>().setScreen(AppScreen.genieScan),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.2), style: BorderStyle.solid),
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
                    child: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.coral),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan a Recipe', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('Photo → OCR → saved to your cookbook', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.add, size: 16, color: AppColors.coral),
                ],
              ),
            ),
          ),
          for (final r in MockProfileData.myRecipes)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.glassBorder)),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                    child: Text(r.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${r.source} · ${r.date}', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.muted),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Personal recipes never expire', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCollections(BuildContext context, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text('Organize saves into themed lists', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          if (!isPremium)
            Opacity(
              opacity: 0.7,
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.13)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 16, color: AppColors.amber),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Custom Collections', style: TextStyle(color: AppColors.amber, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Premium — create unlimited lists', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.premium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                        child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isPremium)
            GestureDetector(
              onTap: () => context.showToast('📝 Name your new list!'),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.27)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.add, size: 22, color: AppColors.coral),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create New List', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('Group your favorite recipes by theme, meal type, or occasion', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (final c in MockProfileData.collections)
            GestureDetector(
              onTap: () => setState(() => _activeFilter = 'all'),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorder)),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.color.withValues(alpha: 0.2)),
                      ),
                      child: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('${c.count} recipes', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPassed(BuildContext context, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENTLY PASSED', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                if (!isPremium) const Text('🔒 Premium', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockProfileData.recentlyPassed.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = MockProfileData.recentlyPassed[i];
                return GestureDetector(
                  onTap: () {
                    if (isPremium) {
                      context.showToast('↩️ ${item.title} restored to your deck!');
                    } else {
                      PremiumGateService.instance.show(
                        'Undo Passed Cards',
                        'premium',
                        'See and restore recipes you passed. Never lose a great dish again.',
                      );
                    }
                  },
                  child: Opacity(
                    opacity: isPremium ? 1 : 0.5,
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isPremium ? 0.03 : 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: isPremium ? 0.06 : 0.03)),
                      ),
                      child: Stack(
                        children: [
                          if (!isPremium)
                            const Positioned(top: 0, right: 0, child: Icon(Icons.lock_rounded, size: 10, color: AppColors.amber)),
                          Column(
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 6),
                              Text(
                                item.title.split(' ').take(2).join(' '),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: isPremium ? Colors.white : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.creator,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.muted, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenRequests(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('FAMILY KITCHEN', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
                ),
                child: const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kitchen Requests', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Your family wants to eat!', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                ),
              ),
              Pulse(
                duration: const Duration(milliseconds: 2000),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
                  ),
                  child: const Text('3 new', style: TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var di = 0; di < MockProfileData.weekDays.length; di++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ZoomIn(
                      duration: Duration(milliseconds: 180 + di * 25),
                      child: _WeekSlot(day: MockProfileData.weekDays[di], index: di),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < MockProfileData.kitchenRequests.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ZoomIn(
                duration: Duration(milliseconds: 260 + i * 60),
                child: _KitchenRequestCard(request: MockProfileData.kitchenRequests[i]),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.03), AppColors.coral.withValues(alpha: 0.02)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_none_rounded, size: 14, color: AppColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                      children: const [
                        TextSpan(text: 'Tonight 6pm: ', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700)),
                        TextSpan(text: "Jake's Gochujang Chicken request — ready to cook?"),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 12, color: AppColors.muted),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SavedCard(item: items[0], color: _typeColor(items[0]), height: 160, titleSize: 16, emojiSize: 40, typeEmoji: _typeEmoji(items[0].itemType)),
          ),
        if (items.length > 1)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
      onTap: () => context.read<FlowCubit>().setScreen(
            item.itemType == 'place' ? AppScreen.placeDetail : AppScreen.recipeDetail,
          ),
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
                child: Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
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

class _WeekSlot extends StatelessWidget {
  const _WeekSlot({required this.day, required this.index});

  final String day;
  final int index;

  @override
  Widget build(BuildContext context) {
    final assigned = index == 2 ? '🍗' : index == 5 ? '🍝' : null;
    final isToday = index == 4;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.cyan.withValues(alpha: 0.07)
            : assigned != null
                ? const Color(0x0F4CAF50)
                : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.cyan.withValues(alpha: 0.27)
              : assigned != null
                  ? const Color(0x334CAF50)
                  : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: isToday ? AppColors.cyan : AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            assigned ?? '—',
            style: TextStyle(fontSize: assigned != null ? 16 : 10, color: assigned != null ? Colors.white : Colors.white.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }
}

class _KitchenRequestCard extends StatelessWidget {
  const _KitchenRequestCard({required this.request});

  final ({String from, String emoji, String title, String note, String time, String avatar, String? day}) request;

  @override
  Widget build(BuildContext context) {
    final isNew = request.day == null;
    return Container(
      padding: const EdgeInsets.all(14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Stack(
        children: [
          if (isNew)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Shimmer(
                baseColor: Colors.transparent,
                highlightColor: AppColors.cyan.withValues(alpha: 0.4),
                duration: const Duration(milliseconds: 3000),
                child: Container(height: 2, color: AppColors.cyan.withValues(alpha: 0.15)),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
                ),
                child: AvatarImg(emoji: request.avatar, size: 40, borderWidth: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(request.from, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text(request.time, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                        if (request.day != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0x1A4CAF50),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0x334CAF50)),
                            ),
                            child: Text(request.day!, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${request.emoji} ${request.title}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('"${request.note}"', style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 10, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (request.day == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => context.showToast('✅ ${request.title} added to your week! Tap a day to assign.'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.cyan.withValues(alpha: 0.2), AppColors.cyan.withValues(alpha: 0.09)]),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.27)),
                        ),
                        child: const Text('📅 Plan It', style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => context.showToast('👋 Request dismissed'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                        child: Text('Skip', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                      ),
                    ),
                  ],
                )
              else
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: Color(0xFF4CAF50)),
                    SizedBox(width: 4),
                    Text('Planned', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
