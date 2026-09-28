import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/scrollable_tabs.dart';
import '../../data/genie_meal_pairings_data.dart';

/// Curated "entree + side + drink" meal pairings. Ports `GenieMealsScreen`
/// from `screens-genie.jsx`. Pairings are canned (see repo constraints —
/// no real pairing/AI backend), mirroring the prototype's hardcoded demo
/// set exactly.
class GenieMealsScreen extends StatefulWidget {
  const GenieMealsScreen({super.key});

  @override
  State<GenieMealsScreen> createState() => _GenieMealsScreenState();
}

class _GenieMealsScreenState extends State<GenieMealsScreen> {
  int _selectedMeal = 0;
  bool _gridView = false;

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final meal = GenieMealPairingsData.pairings[_selectedMeal];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: flow.goBack,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          '🍽 Meal Pairings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Complete meals curated by Genie',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ViewModeButton(
                        label: '📋 Stack View',
                        active: !_gridView,
                        onTap: () => setState(() => _gridView = false),
                      ),
                    ),
                    Expanded(
                      child: _ViewModeButton(
                        label: '🔲 Grid View',
                        active: _gridView,
                        onTap: () => setState(() => _gridView = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ScrollableTabs(
              leftPad: 16,
              rightPad: 16,
              children: [
                for (var i = 0; i < GenieMealPairingsData.pairings.length; i++)
                  _MealPill(
                    label: GenieMealPairingsData.pairings[i].name,
                    selected: _selectedMeal == i,
                    onTap: () => setState(() => _selectedMeal = i),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x0F4CAF50),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x264CAF50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.saveGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13),
                              children: [
                                const TextSpan(
                                  text: 'Vibe: ',
                                  style: TextStyle(
                                    color: AppColors.saveGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: meal.vibe,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_gridView)
                    Column(
                      children: [
                        _MealCard(
                          item: meal.entree,
                          label: 'Entree',
                          icon: '🍳',
                        ),
                        _divider('PAIRS WITH'),
                        _MealCard(item: meal.side, label: 'Side', icon: '🥗'),
                        _divider('WASH IT DOWN'),
                        _MealCard(item: meal.drink, label: 'Drink', icon: '🍸'),
                        const SizedBox(height: 20),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _GridMealCard(
                              item: meal.entree,
                              label: 'Entree',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _GridMealCard(
                              item: meal.side,
                              label: 'Side',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _GridMealCard(
                              item: meal.drink,
                              label: 'Drink',
                            ),
                          ),
                        ],
                      ),
                    ),
                  Glass(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statTile('${meal.totalMinutes} min', 'Total time'),
                        _vDivider(),
                        _statTile('3', 'Recipes'),
                        _vDivider(),
                        _statTile('Serves 4', 'People'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => flow.setScreen(AppScreen.geniePlanner),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saveGreen,
                        shadowColor: AppColors.saveGreen.withValues(alpha: 0.3),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: const Text(
                        '⏱ Cook This Meal — Time It 🍽',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => ToastService.instance.show(
                              '🔖 Meal saved to collection!',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x4D4CAF50)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              backgroundColor: const Color(0x0F4CAF50),
                            ),
                            child: const Text(
                              '🔖 Save Meal',
                              style: TextStyle(
                                color: AppColors.saveGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedMeal =
                                    (_selectedMeal + 1) %
                                    GenieMealPairingsData.pairings.length;
                              });
                              ToastService.instance.show(
                                '🔀 New meal pairing!',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Text(
                              '🔀 Shuffle',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Genie pairs meals based on cuisine, flavor profiles, '
                    'and prep time',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, color: Colors.white.withValues(alpha: 0.06));
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.saveGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _MealPill extends StatelessWidget {
  const _MealPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.saveGreen
              : Colors.white.withValues(alpha: 0.06),
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

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.item,
    required this.label,
    required this.icon,
  });

  final GenieMealComponent item;
  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.27),
                  item.color.withValues(alpha: 0.07),
                ],
              ),
            ),
            child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(icon, style: const TextStyle(fontSize: 10)),
                  ],
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.creator} · ${item.time}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _GridMealCard extends StatelessWidget {
  const _GridMealCard({required this.item, required this.label});

  final GenieMealComponent item;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  item.color.withValues(alpha: 0.27),
                  item.color.withValues(alpha: 0.07),
                ],
              ),
            ),
            child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
