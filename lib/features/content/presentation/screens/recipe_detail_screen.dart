import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../cooking/data/cook_data.dart';
import '../../../cooking/domain/cook_session.dart';
import '../../domain/entities/bite_card.dart';
import '../blocs/content_cubit.dart';
import '../widgets/social_comments_block.dart';

/// Recipe / drink detail sheet — ports `RecipeDetailScreen` from
/// `screens-detail.jsx`. Reached from the swipe deck for non-place cards.
class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  String _activeTab = 'ingredients';
  bool _liked = false;
  bool _saved = false;
  int? _servings;
  final Set<int> _checkedIngs = {};
  final Set<int> _completedSteps = {};
  final Set<String> _checkedSideIngs = {};
  final List<SideDish> _addedSides = [];
  String _sidesTab = 'picks';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateCubit>().state;
    final content = context.watch<ContentCubit>().state;
    final deck = appState.subTab == DeckTab.drinks
        ? content.drinks
        : content.recipes;
    final card = deck.isEmpty
        ? null
        : deck[appState.activeCardIndex % deck.length];

    if (card == null) {
      return ColoredBox(
        color: const Color(0xB3000000),
        child: content.loading
            ? const LoadingState(label: 'Loading recipe…', backgroundColor: Colors.transparent)
            : content.error != null
                ? ErrorState(
                    message: content.error!,
                    backgroundColor: Colors.transparent,
                    onRetry: () => context.read<ContentCubit>().refetch(),
                  )
                : const EmptyState(
                    emoji: '🍽',
                    title: 'No recipe to show',
                    message: 'Check back soon for new recipes.',
                  ),
      );
    }

    final isDrink = appState.subTab == DeckTab.drinks;
    final themeColor = isDrink ? AppColors.drinksBlue : AppColors.coral;
    final baseServings = isDrink
        ? CookData.baseServingsDrink
        : CookData.baseServingsFood;
    _servings ??= baseServings;
    final servings = _servings!;
    final ingredients = isDrink
        ? CookData.drinkIngredients
        : CookData.foodIngredients;
    final steps = isDrink
        ? CookData.drinkDetailSteps
        : CookData.foodDetailSteps;

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().goBack(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.88,
              widthFactor: 1,
              child: GestureDetector(
                onTap:
                    () {}, // absorb taps so they don't fall through to goBack
                child: ZoomIn(
                  duration: const Duration(milliseconds: 380),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: ColoredBox(
                      color: AppColors.bgDark,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            _dragHandle(),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _hero(card, isDrink),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 20),
                                          Text(
                                            card.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _creatorRow(
                                            card,
                                            isDrink,
                                            themeColor,
                                          ),
                                          const SizedBox(height: 16),
                                          _statsRow(card, isDrink),
                                          const SizedBox(height: 8),
                                          SocialCommentsBlock(
                                            hearts: card.hearts,
                                            saved: card.saved,
                                            accentColor: themeColor,
                                            baseCommentCount: 4,
                                            quickChips: const [
                                              '🔥 Fire!',
                                              '😍 Love this!',
                                              'Need recipe!',
                                              '💯 Amazing',
                                              'Saving this',
                                            ],
                                            seedComments: const [
                                              SeedComment(
                                                user: '@noodlequeen',
                                                avatarEmoji: '🍜',
                                                text:
                                                    'This looks incredible! 🔥',
                                                time: '2m',
                                                likes: 12,
                                              ),
                                              SeedComment(
                                                user: '@marco.eats',
                                                avatarEmoji: '🍄',
                                                text: 'Need the recipe ASAP!',
                                                time: '8m',
                                                likes: 5,
                                              ),
                                              SeedComment(
                                                user: '@sarah_bakes',
                                                avatarEmoji: '🍰',
                                                text:
                                                    'The plating is gorgeous 😍',
                                                time: '15m',
                                                likes: 8,
                                              ),
                                              SeedComment(
                                                user: '@bangkokbites',
                                                avatarEmoji: '🍗',
                                                text:
                                                    "Reminds me of my grandma's version",
                                                time: '1h',
                                                likes: 3,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          _actionRow(
                                            card,
                                            isDrink,
                                            themeColor,
                                            ingredients,
                                          ),
                                          const SizedBox(height: 12),
                                          _addSidesButton(themeColor),
                                          if (_addedSides.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            _addedSidesPills(),
                                          ],
                                          const SizedBox(height: 16),
                                          _tabToggle(themeColor, isDrink),
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: _activeTab == 'ingredients'
                                          ? _ingredientsTab(
                                              card,
                                              isDrink,
                                              themeColor,
                                              ingredients,
                                              baseServings,
                                              servings,
                                            )
                                          : _stepsTab(
                                              card,
                                              isDrink,
                                              themeColor,
                                              steps,
                                              ingredients,
                                            ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header pieces ──

  Widget _dragHandle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().goBack(),
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _hero(BiteCard card, bool isDrink) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: EmojiThemes.cardBg(card.emoji),
              ),
            ),
            alignment: Alignment.center,
            child: (card.image == null || card.image!.isEmpty)
                ? Text(
                    card.emoji.isEmpty ? '🍽' : card.emoji,
                    style: const TextStyle(fontSize: 80),
                  )
                : null,
          ),
          if (card.image != null && card.image!.isNotEmpty)
            Image.network(
              card.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Positioned(
            top: 12,
            right: 16,
            child: GestureDetector(
              onTap: () => context.read<FlowCubit>().goBack(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creatorRow(BiteCard card, bool isDrink, Color themeColor) {
    return GestureDetector(
      onTap: () =>
          context.read<FlowCubit>().setScreen(AppScreen.creatorProfile),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  themeColor,
                  isDrink ? AppColors.cyan : AppColors.amber,
                ],
              ),
            ),
            child: const Text('👩‍🍳', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(
            card.creator,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BiteCard card, bool isDrink) {
    const peppers = ['🫑', '🟡', '🟠', '🍊', '🌶'];
    final heatStr = peppers.take(card.heat).join();
    final text =
        '${card.time} · ${isDrink ? '🍸' : '🔥'} ${card.diff} · ${isDrink ? '🥃 Yields ${card.serves}' : '🍽 Serves ${card.serves}'}${heatStr.isNotEmpty ? ' · $heatStr' : ''}';
    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Action row ──

  Widget _actionRow(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookIngredient> ingredients,
  ) {
    return Row(
      children: [
        _circleToggle(
          icon: Icons.favorite_rounded,
          active: _liked,
          color: AppColors.coral,
          onTap: () => setState(() => _liked = !_liked),
        ),
        const SizedBox(width: 10),
        _circleToggle(
          icon: Icons.bookmark_rounded,
          active: _saved,
          color: AppColors.amber,
          onTap: () {
            setState(() => _saved = !_saved);
            if (_saved) {
              context.read<ContentCubit>().saveItem(
                card,
                isDrink ? 'drink' : 'recipe',
              );
            }
          },
        ),
        const SizedBox(width: 10),
        _circleToggle(
          icon: Icons.ios_share_rounded,
          active: false,
          color: Colors.white,
          onTap: () =>
              context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _attemptCook(card, isDrink, themeColor, ingredients),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: LinearGradient(
                  colors: [
                    themeColor,
                    isDrink ? AppColors.cyan : AppColors.amber,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.33),
                    blurRadius: 20,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                isDrink ? '🍸 Mix Now' : '🍳 Cook Now',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleToggle({
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withValues(alpha: 0.13) : AppColors.glass,
          border: Border.all(color: active ? color : AppColors.glassBorder),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _addSidesButton(Color themeColor) {
    final premium = PremiumGateService.instance.isPremium;
    return GestureDetector(
      onTap: () {
        if (premium) {
          _openSidesSheet();
        } else {
          PremiumGateService.instance.show(
            'Add Sides & Pairings',
            'premium',
            'Add up to 3 sides — browse picks, or let Genie AI suggest perfect pairings with drinks and desserts.',
          );
        }
      },
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: premium
              ? AppColors.amber.withValues(alpha: 0.07)
              : const Color(0x0FF5A623),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
        ),
        alignment: Alignment.center,
        child: Text(
          premium
              ? '➕ Add Sides & Pairings (${_addedSides.length}/3)'
              : '🔒 Add Sides & Pairings — Premium',
          style: const TextStyle(
            color: AppColors.amber,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _addedSidesPills() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final side in _addedSides)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: AppColors.amber.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(side.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  side.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _addedSides.remove(side)),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tabToggle(Color themeColor, bool isDrink) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final t in ['ingredients', 'steps'])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == t ? themeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t == 'steps' && isDrink ? 'mixing' : t,
                    style: TextStyle(
                      color: _activeTab == t ? Colors.white : AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Ingredients tab ──

  Widget _ingredientsTab(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookIngredient> ingredients,
    int baseServings,
    int servings,
  ) {
    final unchecked = [
      for (var i = 0; i < ingredients.length; i++)
        if (!_checkedIngs.contains(i)) i,
    ];
    final sideUnchecked = <({SideDish side, int index})>[];
    for (final side in _addedSides) {
      final ings = side.ingredients.isEmpty
          ? const ['Ingredients listed in recipe']
          : side.ingredients;
      for (var i = 0; i < ings.length; i++) {
        if (!_checkedSideIngs.contains('${side.name}-$i')) {
          sideUnchecked.add((side: side, index: i));
        }
      }
    }
    final totalUnchecked = unchecked.length + sideUnchecked.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${ingredients.length} ingredients',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            Row(
              children: [
                Text(
                  isDrink ? 'Yields' : 'Servings',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(width: 10),
                _servingsButton(
                  '−',
                  () => setState(() => _servings = (servings - 1).clamp(1, 99)),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$servings',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                _servingsButton(
                  '+',
                  () => setState(() => _servings = servings + 1),
                ),
              ],
            ),
          ],
        ),
        if (servings != baseServings)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              '📐 Quantities scaled from $baseServings → $servings ${isDrink ? 'yields' : 'servings'}',
              style: TextStyle(
                color: themeColor,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (_checkedIngs.isNotEmpty)
          _readySummary(
            _checkedIngs.length,
            () => setState(_checkedIngs.clear),
          ),
        for (final i in unchecked)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ingredientRow(
              label: CookData.formatIngredient(
                ingredients[i],
                baseServings,
                servings,
              ),
              qtyLabel: ingredients[i].qty > 0
                  ? CookData.scaleQty(
                      ingredients[i].qty,
                      baseServings,
                      servings,
                    )
                  : null,
              themeColor: themeColor,
              onTap: () => setState(() => _checkedIngs.add(i)),
            ),
          ),
        if (_addedSides.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'SIDES',
                style: TextStyle(
                  color: Color(0x59FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final side in _addedSides) _sideIngredientGroup(side),
        ],
        if (totalUnchecked == 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0x144CAF50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x264CAF50)),
            ),
            alignment: Alignment.center,
            child: const Text(
              '✓ All ingredients ready!',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () =>
                  _openOrderPicker(card, isDrink, themeColor, ingredients),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x1A43A047),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x4043A047)),
                ),
                child: Row(
                  children: [
                    const Text('🛒', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order $totalUnchecked ingredient${totalUnchecked > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF66BB6A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _addedSides.isNotEmpty
                                ? 'Main dish + ${_addedSides.length} side${_addedSides.length > 1 ? 's' : ''}'
                                : 'Instacart · Walmart · Amazon',
                            style: const TextStyle(
                              color: Color(0x73FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF66BB6A),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sideIngredientGroup(SideDish side) {
    final ings = side.ingredients.isEmpty
        ? const ['Ingredients listed in recipe']
        : side.ingredients;
    final checkedCount = [
      for (var i = 0; i < ings.length; i++)
        if (_checkedSideIngs.contains('${side.name}-$i')) i,
    ].length;
    final allChecked = checkedCount == ings.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 0, 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: side.color, width: 3)),
            ),
            child: Row(
              children: [
                Text(side.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    side.name,
                    style: TextStyle(
                      color: allChecked
                          ? const Color(0xFF4CAF50)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: allChecked
                        ? const Color(0x264CAF50)
                        : side.color.withValues(alpha: 0.08),
                    border: Border.all(
                      color: allChecked
                          ? const Color(0x4D4CAF50)
                          : side.color.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '$checkedCount/${ings.length}',
                    style: TextStyle(
                      color: allChecked ? const Color(0xFF4CAF50) : side.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (checkedCount > 0 && !allChecked)
            _readySummary(
              checkedCount,
              () => setState(() {
                for (var i = 0; i < ings.length; i++) {
                  _checkedSideIngs.remove('${side.name}-$i');
                }
              }),
            ),
          for (var i = 0; i < ings.length; i++)
            if (!_checkedSideIngs.contains('${side.name}-$i'))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ingredientRow(
                  label: ings[i],
                  emoji: side.emoji,
                  themeColor: side.color,
                  onTap: () =>
                      setState(() => _checkedSideIngs.add('${side.name}-$i')),
                ),
              ),
        ],
      ),
    );
  }

  Widget _readySummary(int count, VoidCallback onReset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0F4CAF50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x264CAF50)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count ingredient${count != 1 ? 's' : ''} ready',
              style: const TextStyle(
                color: Color(0xB34CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onReset,
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0x40FFFFFF), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servingsButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glass,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _ingredientRow({
    required String label,
    required Color themeColor,
    required VoidCallback onTap,
    String? qtyLabel,
    String? emoji,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (emoji != null) ...[
              Opacity(
                opacity: 0.55,
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    if (qtyLabel != null && qtyLabel.isNotEmpty)
                      TextSpan(
                        text: '$qtyLabel ',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    TextSpan(
                      text: label,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Steps tab ──

  Widget _stepsTab(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookStepDef> steps,
    List<CookIngredient> ingredients,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: steps.isEmpty
                      ? 0
                      : _completedSteps.length / steps.length,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(themeColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_completedSteps.length}/${steps.length} steps',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++) _stepRow(i, steps[i]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _attemptCook(card, isDrink, themeColor, ingredients),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: LinearGradient(
                colors: [
                  themeColor,
                  isDrink ? AppColors.cyan : AppColors.amber,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.33),
                  blurRadius: 24,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              isDrink ? '🍸 Enter Mix Mode' : '👨‍🍳 Enter Cook Mode',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Hands-free, step-by-step, screen stays awake',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _stepRow(int i, CookStepDef step) {
    final done = _completedSteps.contains(i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (done) {
                _completedSteps.remove(i);
              } else {
                _completedSteps.add(i);
              }
            }),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.coral
                    : AppColors.coral.withValues(alpha: 0.13),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.text,
                  style: TextStyle(
                    color: done ? AppColors.muted : Colors.white,
                    fontSize: 14,
                    height: 1.6,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (step.timerLabel != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Timer: ${step.timerLabel}',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 12,
                            fontFamily: 'monospace',
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
    );
  }

  // ── Cook flow ──

  void _attemptCook(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookIngredient> ingredients,
  ) {
    final unchecked = [
      for (var i = 0; i < ingredients.length; i++)
        if (!_checkedIngs.contains(i)) i,
    ];
    if (unchecked.isNotEmpty) {
      _showMissingIngredientsDialog(
        card,
        isDrink,
        themeColor,
        ingredients,
        unchecked,
      );
    } else {
      _goToCookMode(card, isDrink);
    }
  }

  void _goToCookMode(BiteCard card, bool isDrink) {
    CookSession.instance
      ..dishTitle = card.title
      ..creator = card.creator
      ..isDrink = isDrink
      ..heat = card.heat;
    context.read<FlowCubit>().setScreen(AppScreen.cookMode);
  }

  void _showMissingIngredientsDialog(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookIngredient> ingredients,
    List<int> unchecked,
  ) {
    final servings =
        _servings ??
        (isDrink ? CookData.baseServingsDrink : CookData.baseServingsFood);
    final baseServings = isDrink
        ? CookData.baseServingsDrink
        : CookData.baseServingsFood;
    final preview = unchecked
        .take(3)
        .map(
          (i) =>
              CookData.formatIngredient(ingredients[i], baseServings, servings),
        )
        .join(', ');
    final more = unchecked.length > 3 ? ' + ${unchecked.length - 3} more' : '';
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => _AlertShell(
        accentColor: AppColors.amber,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDrink ? '🍸' : '🧑‍🍳',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              '${unchecked.length} Missing Ingredient${unchecked.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$preview$more',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _pillButton(
              label: '🛒  Order Ingredients',
              background: const Color(0x2643A047),
              textColor: const Color(0xFF66BB6A),
              onTap: () {
                Navigator.pop(ctx);
                _openOrderPicker(card, isDrink, themeColor, ingredients);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _pillButton(
                    label: 'Go Back',
                    background: Colors.transparent,
                    textColor: AppColors.muted,
                    border: Colors.white.withValues(alpha: 0.12),
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _pillButton(
                    label: isDrink ? 'Mix Anyway 🍸' : 'Cook Anyway 🔥',
                    background: themeColor,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToCookMode(card, isDrink);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReadyToCookDialog(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    int ingredientCount,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => _AlertShell(
        accentColor: const Color(0xFF4CAF50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x1F4CAF50),
                border: Border.all(color: const Color(0x4D4CAF50), width: 2),
              ),
              child: Text(
                isDrink ? '🍸' : '🍳',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isDrink ? 'Ready to Mix?' : 'Ready to Cook?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'All ingredients ordered & checked off',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '✅ $ingredientCount/$ingredientCount ingredients ready',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _pillButton(
                    label: 'Not Yet',
                    background: Colors.transparent,
                    textColor: AppColors.muted,
                    border: Colors.white.withValues(alpha: 0.12),
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _pillButton(
                    label: isDrink ? "Let's Mix! 🍸" : "Let's Cook! 🔥",
                    background: themeColor,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToCookMode(card, isDrink);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required Color background,
    required Color textColor,
    required VoidCallback onTap,
    Color? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(100),
          border: border != null ? Border.all(color: border) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _openOrderPicker(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookIngredient> ingredients,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        const services = [
          (
            key: 'instacart',
            emoji: '🛒',
            name: 'Instacart',
            desc: 'Delivery in as fast as 1 hour',
            color: Color(0xFF66BB6A),
          ),
          (
            key: 'amazonfresh',
            emoji: '📦',
            name: 'Amazon Fresh',
            desc: 'Free delivery with Prime',
            color: Color(0xFFFF9900),
          ),
          (
            key: 'walmart',
            emoji: '🔵',
            name: 'Walmart',
            desc: 'Everyday low prices',
            color: Color(0xFF0071CE),
          ),
        ];
        return _SheetShell(
          title: 'Order Ingredients',
          subtitle: card.title,
          children: [
            for (final svc in services)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _fulfillOrder(
                      card,
                      isDrink,
                      themeColor,
                      ingredients,
                      svc.name,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: svc.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: svc.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: svc.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            svc.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                svc.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                svc.desc,
                                style: const TextStyle(
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
                          color: svc.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _fulfillOrder(
    BiteCard card,
    bool isDrink,
    Color themeColor,
    List<CookIngredient> ingredients,
    String serviceName,
  ) {
    setState(() {
      for (var i = 0; i < ingredients.length; i++) {
        _checkedIngs.add(i);
      }
      for (final side in _addedSides) {
        final ings = side.ingredients.isEmpty
            ? const ['Ingredients listed in recipe']
            : side.ingredients;
        for (var i = 0; i < ings.length; i++) {
          _checkedSideIngs.add('${side.name}-$i');
        }
      }
    });
    ToastService.instance.show('🛒 Ordered via $serviceName!');
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted)
        _showReadyToCookDialog(card, isDrink, themeColor, ingredients.length);
    });
  }

  // ── Sides sheet ──

  void _openSidesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            void toggle(SideDish side) {
              final already = _addedSides.any((s) => s.name == side.name);
              if (already) {
                setState(
                  () => _addedSides.removeWhere((s) => s.name == side.name),
                );
                ToastService.instance.show('✕ ${side.name} removed');
              } else if (_addedSides.length >= 3) {
                ToastService.instance.show('🌶 Max 3 sides per recipe');
              } else {
                setState(() => _addedSides.add(side));
                ToastService.instance.show(
                  '🔥 ${side.name} added to your meal!',
                );
              }
              setSheetState(() {});
            }

            return _SidesSheetBody(
              addedSides: _addedSides,
              activeTab: _sidesTab,
              onTabChanged: (t) => setSheetState(() => _sidesTab = t),
              onToggle: toggle,
              onDone: () {
                Navigator.pop(sheetCtx);
                ToastService.instance.show(
                  '✨ ${_addedSides.length} side${_addedSides.length > 1 ? 's' : ''} added! Ingredients updated.',
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Bottom-sheet content for "Add Sides & Pairings".
class _SidesSheetBody extends StatelessWidget {
  const _SidesSheetBody({
    required this.addedSides,
    required this.activeTab,
    required this.onTabChanged,
    required this.onToggle,
    required this.onDone,
  });

  final List<SideDish> addedSides;
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<SideDish> onToggle;
  final VoidCallback onDone;

  bool _isAdded(SideDish side) => addedSides.any((s) => s.name == side.name);

  @override
  Widget build(BuildContext context) {
    final doneButton = addedSides.isNotEmpty
        ? GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  colors: [AppColors.coral, AppColors.amber],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Done — Cook with ${addedSides.length} Side${addedSides.length > 1 ? 's' : ''} 🍽',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          )
        : null;
    return _SheetShell(
      title: 'Add Sides & Pairings',
      subtitle: '${addedSides.length}/3 added',
      maxHeightFactor: 0.8,
      bottomBar: doneButton,
      headerExtra: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (final tab in const [
              ('picks', 'Picks & Browse'),
              ('genie', '🧞 Genie AI'),
            ])
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(tab.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: activeTab == tab.$1
                          ? AppColors.coral
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tab.$2,
                      style: TextStyle(
                        color: activeTab == tab.$1
                            ? Colors.white
                            : AppColors.muted,
                        fontWeight: activeTab == tab.$1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      children: [
        if (activeTab == 'picks') ...[
          const Text(
            "⭐ Creator's Picks",
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final side in CookData.creatorPicks) _sideTile(side, big: true),
          const SizedBox(height: 6),
          const Text(
            'BROWSE SIDES',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final side in CookData.browseSides) _sideTile(side, big: false),
        ] else ...[
          const Row(
            children: [
              Text('🧞', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Genie AI Pairings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🥗 SIDE DISHES',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final side in CookData.genieSides)
            _sideTile(side, big: false, showMatch: true),
          const SizedBox(height: 14),
          const Text(
            '🍹 DRINKS',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final side in CookData.genieDrinks)
            _sideTile(side, big: false, showMatch: true),
          const SizedBox(height: 14),
          const Text(
            '🍰 DESSERTS',
            style: TextStyle(
              color: AppColors.coral,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final side in CookData.genieDesserts)
            _sideTile(side, big: false, showMatch: true),
        ],
      ],
    );
  }

  Widget _sideTile(SideDish side, {required bool big, bool showMatch = false}) {
    final added = _isAdded(side);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => onToggle(side),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: big ? 14 : 12,
            vertical: big ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: added
                ? const Color(0x1A4CAF50)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(big ? 14 : 12),
            border: Border.all(
              color: added
                  ? const Color(0x734CAF50)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Text(side.emoji, style: TextStyle(fontSize: big ? 22 : 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      side.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: big ? 14 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${side.desc} · ⏱ ${side.time}',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: big ? 11 : 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (showMatch && side.match != null) ...[
                Text(
                  side.match!,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                added ? Icons.check_rounded : Icons.add_rounded,
                size: big ? 18 : 14,
                color: added ? const Color(0xFF4CAF50) : AppColors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared bottom-sheet chrome: drag handle, title/subtitle header, scrollable
/// body, optional sticky bottom bar. Used by both the order picker and the
/// sides sheet.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.children,
    this.subtitle,
    this.headerExtra,
    this.bottomBar,
    this.maxHeightFactor = 0.6,
  });

  final String title;
  final String? subtitle;
  final Widget? headerExtra;
  final List<Widget> children;
  final Widget? bottomBar;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        child: ColoredBox(
          color: AppColors.bgDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ?headerExtra,
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ),
              if (bottomBar != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  child: bottomBar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared centered alert-dialog chrome (missing ingredients / ready to cook).
class _AlertShell extends StatelessWidget {
  const _AlertShell({required this.child, required this.accentColor});

  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: PopIn(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
