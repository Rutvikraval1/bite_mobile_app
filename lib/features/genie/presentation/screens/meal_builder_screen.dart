import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../content/domain/entities/meal_plan.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../../home/presentation/widgets/meal_planner_sheet.dart'
    show biteDayKey;

/// The weekly meal planner — a 7-day strip with breakfast/lunch/dinner/
/// dessert/snack slots, backed by the real `meal_plans` table via
/// [ContentCubit]. Ports `MealBuilderScreen` from `screens-genie.jsx`.
class MealBuilderScreen extends StatefulWidget {
  const MealBuilderScreen({super.key});

  @override
  State<MealBuilderScreen> createState() => _MealBuilderScreenState();
}

class _MealBuilderScreenState extends State<MealBuilderScreen> {
  int _viewDay = 0;

  static const List<({String id, String icon, String label, String time})>
  _mealTypes = [
    (id: 'breakfast', icon: '🌅', label: 'Breakfast', time: 'Morning'),
    (id: 'lunch', icon: '☀️', label: 'Lunch', time: 'Midday'),
    (id: 'dinner', icon: '🌙', label: 'Dinner', time: 'Evening'),
    (id: 'dessert', icon: '🍰', label: 'Dessert', time: 'Sweet'),
    (id: 'snack', icon: '🍿', label: 'Snack', time: 'Anytime'),
  ];

  DateTime _dateFor(int offset) => DateTime.now().add(Duration(days: offset));

  String _dayLabel(int offset) {
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Tmrw';
    return DateFormat('EEE').format(_dateFor(offset));
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: BlocBuilder<ContentCubit, ContentState>(
          builder: (context, content) {
            final calendar = content.mealPlans;
            final dayKey = biteDayKey(_dateFor(_viewDay));
            final dayData =
                calendar[dayKey] ?? const <String, List<MealPlan>>{};
            final totalMeals = dayData.values.fold<int>(
              0,
              (sum, list) => sum + list.length,
            );

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '📅 Meal Planner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          '⭐ Premium',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _navButton(
                            Icons.arrow_back_ios_new,
                            () => setState(() => _viewDay -= 7),
                          ),
                          Expanded(
                            child: Text(
                              '${DateFormat('MMM d').format(_dateFor(_viewDay))} '
                              '— ${DateFormat('MMM d').format(_dateFor(_viewDay + 6))}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _navButton(
                            Icons.arrow_forward_ios,
                            () => setState(() => _viewDay += 7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: _DayCell(
                                offset: _viewDay + i,
                                selected: i == 0,
                                calendar: calendar,
                                label: _dayLabel(_viewDay + i),
                                date: _dateFor(_viewDay + i),
                                onTap: () =>
                                    setState(() => _viewDay = _viewDay + i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dayLabel(_viewDay),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        totalMeals > 0
                            ? '$totalMeals meal${totalMeals > 1 ? 's' : ''} planned'
                            : 'No meals yet',
                        style: TextStyle(
                          color: totalMeals > 0
                              ? AppColors.saveGreen
                              : AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (var mi = 0; mi < _mealTypes.length; mi++)
                        ZoomIn(
                          duration: Duration(milliseconds: 180 + mi * 40),
                          child: _MealTypeSection(
                            meal: _mealTypes[mi],
                            items: dayData[_mealTypes[mi].id] ?? const [],
                            onRemove: (plan) => context
                                .read<ContentCubit>()
                                .removeMealPlan(plan.id),
                          ),
                        ),
                    ],
                  ),
                ),
                if (totalMeals > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final app = context.read<AppStateCubit>();
                          // Mirrors the JS `setMealItems(todayItems...)` —
                          // replaces the tray with today's plan rather than
                          // appending onto whatever was in it before.
                          app.clearMealItems();
                          for (final list in dayData.values) {
                            for (final item in list) {
                              app.addMealItem(
                                MealItem(
                                  title: item.title,
                                  emoji: item.emoji,
                                  type: 'food',
                                  color: item.color,
                                ),
                              );
                            }
                          }
                          flow.setScreen(AppScreen.geniePlanner);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          shadowColor: AppColors.coral.withValues(alpha: 0.3),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          '⏱ Cook ${_dayLabel(_viewDay)}\'s Meals',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.07),
                      ),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: '💡 '),
                          TextSpan(
                            text: 'Tip: ',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Swipe through recipes and tap "Add to '
                                'Meal" to plan your week. The Genie times '
                                'everything so it all lands on the table '
                                'together.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: 12, color: AppColors.muted),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.offset,
    required this.selected,
    required this.calendar,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final int offset;
  final bool selected;
  final MealCalendar calendar;
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final key = biteDayKey(date);
    final slots = calendar[key];
    final count = slots?.values.fold<int>(0, (sum, l) => sum + l.length) ?? 0;
    final isToday = offset == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.amber.withValues(alpha: 0.13)
                : isToday
                ? AppColors.cyan.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.amber.withValues(alpha: 0.33)
                  : isToday
                  ? AppColors.cyan.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label.length > 3 ? label.substring(0, 3) : label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.amber
                      : isToday
                      ? AppColors.cyan
                      : AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var j = 0; j < (count > 3 ? 3 : count); j++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.saveGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MealTypeSection extends StatelessWidget {
  const _MealTypeSection({
    required this.meal,
    required this.items,
    required this.onRemove,
  });

  final ({String id, String icon, String label, String time}) meal;
  final List<MealPlan> items;
  final ValueChanged<MealPlan> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
            child: Row(
              children: [
                Text(meal.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  meal.time,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (items.isNotEmpty)
            for (final item in items)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(
                          item.color ?? 0xFFFF6B6B,
                        ).withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Color(
                            item.color ?? 0xFFFF6B6B,
                          ).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onRemove(item),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              )
          else
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                'No ${meal.label.toLowerCase()} — swipe to add',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
