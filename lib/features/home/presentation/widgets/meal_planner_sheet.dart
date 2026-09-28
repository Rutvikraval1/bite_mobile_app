import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../content/domain/entities/meal_plan.dart';

/// Day info helper shared by planner sheets.
String biteDayKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Meal-planner bottom sheet — ports the `mealPlannerSheet` overlay from
/// `SwipeDeckScreen`.
class MealPlannerBottomSheet extends StatefulWidget {
  const MealPlannerBottomSheet({
    super.key,
    required this.sheet,
    required this.mealCalendar,
    required this.onAdd,
    required this.onClose,
  });

  final MealPlannerSheet sheet;
  final MealCalendar mealCalendar;
  final Future<void> Function(String dayKey, String mealSlot) onAdd;
  final VoidCallback onClose;

  @override
  State<MealPlannerBottomSheet> createState() => _MealPlannerSheetState();
}

class _MealPlannerSheetState extends State<MealPlannerBottomSheet> {
  int _selectedDay = 0;

  static const List<({String id, String icon, String label, String time})>
      _mealTypes = [
    (id: 'breakfast', icon: '🌅', label: 'Breakfast', time: '7–9 AM'),
    (id: 'lunch', icon: '☀️', label: 'Lunch', time: '12–1 PM'),
    (id: 'dinner', icon: '🌙', label: 'Dinner', time: '6–8 PM'),
    (id: 'dessert', icon: '🍰', label: 'Dessert', time: 'After dinner'),
    (id: 'snack', icon: '🍿', label: 'Snack', time: 'Anytime'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withValues(alpha: 0.8),
          dismissible: false,
        ),
        Align(
        alignment: Alignment.bottomCenter,
        child: SlideUp(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0x14FFFFFF)),
                left: BorderSide(color: Color(0x14FFFFFF)),
                right: BorderSide(color: Color(0x14FFFFFF)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x66F5A623),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(widget.sheet.emoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.sheet.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Add to your meal plan',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PICK A DAY',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DaySelector(
                    selected: _selectedDay,
                    onSelect: (i) => setState(() => _selectedDay = i),
                    calendar: widget.mealCalendar,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MEAL TYPE',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: [
                        for (var i = 0; i < _mealTypes.length; i++)
                          _MealTypeRow(
                            index: i,
                            meal: _mealTypes[i],
                            existing: _existingFor(_mealTypes[i].id),
                            onTap: () => _select(_mealTypes[i]),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  List<String> _existingFor(String slot) {
    final date = DateTime.now().add(Duration(days: _selectedDay));
    return widget.mealCalendar[biteDayKey(date)]?[slot]
            ?.map((m) => m.emoji)
            .toList() ??
        [];
  }

  Future<void> _select(({String id, String icon, String label, String time}) meal) async {
    final date = DateTime.now().add(Duration(days: _selectedDay));
    await widget.onAdd(biteDayKey(date), meal.id);
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selected,
    required this.onSelect,
    required this.calendar,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final MealCalendar calendar;

  static const List<String> _dayNames = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayCell(
              index: i,
              selected: selected == i,
              onTap: () => onSelect(i),
              calendar: calendar,
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.calendar,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;
  final MealCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now().add(Duration(days: index));
    final dayName = index == 0
        ? 'Today'
        : index == 1
            ? 'Tmrw'
            : _DaySelector._dayNames[date.weekday % 7];
    final hasMeals = calendar[biteDayKey(date)]
            ?.values
            .any((list) => list.isNotEmpty) ??
        false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ZoomIn(
        duration: Duration(milliseconds: 200 + index * 30),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.amber.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.amber.withValues(alpha: 0.33)
                    : Colors.white.withValues(alpha: 0.06),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.amber
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                if (hasMeals) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealTypeRow extends StatelessWidget {
  const _MealTypeRow({
    required this.index,
    required this.meal,
    required this.existing,
    required this.onTap,
  });

  final int index;
  final ({String id, String icon, String label, String time}) meal;
  final List<String> existing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ZoomIn(
        duration: Duration(milliseconds: 200 + index * 40),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Text(meal.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        meal.time,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (existing.isNotEmpty)
                  Row(
                    children: [
                      for (final e in existing)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(e, style: const TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
