import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/glass.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../data/genie_filter_store.dart';
import '../../domain/genie_filters.dart';
import '../../domain/genie_suggestions.dart';

/// What a hub tile does when tapped.
enum _GenieActionKind {
  /// Open [_GenieAction.dest].
  navigate,

  /// Open a personalized pick from the current deck in its detail screen.
  suggest,

  /// Switch the deck to Places.
  nearby,

  /// Open the highest-rated place.
  topRated,

  /// Open the best-rated place that's open now (reservation partners live
  /// on the place page).
  reserve,
}

/// One quick-action tile in the Genie hub grid.
class _GenieAction {
  const _GenieAction({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    this.kind = _GenieActionKind.navigate,
    this.dest,
    this.premium = false,
    this.gateTitle,
    this.gateDesc,
  });

  final String icon;
  final String title;
  final String desc;
  final Color color;
  final _GenieActionKind kind;
  final AppScreen? dest;
  final bool premium;
  final String? gateTitle;
  final String? gateDesc;
}

/// Opens [card] in its detail screen. Recipes/drinks go through
/// [AppStateCubit.viewRecipe]; places are addressed by catalog index.
void _openCard(BuildContext context, BiteCard card) {
  final appState = context.read<AppStateCubit>();
  final flow = context.read<FlowCubit>();
  if (card.isPlace) {
    final places = context.read<ContentCubit>().state.places;
    final index = places.indexWhere((p) => p.id == card.id);
    if (index < 0) return;
    appState.setSubTab(DeckTab.places);
    appState.setActiveCardIndex(index);
    flow.setScreen(AppScreen.placeDetail);
    return;
  }
  appState.setActiveCardIndex(0);
  appState.viewRecipe(card);
  flow.setScreen(AppScreen.recipeDetail);
}

bool _isOpen(BiteCard p) {
  final s = (p.status ?? '').toLowerCase();
  return s.contains('open') && !s.contains('closed');
}

/// The Genie hub — a bottom-anchored modal sheet with the AI orb, Crave
/// Radar search, a 2×2 quick-action grid, personalized picks and the Meal
/// Timing Planner banner. Ports `GenieScreen` from `screens-genie.jsx`.
///
/// Picks, place stats and the filter badge come from live state
/// ([ContentCubit] catalog, saved items and cook history; [AppStateCubit]
/// cuisines/premium; [GenieFilterStore]). Chat / Scan / Meals / Planner open
/// their own screens.
class GenieScreen extends StatelessWidget {
  const GenieScreen({super.key});

  List<_GenieAction> _actionsFor(DeckTab tab, ContentState content) {
    switch (tab) {
      case DeckTab.places:
        final places = content.places;
        final openCount = places.where(_isOpen).length;
        return [
          _GenieAction(
            icon: '📍',
            title: 'Nearby',
            desc: places.isEmpty
                ? 'Browse restaurants around you'
                : '${places.length} spots · $openCount open now',
            color: AppColors.placesPurple,
            kind: _GenieActionKind.nearby,
          ),
          const _GenieAction(
            icon: '⭐',
            title: 'Top Rated',
            desc: 'The highest-rated spot right now',
            color: AppColors.coral,
            kind: _GenieActionKind.topRated,
          ),
          const _GenieAction(
            icon: '📸',
            title: 'Scan',
            desc: 'Snap a menu or storefront',
            color: AppColors.cyan,
            dest: AppScreen.genieScan,
          ),
          const _GenieAction(
            icon: '🗓',
            title: 'Reserve',
            desc: 'Find open tables tonight',
            color: AppColors.saveGreen,
            kind: _GenieActionKind.reserve,
            premium: true,
            gateTitle: 'Reservations',
            gateDesc:
                'Search availability across OpenTable, Resy & Google '
                '— book tables directly from b🌶te.',
          ),
        ];
      case DeckTab.drinks:
        return const [
          _GenieAction(
            icon: '✨',
            title: 'Suggest',
            desc: 'What should I mix?',
            color: AppColors.amber,
            kind: _GenieActionKind.suggest,
          ),
          _GenieAction(
            icon: '🎯',
            title: 'Filter',
            desc: 'Vibe, spirit, cuisine & type',
            color: AppColors.drinksBlue,
            dest: AppScreen.genieFilter,
            premium: true,
            gateTitle: 'Smart Filters',
            gateDesc:
                'Filter by spirit type, occasion, cuisine and '
                'non-alcoholic options.',
          ),
          _GenieAction(
            icon: '📸',
            title: 'Scan',
            desc: 'Snap a bottle or cocktail menu',
            color: AppColors.cyan,
            dest: AppScreen.genieScan,
          ),
          _GenieAction(
            icon: '🍹',
            title: 'Pairings',
            desc: 'Match drinks to your meal',
            color: AppColors.saveGreen,
            dest: AppScreen.genieMeals,
            premium: true,
            gateTitle: 'Drink Pairings',
            gateDesc:
                'AI-powered drink pairing for any dish — wine, '
                'cocktails, mocktails, or beer.',
          ),
        ];
      case DeckTab.food:
        return const [
          _GenieAction(
            icon: '✨',
            title: 'Suggest',
            desc: 'What should I cook?',
            color: AppColors.amber,
            kind: _GenieActionKind.suggest,
          ),
          _GenieAction(
            icon: '🎯',
            title: 'Filter',
            desc: 'Vibe, cuisine, diet, time & spice',
            color: AppColors.coral,
            dest: AppScreen.genieFilter,
            premium: true,
            gateTitle: 'Smart Filters',
            gateDesc:
                'Unlock precision filters for cook time, spice level, '
                'difficulty, cuisine and dietary needs.',
          ),
          _GenieAction(
            icon: '📸',
            title: 'Scan',
            desc: 'Snap ingredients or a recipe',
            color: AppColors.cyan,
            dest: AppScreen.genieScan,
          ),
          _GenieAction(
            icon: '🍽',
            title: 'Meals',
            desc: 'Full meal pairings — entree, side & drink',
            color: AppColors.saveGreen,
            dest: AppScreen.genieMeals,
            premium: true,
            gateTitle: 'Meal Builder',
            gateDesc:
                'Build complete meals with AI-curated pairings and '
                'synchronized cook timers.',
          ),
        ];
    }
  }

  void _openAction(BuildContext context, _GenieAction a, AppState state) {
    if (a.premium && !state.isPremium) {
      PremiumGateService.instance.show(
        a.gateTitle ?? a.title,
        'premium',
        a.gateDesc ?? 'Upgrade to Premium to unlock this feature.',
      );
      return;
    }
    final flow = context.read<FlowCubit>();
    final content = context.read<ContentCubit>().state;
    switch (a.kind) {
      case _GenieActionKind.navigate:
        final dest = a.dest;
        if (dest != null) flow.setScreen(dest);
      case _GenieActionKind.suggest:
        _surprise(context, state);
      case _GenieActionKind.nearby:
        final appState = context.read<AppStateCubit>();
        appState.setSubTab(DeckTab.places);
        appState.setActiveCardIndex(0);
        flow.setScreen(AppScreen.swipeDeck);
      case _GenieActionKind.topRated:
      case _GenieActionKind.reserve:
        final pool = a.kind == _GenieActionKind.reserve
            ? content.places.where(_isOpen).toList()
            : content.places;
        final best = GenieSuggestions.rankPlaces(
          places: pool,
          favoriteCuisines: state.userCuisines,
          limit: 1,
        );
        if (best.isEmpty) {
          ToastService.instance.show(
            content.loading
                ? '⏳ Still loading places…'
                : a.kind == _GenieActionKind.reserve
                ? '😴 No places are open right now'
                : 'No places to show yet',
          );
          return;
        }
        _openCard(context, best.first.card);
    }
  }

  /// "Suggest" — opens a random pick from the top personalized matches.
  void _surprise(BuildContext context, AppState state) {
    final content = context.read<ContentCubit>().state;
    final drinks = state.subTab == DeckTab.drinks;
    final picks = GenieSuggestions.rank(
      pool: drinks ? content.drinks : content.recipes,
      favoriteCuisines: state.userCuisines,
      saved: content.savedItems,
      cookHistory: content.cookHistory,
      filters: GenieFilterStore.instance.appliedFor(state.subTab),
      kind: drinks ? GenieFilterKind.drinks : GenieFilterKind.food,
      limit: 5,
    );
    if (picks.isEmpty) {
      ToastService.instance.show(
        content.loading
            ? '⏳ Still loading — try again in a sec'
            : '🤷 Nothing matches right now — try clearing your filters',
      );
      return;
    }
    HapticsService.medium();
    final pick = picks[Random().nextInt(picks.length)];
    ToastService.instance.show('✨ ${pick.reason}');
    _openCard(context, pick.card);
  }

  void _openCraveRadar(BuildContext context) {
    HapticsService.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ContentCubit>(),
        child: _CraveRadarSheet(
          favoriteCuisines: context.read<AppStateCubit>().state.userCuisines,
          onOpen: (card) {
            Navigator.of(context).pop();
            _openCard(context, card);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStateCubit, AppState>(
      buildWhen: (prev, curr) =>
          prev.subTab != curr.subTab ||
          prev.isPremium != curr.isPremium ||
          prev.userCuisines != curr.userCuisines,
      builder: (context, state) {
        final content = context.watch<ContentCubit>().state;
        final actions = _actionsFor(state.subTab, content);
        final flow = context.read<FlowCubit>();

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: flow.goBack,
                // ClipRect bounds the blur to this layer's own rect.
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: flow.goBack,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    120,
                                  ),
                                  child: _GenieSheetContent(
                                    actions: actions,
                                    state: state,
                                    content: content,
                                    onOpen: (a) =>
                                        _openAction(context, a, state),
                                    onCraveRadar: () =>
                                        _openCraveRadar(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GenieSheetContent extends StatelessWidget {
  const _GenieSheetContent({
    required this.actions,
    required this.state,
    required this.content,
    required this.onOpen,
    required this.onCraveRadar,
  });

  final List<_GenieAction> actions;
  final AppState state;
  final ContentState content;
  final ValueChanged<_GenieAction> onOpen;
  final VoidCallback onCraveRadar;

  bool get isPremium => state.isPremium;

  List<GenieSuggestion> _picks() {
    switch (state.subTab) {
      case DeckTab.places:
        return GenieSuggestions.rankPlaces(
          places: content.places,
          favoriteCuisines: state.userCuisines,
        );
      case DeckTab.drinks:
      case DeckTab.food:
        final drinks = state.subTab == DeckTab.drinks;
        return GenieSuggestions.rank(
          pool: drinks ? content.drinks : content.recipes,
          favoriteCuisines: state.userCuisines,
          saved: content.savedItems,
          cookHistory: content.cookHistory,
          filters: GenieFilterStore.instance.appliedFor(state.subTab),
          kind: drinks ? GenieFilterKind.drinks : GenieFilterKind.food,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final picks = _picks();
    final savedCount = content.savedItems.length;
    final cookedCount = content.cookHistory.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: flow.goBack,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Pulse(
                    amount: 0.06,
                    child: GestureDetector(
                      onTap: () => flow.setScreen(AppScreen.genieChat),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [AppColors.amber, AppColors.coral],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.4),
                              blurRadius: 32,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🧞 Food Genie',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    savedCount + cookedCount == 0
                        ? 'Your AI cooking & discovery assistant'
                        : '🔖 $savedCount saved · 🍳 $cookedCount cooked',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ZoomIn(child: _CraveRadarCta(onTap: onCraveRadar)),
            const SizedBox(height: 14),
            _ActiveFiltersBar(tab: state.subTab),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                for (var i = 0; i < actions.length; i++)
                  ZoomIn(
                    duration: Duration(milliseconds: 240 + i * 60),
                    child: _ActionTile(
                      action: actions[i],
                      isPremium: isPremium,
                      onTap: () => onOpen(actions[i]),
                    ),
                  ),
              ],
            ),
            if (picks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PicksRow(
                title: state.subTab == DeckTab.places
                    ? 'GENIE PICKS NEARBY'
                    : 'GENIE PICKS FOR YOU',
                picks: picks,
              ),
            ],
            const SizedBox(height: 12),
            Glass(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              borderColor: isPremium
                  ? const Color(0x334CAF50)
                  : AppColors.amber.withValues(alpha: 0.13),
              onTap: () {
                if (isPremium) {
                  flow.setScreen(AppScreen.geniePlanner);
                } else {
                  PremiumGateService.instance.show(
                    'Meal Timing Planner',
                    'premium',
                    'Time multiple dishes to land on the table together — '
                        'Genie calculates start times and guides each step.',
                  );
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPremium ? const Color(0x1F4CAF50) : null,
                      gradient: isPremium
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.amber.withValues(alpha: 0.2),
                                AppColors.coral.withValues(alpha: 0.13),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('⏱', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Meal Timing Planner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isPremium) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: AppColors.amber.withValues(
                                      alpha: 0.33,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.mealItems.isEmpty
                              ? "Time your dishes so everything's hot & ready "
                                    'at once'
                              : '${state.mealItems.length} '
                                    '${state.mealItems.length == 1 ? 'dish' : 'dishes'} '
                                    'in your meal tray — plan the timing',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isPremium ? AppColors.saveGreen : AppColors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x0F4CAF50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x264CAF50)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 8),
                    Text(
                      'Unlimited Genie — Premium active',
                      style: TextStyle(
                        color: AppColors.saveGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Free plan — picks, Crave Radar & Suggest included',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => flow.setScreen(AppScreen.premium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.coral.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'Unlimited →',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              state.userCuisines.isEmpty
                  ? 'Picks are based on your saves & cook history ✨'
                  : 'Picks are based on your ${state.userCuisines.length} '
                        'favorite cuisines, saves & cooks ✨',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x40FFFFFF), fontSize: 11),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => flow.setScreen(AppScreen.genieChat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: const Row(
                  children: [
                    Text('🧞', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ask Genie anything...',
                        style: TextStyle(
                          color: Color(0x73FFFFFF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.send, size: 16, color: AppColors.amber),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: -4,
          right: 0,
          child: GestureDetector(
            onTap: flow.goBack,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// "🎯 N filters on" strip — shown while Genie filters narrow this deck.
class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({required this.tab});

  final DeckTab tab;

  @override
  Widget build(BuildContext context) {
    final store = GenieFilterStore.instance;
    return ValueListenableBuilder<Map<GenieFilterKind, GenieFilters>>(
      valueListenable: store.applied,
      builder: (context, _, _) {
        final filters = store.appliedFor(tab);
        final kind = GenieFilterStore.kindFor(tab);
        if (filters == null || kind == null) return const SizedBox.shrink();
        final content = context.watch<ContentCubit>().state;
        final pool = kind == GenieFilterKind.drinks
            ? content.drinks
            : content.recipes;
        final matches = filters.apply(pool, kind).length;
        final n = filters.activeCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Glass(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderColor: AppColors.coral.withValues(alpha: 0.3),
            onTap: () =>
                context.read<FlowCubit>().setScreen(AppScreen.genieFilter),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$n ${n == 1 ? 'filter' : 'filters'} on · '
                    '$matches of ${pool.length} in your deck',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticsService.light();
                    store.deactivate(kind);
                    ToastService.instance.show(
                      '🍽 Showing everything — filters stay saved',
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Turn off',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal row of personalized picks, each with its reason.
class _PicksRow extends StatelessWidget {
  const _PicksRow({required this.title, required this.picks});

  final String title;
  final List<GenieSuggestion> picks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < picks.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Glass(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(10),
                  onTap: () => _openCard(context, picks[i].card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        picks[i].card.emoji.isEmpty
                            ? '🍽'
                            : picks[i].card.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        picks[i].card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        picks[i].reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Crave Radar — type a craving, get real places that serve it (by name,
/// cuisine, tags and menu highlights) plus recipes to cook it yourself.
class _CraveRadarSheet extends StatefulWidget {
  const _CraveRadarSheet({
    required this.favoriteCuisines,
    required this.onOpen,
  });

  final List<String> favoriteCuisines;
  final ValueChanged<BiteCard> onOpen;

  @override
  State<_CraveRadarSheet> createState() => _CraveRadarSheetState();
}

class _CraveRadarSheetState extends State<_CraveRadarSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static int _score(BiteCard c, List<String> terms) {
    final title = c.title.toLowerCase();
    final cuisine = c.cuisine.toLowerCase();
    final tags = GenieFilters.tagsOf(c);
    final menu = [for (final m in c.menuHighlights) m.name.toLowerCase()];
    var score = 0;
    for (final t in terms) {
      final norm = GenieFilters.normalize(t);
      var hit = 0;
      if (title.contains(t)) hit = 3;
      if (hit == 0 && menu.any((m) => m.contains(t))) hit = 3;
      if (hit == 0 && cuisine.contains(t)) hit = 2;
      if (hit == 0 && norm.isNotEmpty && tags.any((g) => g.contains(norm))) {
        hit = 1;
      }
      if (hit == 0) return 0; // every word must match something
      score += hit;
    }
    return score;
  }

  List<BiteCard> _search(List<BiteCard> pool, List<String> terms) {
    final scored = [
      for (final c in pool)
        if (_score(c, terms) case final s when s > 0) (card: c, score: s),
    ]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return (b.card.rating ?? 0).compareTo(a.card.rating ?? 0);
      });
    return [for (final s in scored) s.card];
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentCubit>().state;
    final terms = _query.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
    final places = terms.isEmpty
        ? const <BiteCard>[]
        : _search(content.places, terms);
    final recipes = terms.isEmpty
        ? const <BiteCard>[]
        : _search(content.recipes, terms);
    final quick = [
      ...widget.favoriteCuisines.take(4),
      for (final s in const ['Tacos', 'Ramen', 'Spicy', 'Pasta'])
        if (!widget.favoriteCuisines.contains(s)) s,
    ].take(6).toList();
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: height * 0.8),
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '🔍 Crave Radar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: AppColors.cyan,
                  decoration: InputDecoration(
                    hintText: 'What are you craving? e.g. birria tacos',
                    hintStyle: const TextStyle(color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.cyan),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            onPressed: () => setState(_query.clear),
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: quick.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setState(() {
                      _query.text = quick[i];
                      _query.selection = TextSelection.collapsed(
                        offset: quick[i].length,
                      );
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        quick[i],
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: terms.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Text(
                          'Type a dish, ingredient or cuisine — I’ll find '
                          'who serves it and how to make it.',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      )
                    : places.isEmpty && recipes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Text(
                          content.loading
                              ? 'Loading places & recipes…'
                              : 'No matches for “${_query.text.trim()}” yet — '
                                    'try a cuisine or a single dish name.',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          if (places.isNotEmpty) ...[
                            _label('SERVED NEARBY'),
                            for (final p in places.take(6))
                              _ResultRow(
                                card: p,
                                subtitle: [
                                  if (p.rating != null)
                                    '★ ${p.rating!.toStringAsFixed(1)}',
                                  ?p.distance,
                                  ?p.status,
                                ].join(' · '),
                                onTap: () => widget.onOpen(p),
                              ),
                          ],
                          if (recipes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _label('COOK IT YOURSELF'),
                            for (final r in recipes.take(6))
                              _ResultRow(
                                card: r,
                                subtitle: [
                                  if (r.cuisine.isNotEmpty) r.cuisine,
                                  if (r.time.isNotEmpty) r.time,
                                  if (r.diff.isNotEmpty) r.diff,
                                ].join(' · '),
                                onTap: () => widget.onOpen(r),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.card,
    required this.subtitle,
    required this.onTap,
  });

  final BiteCard card;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            Text(
              card.emoji.isEmpty ? '🍽' : card.emoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _CraveRadarCta extends StatelessWidget {
  const _CraveRadarCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cyan.withValues(alpha: 0.13),
              AppColors.placesPurple.withValues(alpha: 0.13),
            ],
          ),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.27)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.13),
              blurRadius: 28,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 24.0 + i * 14,
                      height: 24.0 + i * 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cyan.withValues(
                            alpha: [0.4, 0.27, 0.13][i],
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan.withValues(alpha: 0.2),
                          AppColors.placesPurple.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.cyan,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Crave Radar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.33),
                          ),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tell me what you're craving — I'll find who serves it "
                    'best nearby',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.cyan, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.isPremium,
    required this.onTap,
  });

  final _GenieAction action;
  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 20,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(action.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          if (action.premium)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPremium
                      ? const Color(0x264CAF50)
                      : AppColors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isPremium
                        ? const Color(0x594CAF50)
                        : AppColors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isPremium ? '✓' : 'PREMIUM',
                  style: TextStyle(
                    color: isPremium ? AppColors.saveGreen : AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
