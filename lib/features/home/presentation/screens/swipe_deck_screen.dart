import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/badge_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bite_scale.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/floating_pill_nav.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../widgets/daily_chest_overlay.dart';
import '../widgets/deck_card.dart';
import '../widgets/meal_planner_sheet.dart';
import '../widgets/streak_sheet.dart';
import '../widgets/swipe_deck_top_bar.dart';
import '../widgets/xp_progress_bar.dart';

/// The home swipe deck — ports `SwipeDeckScreen` from `screens-deck.jsx`.
class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  int _cardIndex = 0;
  bool _deckLoading = true;
  Timer? _loadingTimer;

  /// Drag offset lives in a notifier so finger movement only repaints the
  /// card transform instead of rebuilding the whole screen every frame.
  final ValueNotifier<double> _drag = ValueNotifier<double>(0);
  double get _dragY => _drag.value;
  set _dragY(double v) => _drag.value = v;
  bool _isDragging = false;
  String? _exitDirection; // "up" | "down"
  String? _swipeResult; // "saved" | "passed"
  bool _likeAnim = false;
  bool _passAnim = false;
  bool _superFav = false;
  int? _xpFlash;
  Timer? _flashTimer;

  ({String title, String emoji, int index})? _undoCard;
  Timer? _undoTimer;

  bool _showServicePicker = false;

  final Map<DeckTab, bool> _expandedByCat = {
    DeckTab.food: false,
    DeckTab.drinks: false,
    DeckTab.places: false,
  };

  @override
  void initState() {
    super.initState();
    _deckLoading = false;
    _loadingTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _deckLoading = false);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _flashTimer?.cancel();
    _undoTimer?.cancel();
    _drag.dispose();
    super.dispose();
  }

  List<BiteCard> get _deck {
    final state = context.read<ContentCubit>().state;
    final tab = context.read<AppStateCubit>().state.subTab;
    final raw = switch (tab) {
      DeckTab.drinks => state.drinks,
      DeckTab.places => state.places,
      _ => state.recipes,
    };
    return raw;
  }

  Color get _accentColor {
    return switch (_activeTab) {
      DeckTab.food => AppColors.coral,
      DeckTab.drinks => AppColors.drinksBlue,
      DeckTab.places => AppColors.placesPurple,
    };
  }

  DeckTab get _activeTab => context.read<AppStateCubit>().state.subTab;

  void _setXpFlash(int pts) {
    setState(() => _xpFlash = pts);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _xpFlash = null);
    });
  }

  void _openDetail(BiteCard card) {
    context.read<AppStateCubit>().setActiveCardIndex(_cardIndex);
    final flow = context.read<FlowCubit>();
    if (card.isPlace) {
      flow.setScreen(AppScreen.placeDetail);
    } else {
      flow.setScreen(AppScreen.recipeDetail);
    }
  }

  void _onDragEnd() {
    if (!_isDragging) return;
    setState(() => _isDragging = false);

    final appState = context.read<AppStateCubit>();
    final content = context.read<ContentCubit>();
    final deck = _deck;
    if (deck.isEmpty) {
      setState(() => _dragY = 0);
      return;
    }
    final card = deck[_cardIndex % deck.length];

    if (_dragY > 80) {
      // SAVE
      setState(() {
        _exitDirection = 'up';
        _likeAnim = true;
        _swipeResult = 'saved';
      });
      appState.addXp(8);
      _setXpFlash(8);
      content.recordSwipe(
        itemType: switch (_activeTab) {
          DeckTab.drinks => 'drink',
          DeckTab.places => 'place',
          _ => 'recipe',
        },
        itemId: card.id,
        action: 'save',
        cuisine: card.cuisine,
      );
      if (_superFav) {
        BadgeService.instance.award(const ['creator_match']);
      }
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _likeAnim = false;
          _exitDirection = null;
          _cardIndex++;
          if (_cardIndex + 1 == 8) {
            ToastService.instance.show(
              '🏅 Achievement: First Five! 5 recipes discovered',
            );
          }
          if (_cardIndex == 10 &&
              !context.read<AppStateCubit>().state.dailyChestClaimed &&
              !context.read<AppStateCubit>().state.showDailyChest) {
            Timer(const Duration(milliseconds: 800), () {
              if (mounted) {
                context.read<AppStateCubit>().setShowDailyChest(true);
              }
            });
          }
        });
      });
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _swipeResult = null);
      });
    } else if (_dragY < -80) {
      // PASS
      setState(() {
        _exitDirection = 'down';
        _passAnim = true;
        _swipeResult = 'passed';
      });
      appState.addXp(4);
      _setXpFlash(4);
      content.recordSwipe(
        itemType: switch (_activeTab) {
          DeckTab.drinks => 'drink',
          DeckTab.places => 'place',
          _ => 'recipe',
        },
        itemId: card.id,
        action: 'pass',
        cuisine: card.cuisine,
      );
      setState(() {
        _undoCard = (title: card.title, emoji: card.emoji, index: _cardIndex);
      });
      _undoTimer?.cancel();
      _undoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _undoCard = null);
      });
      Timer(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _passAnim = false;
          _exitDirection = null;
          _cardIndex++;
        });
      });
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _swipeResult = null);
      });
    }
    setState(() => _dragY = 0);
  }

  void _onSuperFav() {
    if (_superFav) return;
    setState(() => _superFav = true);
    context.read<AppStateCubit>().addXp(15);
    _setXpFlash(15);
    ToastService.instance.show('⭐ Favorited! +15 XP');
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _superFav = false;
        _exitDirection = 'up';
        _likeAnim = true;
      });
      final deck = _deck;
      if (deck.isNotEmpty) {
        context.read<ContentCubit>().recordSwipe(
          itemType: 'recipe',
          itemId: deck[_cardIndex % deck.length].id,
          action: 'super_fav',
        );
      }
      BadgeService.instance.award(const ['super_fav']);
      Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _likeAnim = false;
          _exitDirection = null;
          _cardIndex++;
        });
      });
    });
  }

  void _undo() {
    final app = context.read<AppStateCubit>();
    final isPremium = app.state.isPremium;
    final undo = _undoCard;
    if (undo == null) return;
    if (isPremium) {
      setState(() {
        _cardIndex = undo.index;
        _undoCard = null;
      });
      ToastService.instance.show('↩️ Card restored!');
    } else {
      setState(() => _undoCard = null);
      PremiumGateService.instance.show(
        'Undo Swipe',
        'premium',
        'Accidentally passed? Premium lets you undo and bring back any card '
            'you swiped past.',
      );
    }
  }

  void _onMealTap(BiteCard card) {
    final app = context.read<AppStateCubit>();
    final inMeal = app.state.mealItems.any((m) => m.title == card.title);
    if (inMeal) {
      context.read<FlowCubit>().setScreen(AppScreen.mealBuilder);
      return;
    }
    if (app.state.isPremium) {
      app.setMealPlannerSheet(
        MealPlannerSheet(
          title: card.title,
          emoji: card.emoji,
          color: _accentColor.toARGB32(),
          type: switch (_activeTab) {
            DeckTab.drinks => 'drink',
            DeckTab.places => 'place',
            _ => 'food',
          },
        ),
      );
    } else {
      PremiumGateService.instance.show(
        'Meal Planner',
        'premium',
        'Plan meals for the week — assign recipes to breakfast, lunch, '
            'dinner for any day. Includes grocery list auto-builder.',
      );
    }
  }

  Future<void> _addMealToPlan(String dayKey, String mealSlot) async {
    final app = context.read<AppStateCubit>();
    final sheet = app.state.mealPlannerSheet;
    final content = context.read<ContentCubit>();
    if (sheet == null) return;

    await content.addMealPlan(
      planDate: dayKey,
      mealSlot: mealSlot,
      title: sheet.title,
      emoji: sheet.emoji,
      color: '#${(sheet.color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
    );
    app.addMealItem(
      MealItem(
        title: sheet.title,
        emoji: sheet.emoji,
        type: sheet.type,
        color: sheet.color,
      ),
    );
    final slotLabel = switch (mealSlot) {
      'breakfast' => 'Breakfast',
      'lunch' => 'Lunch',
      'dinner' => 'Dinner',
      'dessert' => 'Dessert',
      _ => 'Snack',
    };
    ToastService.instance.show('✅ ${sheet.title} → $slotLabel!');
    BadgeService.instance.award(const ['meal_planner']);
    app.setMealPlannerSheet(null);
    HapticsService.selection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, content) {
          final contentLoading = content.loading;
          return BlocBuilder<AppStateCubit, AppState>(
            buildWhen: (prev, curr) =>
                prev.subTab != curr.subTab ||
                prev.ageVerified != curr.ageVerified ||
                prev.locationGranted != curr.locationGranted ||
                prev.xp != curr.xp ||
                prev.biteCoins != curr.biteCoins ||
                prev.mealItems != curr.mealItems ||
                prev.showDailyChest != curr.showDailyChest ||
                prev.showStreakSheet != curr.showStreakSheet ||
                prev.mealPlannerSheet != curr.mealPlannerSheet,
            builder: (context, state) {
              final scale = BiteScale.of(context);
              final deck = _deckFor(state.subTab, content);
              final card = deck.isEmpty ? null : deck[_cardIndex % deck.length];
              final infoExpanded = _expandedByCat[state.subTab] ?? false;

              return BlocBuilder<AuthCubit, AuthState>(
                builder: (context, auth) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBackground(deck, card),
                      if (card != null)
                        _buildCardStack(card, state, scale, infoExpanded),
                      _buildOverlays(state, auth, scale),
                      // Skeleton loading — shown while fetching, whether or
                      // not a card is already on screen.
                      if (contentLoading || _deckLoading) const _DeckSkeleton(),
                      // Deck fetch failed and left nothing to show.
                      if (!contentLoading &&
                          !_deckLoading &&
                          card == null &&
                          content.error != null)
                        ErrorState(
                          message: content.error!,
                          backgroundColor: Colors.transparent,
                          onRetry: () => context.read<ContentCubit>().refetch(),
                        ),
                      // Loaded successfully but this sub-tab has nothing.
                      if (!contentLoading &&
                          !_deckLoading &&
                          card == null &&
                          content.error == null)
                        EmptyState(
                          emoji: switch (state.subTab) {
                            DeckTab.drinks => '🥤',
                            DeckTab.places => '📍',
                            DeckTab.food => '🍽',
                          },
                          title: 'No more to show',
                          message:
                              'Check back soon for new ${state.subTab.name}.',
                        ),
                      // Gesture layer
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: (_) {
                            if (state.showDailyChest) return;
                            setState(() {
                              _isDragging = true;
                              _dragY = 0;
                            });
                          },
                          onVerticalDragUpdate: (details) {
                            if (!_isDragging) return;
                            _dragY -= details.delta.dy;
                          },
                          onVerticalDragEnd: (_) => _onDragEnd(),
                          onTap: () {
                            if (card != null) _openDetail(card);
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),
                      // Top bar + XP bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: SwipeDeckTopBar(
                            subTab: state.subTab,
                            onSubTabChanged: (t) {
                              if (t == state.subTab) return;
                              context.read<AppStateCubit>().setSubTab(t);
                              setState(() {
                                _cardIndex = 0;
                                _deckLoading = true;
                              });
                              _loadingTimer?.cancel();
                              _loadingTimer = Timer(
                                const Duration(milliseconds: 400),
                                () {
                                  if (mounted) {
                                    setState(() => _deckLoading = false);
                                  }
                                },
                              );
                            },
                            onAvatarClick: () => context
                                .read<FlowCubit>()
                                .setScreen(AppScreen.profile),
                            onBellClick: () => context
                                .read<FlowCubit>()
                                .setScreen(AppScreen.notifications),
                            onTrophyClick: () => context
                                .read<FlowCubit>()
                                .setScreen(AppScreen.competition),
                            onCrownClick: () {
                              if (state.isPremium) {
                                ToastService.instance.show(
                                  "👑 You're a b🌶te Premium member!",
                                );
                              } else {
                                PremiumGateService.instance.show(
                                  'b🌶te Premium',
                                  'premium',
                                  'Unlock unlimited Genie, meal planning, '
                                      'undo, smart filters, and recipe scanning — '
                                      '\$6.99/mo.',
                                );
                              }
                            },
                            onMealReminderClick: () => context
                                .read<FlowCubit>()
                                .setScreen(AppScreen.mealReminder),
                            onDrinksGate: () => context
                                .read<FlowCubit>()
                                .setScreen(AppScreen.drinksAgeGate),
                            onPlacesGate: () => context
                                .read<FlowCubit>()
                                .setScreen(AppScreen.genie),
                            ageVerified: state.ageVerified,
                            locationGranted: state.locationGranted,
                            xp: state.xp,
                            notificationCount: state.notificationCount,
                            avatarEmoji: auth.profile?.avatarEmoji,
                          ),
                        ),
                      ),
                      // Floating pill nav
                      const FloatingPillNav(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<BiteCard> _deckFor(DeckTab tab, ContentState content) {
    return switch (tab) {
      DeckTab.drinks => content.drinks,
      DeckTab.places => content.places,
      _ => content.recipes,
    };
  }

  Widget _buildBackground(List<BiteCard> deck, BiteCard? card) {
    final next = deck.isEmpty ? null : deck[(_cardIndex + 1) % deck.length];
    if (next == null) {
      return const ColoredBox(color: AppColors.bgDark);
    }
    return AnimatedContainer(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: EmojiThemes.cardBg(next.emoji),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
          Center(
            child: Opacity(
              opacity: 0.25,
              child: Text(
                next.emoji.isEmpty ? '🍽' : next.emoji,
                style: TextStyle(
                  fontSize: 100,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
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

  Widget _buildCardStack(
    BiteCard card,
    AppState state,
    BiteScale scale,
    bool infoExpanded,
  ) {
    final opacity = _exitDirection != null ? 0.0 : 1.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: _exitDirection != null
              ? const Duration(milliseconds: 450)
              : Duration.zero,
          opacity: opacity,
          child: ValueListenableBuilder<double>(
            valueListenable: _drag,
            builder: (context, dragY, child) {
              // Card physics
              Offset transform;
              if (_exitDirection == 'up') {
                transform = const Offset(0, -1.1);
              } else if (_exitDirection == 'down') {
                transform = const Offset(0, 1.1);
              } else {
                transform = Offset(0, -dragY * 0.4);
              }
              final rotation = _exitDirection == 'down'
                  ? 6.0
                  : dragY < 0
                  ? (dragY * 0.01).clamp(-3.0, 0.0)
                  : 0.0;
              final scaleFactor = _exitDirection == null
                  ? 1 + dragY.abs() * 0.0002
                  : _exitDirection == 'down'
                  ? 0.85
                  : 0.9;
              return Transform.translate(
                offset: transform,
                child: Transform.scale(
                  scale: scaleFactor,
                  child: Transform.rotate(
                    angle: rotation * 3.14159 / 180,
                    child: child,
                  ),
                ),
              );
            },
            child: RepaintBoundary(
              child: DeckCard(
                key: ValueKey('card-$_cardIndex'),
                card: card,
                subTab: state.subTab,
                accentColor: _accentColor,
                scale: scale,
                infoExpanded: infoExpanded,
                onToggleInfo: () {
                  setState(() {
                    _expandedByCat[state.subTab] =
                        !(_expandedByCat[state.subTab] ?? false);
                  });
                },
                onTap: () => _openDetail(card),
                onCreatorTap: () => context.read<FlowCubit>().setScreen(
                  AppScreen.creatorProfile,
                ),
                onOrderTap: () {
                  if (card.isPlace) {
                    ToastService.instance.show(
                      '🛵 Opening delivery options...',
                    );
                  } else {
                    setState(() => _showServicePicker = true);
                  }
                },
                onMealTap: () => _onMealTap(card),
                onFavoriteTap: _onSuperFav,
                onCallTap: () =>
                    ToastService.instance.show('📞 Calling restaurant...'),
                onDirectionsTap: () =>
                    ToastService.instance.show('🗺 Opening directions...'),
                onReserveTap: () =>
                    ToastService.instance.show('🪑 Opening reservations...'),
                onTagTap: (tag) =>
                    ToastService.instance.show('🔍 Filtering by $tag'),
                inMealItems: state.mealItems.any((m) => m.title == card.title),
                mealItemCount: state.mealItems.length,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlays(AppState state, AuthState auth, BiteScale scale) {
    final overlay = <Widget>[];

    // Drag indicators
    if (_isDragging) {
      overlay.add(
        ValueListenableBuilder<double>(
          valueListenable: _drag,
          builder: (context, dragY, _) => dragY.abs() > 20
              ? _DragIndicators(dragY: dragY)
              : const SizedBox.shrink(),
        ),
      );
    }

    // Persistent swipe result
    if (_swipeResult != null && !_isDragging) {
      final saved = _swipeResult == 'saved';
      overlay.add(
        Positioned(
          top: saved ? MediaQuery.sizeOf(context).height * 0.32 : null,
          bottom: saved ? null : MediaQuery.sizeOf(context).height * 0.45,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(child: _SwipeResultPill(result: _swipeResult!)),
          ),
        ),
      );
    }

    // Super fav burst
    if (_superFav) {
      overlay.add(const _SuperFavBurst());
    }

    // Like animation
    if (_likeAnim) {
      overlay.add(const _LikeBurst());
    }

    // Pass animation
    if (_passAnim) {
      overlay.add(const _PassBurst());
    }

    // Undo toast
    if (_undoCard != null && !_passAnim) {
      overlay.add(
        Positioned(
          left: 16,
          right: 16,
          bottom: 90,
          child: _UndoToast(
            undo: _undoCard!,
            isPremium: state.isPremium,
            onUndo: _undo,
            onDismiss: () => setState(() => _undoCard = null),
          ),
        ),
      );
    }

    // Idle nudge arrows
    if (!_isDragging && _exitDirection == null && !_deckLoading) {
      overlay.add(
        Positioned(
          bottom: MediaQuery.sizeOf(context).height * 0.18,
          left: 0,
          right: 0,
          child: const RepaintBoundary(child: _IdleNudge()),
        ),
      );
    }

    // Service picker
    if (_showServicePicker) {
      overlay.add(
        _ServicePicker(
          onClose: () => setState(() => _showServicePicker = false),
          onPick: (service) {
            setState(() => _showServicePicker = false);
            ToastService.instance.show(
              '🛒 Opening $service with ingredients...',
            );
          },
        ),
      );
    }

    // Daily chest
    if (state.showDailyChest && !state.dailyChestClaimed) {
      overlay.add(
        DailyChestOverlay(
          isPremium: state.isPremium,
          onClaim: (rewards) {
            final app = context.read<AppStateCubit>();
            app.addBiteCoins(rewards.coins);
            app.addXp(rewards.xp);
            app.setDailyChestClaimed(true);
          },
          onClose: () => context.read<AppStateCubit>().setShowDailyChest(false),
          onUpgradePremium: () => PremiumGateService.instance.show(
            'Spicy Chest',
            'premium',
            'Unlock daily Spicy Chests with 25–100 coins, rare frame shards, '
                'and exclusive rewards every day.',
          ),
        ),
      );
    }

    // Streak sheet
    if (state.showStreakSheet) {
      overlay.add(
        StreakSheet(
          streakCount: state.streakCount,
          longestStreak: state.longestStreak,
          streakMultiplier: state.streakMultiplier,
          streakFreezes: state.streakFreezes,
          onClose: () =>
              context.read<AppStateCubit>().setShowStreakSheet(false),
        ),
      );
    }

    // Meal planner sheet
    final sheet = state.mealPlannerSheet;
    if (sheet != null) {
      overlay.add(
        MealPlannerBottomSheet(
          sheet: sheet,
          mealCalendar: context.read<ContentCubit>().state.mealPlans,
          onAdd: _addMealToPlan,
          onClose: () =>
              context.read<AppStateCubit>().setMealPlannerSheet(null),
        ),
      );
    }

    // XP progress bar (placed above card, below top bar)
    overlay.add(
      Positioned(
        top: scale.isTiny ? 82 : 118,
        left: scale.isTiny ? 12 : 16,
        right: scale.isTiny ? 12 : 16,
        child: XpProgressBar(
          xp: state.xp,
          streakCount: state.streakCount,
          streakMultiplier: state.streakMultiplier,
          xpFlash: _xpFlash,
          onTap: () =>
              context.read<FlowCubit>().setScreen(AppScreen.cookingLevel),
          onStreakTap: () =>
              context.read<AppStateCubit>().setShowStreakSheet(true),
        ),
      ),
    );

    return Stack(fit: StackFit.expand, children: overlay);
  }
}

class _DragIndicators extends StatelessWidget {
  const _DragIndicators({required this.dragY});

  final double dragY;

  @override
  Widget build(BuildContext context) {
    if (dragY > 20) {
      return IgnorePointer(
        child: Column(
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.saveGreen.withValues(
                      alpha: (dragY / 120).clamp(0.0, 0.5),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }
    if (dragY < -20) {
      return IgnorePointer(
        child: Column(
          children: [
            const Spacer(),
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(
                      alpha: (dragY.abs() / 1000).clamp(0.0, 0.08),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SwipeResultPill extends StatelessWidget {
  const _SwipeResultPill({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final saved = result == 'saved';
    return FadeInOut(
      duration: const Duration(milliseconds: 1200),
      child: PopIn(
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: BoxDecoration(
            color: saved
                ? AppColors.coral.withValues(alpha: 0.53)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: saved
                  ? AppColors.coral
                  : Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                saved ? Icons.favorite_rounded : Icons.close_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                saved ? 'SAVED' : 'PASS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperFavBurst extends StatelessWidget {
  const _SuperFavBurst();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeInOut(
        duration: const Duration(milliseconds: 1200),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const Text(
                  '⭐',
                  style: TextStyle(
                    fontSize: 72,
                    shadows: [Shadow(color: Color(0x80FFD700), blurRadius: 20)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LikeBurst extends StatelessWidget {
  const _LikeBurst();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeInOut(
        duration: const Duration(milliseconds: 500),
        child: ColoredBox(
          color: AppColors.coral.withValues(alpha: 0.12),
          child: Center(
            child: PopIn(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.favorite_rounded,
                size: 80,
                color: AppColors.coral,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassBurst extends StatelessWidget {
  const _PassBurst();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeInOut(
        duration: const Duration(milliseconds: 450),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.15),
          child: Center(
            child: PopIn(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.close_rounded,
                size: 60,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UndoToast extends StatelessWidget {
  const _UndoToast({
    required this.undo,
    required this.isPremium,
    required this.onUndo,
    required this.onDismiss,
  });

  final ({String title, String emoji, int index}) undo;
  final bool isPremium;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SlideUp(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xF2141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(undo.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passed ${undo.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap undo to bring it back',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onUndo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPremium
                      ? AppColors.cyan.withValues(alpha: 0.13)
                      : AppColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  isPremium ? '↩️ Undo' : '🔒 Undo',
                  style: TextStyle(
                    color: isPremium ? AppColors.cyan : AppColors.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleNudge extends StatefulWidget {
  const _IdleNudge();

  @override
  State<_IdleNudge> createState() => _IdleNudgeState();
}

class _IdleNudgeState extends State<_IdleNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween(
    begin: 0.0,
    end: 0.5,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 14,
                color: AppColors.saveGreen,
                shadows: [
                  Shadow(
                    color: AppColors.saveGreen.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ServicePicker extends StatelessWidget {
  const _ServicePicker({required this.onClose, required this.onPick});

  final VoidCallback onClose;
  final ValueChanged<String> onPick;

  static const _services = [
    ('Instacart', '🛒', 'Delivery in as fast as 1 hour', Color(0xFF66BB6A)),
    ('Amazon Fresh', '📦', 'Free delivery with Prime', Color(0xFFFF9900)),
    ('Walmart', '🔵', 'Everyday low prices', Color(0xFF0071CE)),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        child: GestureDetector(
          onTap: () {},
          child: SlideUp(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Order Ingredients',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a delivery service',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < _services.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ZoomIn(
                        duration: Duration(milliseconds: 300 + i * 80),
                        child: GestureDetector(
                          onTap: () => onPick(_services[i].$1),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _services[i].$4.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _services[i].$4.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _services[i].$4.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _services[i].$4.withValues(
                                        alpha: 0.13,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _services[i].$2,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _services[i].$1,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _services[i].$3,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: _services[i].$4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: ColoredBox(
        color: AppColors.bgDark,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 80, 24, 120),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Shimmer(
                baseColor: Colors.white.withValues(alpha: 0.02),
                highlightColor: Colors.white.withValues(alpha: 0.04),
                duration: const Duration(milliseconds: 1500),
                child: Container(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.4,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.75,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: MediaQuery.sizeOf(context).width * 0.55,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
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
