import 'package:flutter/foundation.dart';

/// A meal planned for a specific date + slot — mirrors `meal_plans` rows.
@immutable
class MealPlan {
  const MealPlan({
    required this.id,
    required this.planDate,
    required this.mealSlot,
    required this.title,
    required this.emoji,
    this.color,
  });

  final String id;
  final String planDate; // yyyy-mm-dd
  final String mealSlot; // breakfast | lunch | dinner | snack
  final String title;
  final String emoji;
  final int? color;

  factory MealPlan.fromRow(Map<String, dynamic> row) {
    return MealPlan(
      id: (row['id'] as String?) ?? '',
      planDate: (row['plan_date'] as String?) ?? '',
      mealSlot: (row['meal_slot'] as String?) ?? '',
      title: (row['title'] as String?) ?? '',
      emoji: (row['emoji'] as String?) ?? '🍽',
      color: (row['color'] as int?) ?? 0xFFFF6B6B,
    );
  }
}

/// Calendar-shaped meal plan map: `{ date: { slot: [MealPlan...] } }`.
typedef MealCalendar = Map<String, Map<String, List<MealPlan>>>;

/// Total number of planned meals across the whole calendar.
int mealPlanCount(MealCalendar calendar) {
  var count = 0;
  for (final slots in calendar.values) {
    for (final items in slots.values) {
      count += items.length;
    }
  }
  return count;
}
