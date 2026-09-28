import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A single cooking instruction, optionally with a countdown timer.
@immutable
class GenieStep {
  const GenieStep({required this.text, this.timed = false, this.seconds = 0});

  final String text;
  final bool timed;
  final int seconds;
}

/// A dish in the synchronized meal-timing plan.
@immutable
class GenieDish {
  const GenieDish({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.prepMin,
    required this.cookMin,
    required this.color,
    required this.ingredients,
    required this.steps,
  });

  final int id;
  final String name;
  final String emoji;
  final String type;
  final int prepMin;
  final int cookMin;
  final Color color;
  final List<String> ingredients;
  final List<GenieStep> steps;

  int get totalMin => prepMin + cookMin;
}

/// A dish placed on the shared timeline — carries its computed start offset
/// (minutes before serve time) and clock string.
@immutable
class GenieTimelineEntry {
  const GenieTimelineEntry({
    required this.dish,
    required this.startOffset,
    required this.startClock,
  });

  final GenieDish dish;

  /// Minutes after the cooking-session start time that this dish begins.
  final int startOffset;
  final String startClock;
}

enum GenieDishStatus { waiting, prepping, cooking, done }

enum GenieMealViewMode { timeline, step }

/// A single (dish, step) pair flattened across the whole timeline — powers
/// the step-by-step walkthrough's progress dots and linear navigation.
@immutable
class GenieFlatStep {
  const GenieFlatStep({
    required this.dish,
    required this.timelineIndex,
    required this.stepIndex,
  });

  final GenieDish dish;
  final int timelineIndex;
  final int stepIndex;

  GenieStep get step => dish.steps[stepIndex];
  bool get isFirstInDish => stepIndex == 0;
  bool get isLastInDish => stepIndex == dish.steps.length - 1;
}

/// Flattens a timeline into an ordered (dish, step) sequence.
List<GenieFlatStep> buildFlatSteps(List<GenieTimelineEntry> timeline) {
  final flat = <GenieFlatStep>[];
  for (var ti = 0; ti < timeline.length; ti++) {
    final dish = timeline[ti].dish;
    for (var si = 0; si < dish.steps.length; si++) {
      flat.add(GenieFlatStep(dish: dish, timelineIndex: ti, stepIndex: si));
    }
  }
  return flat;
}

/// Canned "Genie-planned" cooking session — there is no real timing/AI
/// backend, so this mirrors the prototype's hardcoded 4-dish demo meal
/// (Korean night: fried chicken, kimchi rice, cucumber salad, soju cooler).
abstract final class GeniePlannerData {
  GeniePlannerData._();

  static const List<String> serveTimeOptions = [
    '6:00 PM',
    '6:30 PM',
    '7:00 PM',
    '7:30 PM',
    '8:00 PM',
  ];

  static final List<GenieDish> demoDishes = [
    GenieDish(
      id: 1,
      name: 'Gochujang Fried Chicken',
      emoji: '🍗',
      type: 'Entree',
      prepMin: 15,
      cookMin: 25,
      color: AppColors.coral,
      ingredients: const [
        '2 lbs chicken thighs',
        '3 tbsp gochujang',
        '2 tbsp soy sauce',
        '1 tbsp sesame oil',
        '3 cloves garlic',
        '1 tbsp ginger',
        '2 tbsp honey',
        '1 cup cornstarch',
        'Oil for frying',
        'Sesame seeds',
        'Scallions',
      ],
      steps: const [
        GenieStep(
          text:
              'Mix gochujang glaze: soy sauce, sesame oil, garlic, ginger, '
              'honey',
        ),
        GenieStep(text: 'Pat chicken dry, coat in cornstarch'),
        GenieStep(text: 'Heat oil to 350°F', timed: true, seconds: 180),
        GenieStep(
          text: 'Fry chicken 6-8 min per side until golden',
          timed: true,
          seconds: 420,
        ),
        GenieStep(text: 'Toss in glaze, garnish with sesame seeds & scallions'),
      ],
    ),
    GenieDish(
      id: 2,
      name: 'Kimchi Fried Rice',
      emoji: '🍚',
      type: 'Side',
      prepMin: 10,
      cookMin: 12,
      color: AppColors.amber,
      ingredients: const [
        '1 cup kimchi',
        '3 cups cooked rice',
        '2 eggs',
        '1 tbsp sesame oil',
        '2 tbsp soy sauce',
        '1 tsp gochugaru',
        'Scallions',
      ],
      steps: const [
        GenieStep(text: 'Dice kimchi, prepare rice, crack eggs'),
        GenieStep(
          text: 'Stir-fry kimchi in sesame oil 2 min',
          timed: true,
          seconds: 120,
        ),
        GenieStep(
          text: 'Add rice, soy sauce, gochugaru — cook 5 min',
          timed: true,
          seconds: 300,
        ),
        GenieStep(text: 'Top with fried egg and scallions'),
      ],
    ),
    GenieDish(
      id: 3,
      name: 'Sesame Cucumber Salad',
      emoji: '🥒',
      type: 'Side',
      prepMin: 8,
      cookMin: 0,
      color: AppColors.saveGreen,
      ingredients: const [
        '3 Persian cucumbers',
        '2 tbsp rice vinegar',
        '1 tbsp sesame oil',
        '1 tsp soy sauce',
        '½ tsp chili flakes',
        'Sesame seeds',
      ],
      steps: const [
        GenieStep(text: 'Smash cucumbers, slice into bite pieces'),
        GenieStep(
          text: 'Mix rice vinegar, sesame oil, soy sauce, chili flakes',
        ),
        GenieStep(text: 'Toss cucumbers in dressing, top with sesame seeds'),
      ],
    ),
    GenieDish(
      id: 4,
      name: 'Soju Watermelon Cooler',
      emoji: '🍉',
      type: 'Drink',
      prepMin: 5,
      cookMin: 0,
      color: AppColors.drinksBlue,
      ingredients: const [
        '2 cups watermelon chunks',
        '3 oz soju',
        '1 lime (juiced)',
        'Ice',
        'Fresh mint',
      ],
      steps: const [
        GenieStep(text: 'Blend watermelon chunks until smooth'),
        GenieStep(text: 'Mix with soju, lime juice, ice'),
        GenieStep(text: 'Garnish with mint and watermelon wedge'),
      ],
    ),
  ];

  /// Parses a "h:mm AM/PM" string into minutes-from-midnight.
  static int parseTime(String t) {
    final parts = t.split(' ');
    final hm = parts[0].split(':');
    var h = int.parse(hm[0]);
    final m = int.parse(hm[1]);
    final ampm = parts.length > 1 ? parts[1] : 'PM';
    if (ampm == 'PM' && h != 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    return h * 60 + m;
  }

  /// Formats minutes-from-midnight as "h:mm AM/PM".
  static String formatClock(int totalMins) {
    final normalized = ((totalMins % 1440) + 1440) % 1440;
    var h = (normalized ~/ 60) % 12;
    if (h == 0) h = 12;
    final m = normalized % 60;
    final ampm = normalized >= 720 ? 'PM' : 'AM';
    return '$h:${m.toString().padLeft(2, '0')} $ampm';
  }

  /// Builds the shared cook timeline: dishes sorted by how early they must
  /// start so everything finishes together at [serveTime].
  static List<GenieTimelineEntry> buildTimeline(
    List<GenieDish> dishes,
    String serveTime,
  ) {
    final maxTotal = dishes
        .map((d) => d.totalMin)
        .reduce((a, b) => a > b ? a : b);
    final serveMinutes = parseTime(serveTime);
    final startMinutes = serveMinutes - maxTotal;
    final entries =
        dishes
            .map(
              (d) => GenieTimelineEntry(
                dish: d,
                startOffset: maxTotal - d.totalMin,
                startClock: formatClock(startMinutes + (maxTotal - d.totalMin)),
              ),
            )
            .toList()
          ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    return entries;
  }

  static int maxTotalMinutes(List<GenieDish> dishes) =>
      dishes.map((d) => d.totalMin).reduce((a, b) => a > b ? a : b);
}
