import 'package:flutter/foundation.dart';

import '../../content/domain/entities/bite_card.dart';

/// One selectable chip in a Genie filter section. A card matches when it
/// carries any of [tags] (normalized, `#` stripped) or, for time-based
/// chips, when its total time is at most [maxMinutes].
@immutable
class GenieChipOption {
  const GenieChipOption(
    this.label,
    this.emoji, {
    this.tags = const {},
    this.maxMinutes,
  });

  final String label;
  final String emoji;
  final Set<String> tags;
  final int? maxMinutes;

  bool matches(BiteCard card) {
    final limit = maxMinutes;
    if (limit != null) {
      final m = GenieFilters.minutesOf(card);
      if (m != null && m <= limit) return true;
    }
    if (tags.isEmpty) return false;
    return GenieFilters.tagsOf(card).any(tags.contains);
  }
}

/// A chip section — [matchAll] means every selected chip must match
/// (dietary needs), otherwise any one is enough.
@immutable
class GenieFilterSection {
  const GenieFilterSection({
    required this.key,
    required this.title,
    required this.options,
    this.matchAll = false,
  });

  final String key;
  final String title;
  final List<GenieChipOption> options;
  final bool matchAll;

  GenieChipOption? option(String label) {
    for (final o in options) {
      if (o.label == label) return o;
    }
    return null;
  }
}

/// Which deck a filter set applies to. Places have no Genie filters.
enum GenieFilterKind { food, drinks }

/// Static chip catalogs. Cuisine chips are built from the live catalog
/// (see [GenieFilters.cuisinesIn]) so they always match real data.
abstract final class GenieFilterCatalog {
  static const GenieFilterSection foodVibes = GenieFilterSection(
    key: 'vibes',
    title: 'VIBES',
    matchAll: true,
    options: [
      GenieChipOption('Date Night', '🌙', tags: {'datenight', 'fancy'}),
      GenieChipOption('Under 30 Min', '⚡', maxMinutes: 30),
      GenieChipOption(
        'Meal Prep',
        '📦',
        tags: {'mealprep', 'familymeal', 'onepan'},
      ),
      GenieChipOption(
        'Comfort Food',
        '🛋',
        tags: {'comfort', 'cheesy', 'creamy', 'indulgent'},
      ),
      GenieChipOption(
        'Impress Friends',
        '🎉',
        tags: {'fancy', 'datenight', 'viral', 'trending'},
      ),
      GenieChipOption(
        'Healthy',
        '🥗',
        tags: {'healthy', 'lowcarb', 'superfood'},
      ),
    ],
  );

  static const GenieFilterSection foodDietary = GenieFilterSection(
    key: 'dietary',
    title: 'DIETARY',
    matchAll: true,
    options: [
      GenieChipOption('Vegetarian', '🌱', tags: {'vegetarian', 'vegan'}),
      GenieChipOption('Vegan', '🥬', tags: {'vegan'}),
      GenieChipOption('Gluten-Free', '🚫', tags: {'glutenfree'}),
      GenieChipOption('Dairy-Free', '🥛', tags: {'dairyfree', 'vegan'}),
      GenieChipOption('High Protein', '💪', tags: {'highprotein'}),
      GenieChipOption('Low Carb', '🥑', tags: {'lowcarb', 'keto'}),
    ],
  );

  static const GenieFilterSection drinkVibes = GenieFilterSection(
    key: 'vibes',
    title: 'VIBES',
    options: [
      GenieChipOption(
        'Date Night',
        '🌙',
        tags: {'datenight', 'fancy', 'afterdinner'},
      ),
      GenieChipOption('Party', '🎉', tags: {'party', 'viral', 'trending'}),
      GenieChipOption('Brunch', '🥂', tags: {'brunch'}),
      GenieChipOption(
        'Refreshing',
        '🧊',
        tags: {'refreshing', 'summer', 'iced', 'citrus', 'light'},
      ),
      GenieChipOption('Classic', '🎩', tags: {'classic'}),
      GenieChipOption('Sweet', '🍯', tags: {'sweet', 'dessert'}),
    ],
  );

  static const GenieFilterSection drinkType = GenieFilterSection(
    key: 'dietary',
    title: 'TYPE & SPIRIT',
    options: [
      GenieChipOption(
        'Non-Alcoholic',
        '🧃',
        tags: {'nonalcoholic', 'mocktail'},
      ),
      GenieChipOption('Cocktail', '🍸', tags: {'cocktail'}),
      GenieChipOption('Coffee & Tea', '☕', tags: {'coffee', 'matcha', 'tea'}),
      GenieChipOption('Tequila', '🌵', tags: {'tequila', 'mezcal'}),
      GenieChipOption('Gin', '🫒', tags: {'gin'}),
      GenieChipOption('Rum', '🏝', tags: {'rum'}),
      GenieChipOption('Whiskey', '🥃', tags: {'whiskey', 'bourbon'}),
    ],
  );

  static GenieFilterSection vibesFor(GenieFilterKind kind) =>
      kind == GenieFilterKind.drinks ? drinkVibes : foodVibes;

  static GenieFilterSection dietaryFor(GenieFilterKind kind) =>
      kind == GenieFilterKind.drinks ? drinkType : foodDietary;

  static const List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  /// Flag/emoji shown next to a cuisine chip.
  static String cuisineEmoji(String cuisine) =>
      const {
        'korean': '🇰🇷',
        'italian': '🍝',
        'mexican': '🌮',
        'japanese': '🍱',
        'thai': '🥘',
        'indian': '🍛',
        'american': '🍔',
        'chinese': '🥡',
        'mediterranean': '🫒',
        'french': '🥖',
        'vietnamese': '🍜',
        'middle eastern': '🧆',
        'hawaiian': '🌺',
        'brazilian': '🇧🇷',
      }[cuisine.toLowerCase()] ??
      '🍽';
}

/// A user's Genie filter selections for one deck kind. Empty selections and
/// null limits mean "no constraint".
@immutable
class GenieFilters {
  const GenieFilters({
    this.vibes = const {},
    this.cuisines = const {},
    this.dietary = const {},
    this.difficulty = const {},
    this.maxMinutes,
    this.maxHeat,
  });

  static const GenieFilters empty = GenieFilters();

  /// Upper bound of the time slider; at this value time is unlimited.
  static const int minutesCap = 90;

  /// Highest heat level the spice slider distinguishes; null = any.
  static const int heatCap = 4;

  final Set<String> vibes;
  final Set<String> cuisines;
  final Set<String> dietary;
  final Set<String> difficulty;
  final int? maxMinutes;
  final int? maxHeat;

  bool get isEmpty =>
      vibes.isEmpty &&
      cuisines.isEmpty &&
      dietary.isEmpty &&
      difficulty.isEmpty &&
      maxMinutes == null &&
      maxHeat == null;

  /// Number of active constraints — shown as a badge on the hub.
  int get activeCount =>
      vibes.length +
      cuisines.length +
      dietary.length +
      difficulty.length +
      (maxMinutes == null ? 0 : 1) +
      (maxHeat == null ? 0 : 1);

  GenieFilters copyWith({
    Set<String>? vibes,
    Set<String>? cuisines,
    Set<String>? dietary,
    Set<String>? difficulty,
    int? maxMinutes,
    bool clearMaxMinutes = false,
    int? maxHeat,
    bool clearMaxHeat = false,
  }) {
    return GenieFilters(
      vibes: vibes ?? this.vibes,
      cuisines: cuisines ?? this.cuisines,
      dietary: dietary ?? this.dietary,
      difficulty: difficulty ?? this.difficulty,
      maxMinutes: clearMaxMinutes ? null : maxMinutes ?? this.maxMinutes,
      maxHeat: clearMaxHeat ? null : maxHeat ?? this.maxHeat,
    );
  }

  /// Whether [card] passes every active constraint for [kind].
  bool matches(BiteCard card, GenieFilterKind kind) {
    if (!_sectionMatches(GenieFilterCatalog.vibesFor(kind), vibes, card)) {
      return false;
    }
    if (!_sectionMatches(GenieFilterCatalog.dietaryFor(kind), dietary, card)) {
      return false;
    }
    if (cuisines.isNotEmpty) {
      final c = card.cuisine.trim().toLowerCase();
      if (!cuisines.any((s) => s.toLowerCase() == c)) return false;
    }
    if (difficulty.isNotEmpty) {
      final d = card.diff.trim().toLowerCase();
      if (!difficulty.any((s) => s.toLowerCase() == d)) return false;
    }
    final limit = maxMinutes;
    if (limit != null) {
      final m = minutesOf(card);
      if (m == null || m > limit) return false;
    }
    final heat = maxHeat;
    if (heat != null && card.heat > heat) return false;
    return true;
  }

  List<BiteCard> apply(List<BiteCard> cards, GenieFilterKind kind) {
    if (isEmpty) return cards;
    return cards.where((c) => matches(c, kind)).toList();
  }

  static bool _sectionMatches(
    GenieFilterSection section,
    Set<String> selected,
    BiteCard card,
  ) {
    if (selected.isEmpty) return true;
    final options = [
      for (final label in selected) ?section.option(label),
    ];
    // Unknown labels (e.g. from an older app version) are ignored.
    if (options.isEmpty) return true;
    return section.matchAll
        ? options.every((o) => o.matches(card))
        : options.any((o) => o.matches(card));
  }

  /// Normalized tags: lowercase, `#` and non-alphanumerics removed.
  static Set<String> tagsOf(BiteCard card) => {
    for (final t in card.tags) normalize(t),
  };

  static String normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// Total minutes for [card]: prep + cook when stored separately,
  /// otherwise parsed from the display string ("25 min", "1 hr 10 min").
  static int? minutesOf(BiteCard card) {
    final prep = card.prepMin;
    final cook = card.cookMin;
    if (prep != null || cook != null) return (prep ?? 0) + (cook ?? 0);
    final t = card.time.toLowerCase();
    if (t.trim().isEmpty) return null;
    var total = 0;
    var found = false;
    final hours = RegExp(r'(\d+)\s*(h|hr|hrs|hour|hours)\b').firstMatch(t);
    if (hours != null) {
      total += int.parse(hours.group(1)!) * 60;
      found = true;
    }
    final mins = RegExp(r'(\d+)\s*(m|min|mins|minute|minutes)\b').firstMatch(t);
    if (mins != null) {
      total += int.parse(mins.group(1)!);
      found = true;
    }
    if (!found) {
      final bare = RegExp(r'\d+').firstMatch(t);
      if (bare == null) return null;
      return int.parse(bare.group(0)!);
    }
    return total;
  }

  /// Distinct cuisines in [cards], most common first.
  static List<String> cuisinesIn(List<BiteCard> cards) {
    final counts = <String, int>{};
    for (final c in cards) {
      final name = c.cuisine.trim();
      if (name.isEmpty || name.toLowerCase() == 'various') continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return names;
  }

  /// Maps onboarding dietary prefs ("Vegetarian 🥬", "Dairy-Free 🥛") to
  /// the food dietary chips they correspond to.
  static Set<String> dietaryFromProfile(List<String> prefs) {
    final wanted = {for (final p in prefs) normalize(p)};
    final aliases = <String, String>{
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'glutenfree': 'Gluten-Free',
      'dairyfree': 'Dairy-Free',
      'highprotein': 'High Protein',
      'keto': 'Low Carb',
    };
    return {
      for (final e in aliases.entries)
        if (wanted.contains(e.key)) e.value,
    };
  }

  Map<String, dynamic> toJson() => {
    'vibes': vibes.toList(),
    'cuisines': cuisines.toList(),
    'dietary': dietary.toList(),
    'difficulty': difficulty.toList(),
    'max_minutes': maxMinutes,
    'max_heat': maxHeat,
  };

  factory GenieFilters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    Set<String> strings(String key) =>
        ((json[key] as List?) ?? const []).whereType<String>().toSet();
    return GenieFilters(
      vibes: strings('vibes'),
      cuisines: strings('cuisines'),
      dietary: strings('dietary'),
      difficulty: strings('difficulty'),
      maxMinutes: (json['max_minutes'] as num?)?.toInt(),
      maxHeat: (json['max_heat'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GenieFilters &&
      setEquals(other.vibes, vibes) &&
      setEquals(other.cuisines, cuisines) &&
      setEquals(other.dietary, dietary) &&
      setEquals(other.difficulty, difficulty) &&
      other.maxMinutes == maxMinutes &&
      other.maxHeat == maxHeat;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(vibes),
    Object.hashAllUnordered(cuisines),
    Object.hashAllUnordered(dietary),
    Object.hashAllUnordered(difficulty),
    maxMinutes,
    maxHeat,
  );
}
