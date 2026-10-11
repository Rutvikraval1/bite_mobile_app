import '../data/cook_data.dart';

/// What Cook Mode should walk through — handed over by Recipe Detail right
/// before it opens Cook Mode (screens take no constructor arguments, same
/// reason [CookSession] exists).
class CookPlan {
  CookPlan._();

  static final CookPlan instance = CookPlan._();

  /// The recipe's own steps, as written by its author. Empty means the
  /// recipe has no steps yet and Cook Mode shows an empty state.
  List<String> steps = const [];

  /// Ingredient lines for the main dish, already scaled to the servings the
  /// user picked.
  List<String> ingredients = const [];

  /// Indices into [ingredients] the user already ticked off on Recipe Detail.
  Set<int> checkedIngredients = const {};

  /// Sides added on Recipe Detail (ingredients only — sides have no steps).
  List<SideDish> sides = const [];

  /// Target total time used for the pace bar.
  int targetMinutes = 25;

  void reset() {
    steps = const [];
    ingredients = const [];
    checkedIngredients = const {};
    sides = const [];
    targetMinutes = 25;
  }

  /// Turns free-text author steps into Cook Mode steps: each sentence
  /// becomes a checklist task, and a duration in the text ("simmer for
  /// 10 minutes") becomes the step timer.
  static List<CookStepDef> toCookSteps(List<String> steps) {
    final written = [
      for (final s in steps)
        if (s.trim().isNotEmpty) s.trim(),
    ];
    return [
      for (var i = 0; i < written.length; i++)
        CookStepDef(
          'Step ${i + 1}',
          timerSecs: timerSecsIn(written[i]),
          tasks: _sentences(written[i]),
        ),
    ];
  }

  /// Plain step list for Recipe Detail, with a timer chip when the text
  /// mentions a duration.
  static List<CookStepDef> toDetailSteps(List<String> steps) => [
    for (final s in steps)
      if (s.trim().isNotEmpty)
        CookStepDef(
          s.trim(),
          timerLabel: switch (timerSecsIn(s)) {
            final secs? => CookData.fmtTime(secs),
            null => null,
          },
        ),
  ];

  static final RegExp _duration = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:-|–|to)?\s*(\d+(?:\.\d+)?)?\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b',
    caseSensitive: false,
  );

  /// First duration mentioned in [text], in seconds (upper bound of a
  /// range like "6-8 min"); null when there is none.
  static int? timerSecsIn(String text) {
    final m = _duration.firstMatch(text);
    if (m == null) return null;
    final n = double.tryParse(m.group(2) ?? m.group(1)!);
    if (n == null || n <= 0) return null;
    final unit = m.group(3)!.toLowerCase();
    final mult = unit.startsWith('h')
        ? 3600
        : unit.startsWith('m')
        ? 60
        : 1;
    final secs = (n * mult).round();
    return secs > 0 && secs <= 24 * 3600 ? secs : null;
  }

  static List<String> _sentences(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? [text.trim()] : parts;
  }
}
