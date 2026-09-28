import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A single ingredient line — ports the `{ qty, unit, name }` shape from
/// `screens-detail.jsx`.
class CookIngredient {
  const CookIngredient(this.qty, this.unit, this.name);

  final double qty;
  final String unit;
  final String name;
}

/// A cooking/mixing step. [tasks] is used by Cook Mode's checklist; the
/// simpler Recipe Detail "steps" tab just shows [text] + [timerLabel].
class CookStepDef {
  const CookStepDef(
    this.text, {
    this.timerSecs,
    this.timerLabel,
    this.tip,
    this.tasks = const [],
    this.isSide = false,
  });

  final String text;
  final int? timerSecs;

  /// Pretty label shown in Recipe Detail's static step list (e.g. "7:00").
  final String? timerLabel;
  final String? tip;
  final List<String> tasks;
  final bool isSide;
}

/// A side dish offered from the "Add Sides & Pairings" sheet.
class SideDish {
  const SideDish({
    required this.name,
    required this.emoji,
    required this.time,
    required this.color,
    required this.desc,
    this.ingredients = const [],
    this.match,
  });

  final String name;
  final String emoji;
  final String time;
  final Color color;
  final String desc;
  final List<String> ingredients;

  /// Genie AI match percentage label, e.g. "95%".
  final String? match;
}

/// A dish grouped for Cook Mode's "all ingredients" sheet.
class CookDish {
  const CookDish({
    required this.name,
    required this.emoji,
    required this.color,
    required this.items,
  });

  final String name;
  final String emoji;
  final Color color;
  final List<String> items;
}

/// Local, client-side mock data for the cooking flow. There is no
/// `ingredients` / `steps` table in Supabase, so — mirroring the prototype,
/// which hardcodes a single fried-chicken / bourbon-smash template
/// regardless of which card is active — this data is a fixed template keyed
/// only on food vs. drink.
abstract final class CookData {
  static const int baseServingsFood = 4;
  static const int baseServingsDrink = 1;

  // ── Flat ingredient lists (Recipe Detail "Ingredients" tab) ──
  static const List<CookIngredient> foodIngredients = [
    CookIngredient(4, '', 'chicken thighs, bone-in'),
    CookIngredient(3, 'tbsp', 'gochujang paste'),
    CookIngredient(2, 'tbsp', 'soy sauce'),
    CookIngredient(1, 'tbsp', 'sesame oil'),
    CookIngredient(2, 'cloves', 'garlic, minced'),
    CookIngredient(1, 'tbsp', 'ginger, grated'),
    CookIngredient(1, 'tbsp', 'rice vinegar'),
    CookIngredient(1, 'tbsp', 'honey'),
    CookIngredient(0, '', 'Cornstarch for coating'),
    CookIngredient(0, '', 'Oil for frying'),
    CookIngredient(0, '', 'Sesame seeds & scallions for garnish'),
  ];

  static const List<CookIngredient> drinkIngredients = [
    CookIngredient(2, 'oz', 'bourbon'),
    CookIngredient(0.75, 'oz', 'fresh lemon juice'),
    CookIngredient(0.5, 'oz', 'honey syrup (2:1)'),
    CookIngredient(2, 'dashes', 'Angostura bitters'),
    CookIngredient(0, '', 'Ice'),
    CookIngredient(0, '', 'Orange peel for garnish'),
    CookIngredient(0, '', 'Cocktail cherry'),
  ];

  // ── Simple step list (Recipe Detail "Steps/Mixing" tab) ──
  static const List<CookStepDef> foodDetailSteps = [
    CookStepDef(
        'Mix gochujang, soy sauce, sesame oil, garlic, ginger, vinegar, and honey in a bowl.'),
    CookStepDef(
        'Pat chicken dry, season with salt and pepper, then coat in cornstarch.'),
    CookStepDef('Heat oil to 350°F. Fry chicken 6-8 min per side until golden and cooked through.',
        timerLabel: '7:00'),
    CookStepDef('Toss fried chicken in the gochujang glaze while still hot.'),
    CookStepDef('Garnish with sesame seeds and sliced scallions. Serve immediately.'),
  ];

  static const List<CookStepDef> drinkDetailSteps = [
    CookStepDef('Chill a rocks glass or coupe in the freezer. Gather all bottles and tools.'),
    CookStepDef('Measure 2 oz bourbon and ¾ oz fresh lemon juice into a shaker.'),
    CookStepDef('Add ½ oz honey syrup and 2 dashes of Angostura bitters.'),
    CookStepDef('Fill shaker with ice. Shake vigorously for 12–15 seconds until frosty.',
        timerLabel: '0:15'),
    CookStepDef('Strain into chilled glass over fresh ice. Express orange peel over surface.'),
    CookStepDef('Garnish with orange peel and cocktail cherry. Serve immediately.'),
  ];

  // ── Task-based steps (Cook Mode) ──
  static const List<CookStepDef> foodCookSteps = [
    CookStepDef(
      'Prep the Glaze',
      tip: 'Taste the glaze — adjust honey for sweetness or more gochujang for heat.',
      tasks: [
        'Measure gochujang, soy sauce, sesame oil',
        'Mince garlic and grate ginger',
        'Add rice vinegar and honey',
        'Whisk everything together until smooth',
      ],
    ),
    CookStepDef(
      'Coat the Chicken',
      tasks: [
        'Pat chicken pieces completely dry',
        'Season with salt and pepper',
        'Coat generously in cornstarch, press firmly',
      ],
    ),
    CookStepDef(
      'Heat the Oil',
      timerSecs: 180,
      tip: 'Use a thermometer — too hot and the coating burns, too cool and it gets greasy.',
      tasks: [
        'Fill deep skillet with 2 inches of oil',
        'Heat oil to 350°F',
        'Test with a small piece of coating',
      ],
    ),
    CookStepDef(
      'Fry the Chicken',
      timerSecs: 420,
      tasks: [
        'Carefully lower chicken into hot oil',
        'Fry 6-8 min first side until golden',
        'Flip and fry 6-8 min second side',
        'Check internal temp reaches 165°F',
        'Transfer to wire rack to drain',
      ],
    ),
    CookStepDef(
      'Glaze & Toss',
      tasks: [
        'Reheat glaze briefly if needed',
        'Toss fried chicken in glaze while hot',
        'Ensure every piece is evenly coated',
      ],
    ),
    CookStepDef(
      'Garnish & Serve',
      tasks: [
        'Sprinkle sesame seeds on top',
        'Slice scallions and scatter over chicken',
        'Serve immediately while crispy',
      ],
    ),
    CookStepDef(
      '🍚 Side: Kimchi Fried Rice — Prep',
      tip: 'Start this while chicken is frying',
      isSide: true,
      tasks: [
        'Dice kimchi into small pieces',
        'Prepare 3 cups cooked rice (day-old works best)',
        'Crack 2 eggs into a bowl',
      ],
    ),
    CookStepDef(
      '🍚 Side: Kimchi Fried Rice — Cook',
      timerSecs: 300,
      isSide: true,
      tasks: [
        'Stir-fry kimchi in sesame oil for 2 min',
        'Add rice, soy sauce, gochugaru — cook 5 min',
        'Push to side, scramble egg, then mix together',
        'Top with fried egg and scallions',
      ],
    ),
    CookStepDef(
      '🥒 Side: Cucumber Salad — Prep & Toss',
      tip: 'Smashing releases more flavor than slicing',
      isSide: true,
      tasks: [
        'Smash cucumbers with flat of knife, slice into pieces',
        'Mix rice vinegar, sesame oil, soy sauce, chili flakes',
        'Toss cucumbers in dressing, top with sesame seeds',
      ],
    ),
  ];

  static const List<CookStepDef> drinkCookSteps = [
    CookStepDef(
      'Prep Your Glass',
      tip: 'A chilled glass makes all the difference — pop it in the freezer 10 min ahead.',
      tasks: [
        'Select a rocks glass or coupe',
        'Chill glass in freezer or fill with ice',
        'Gather all bottles and tools',
      ],
    ),
    CookStepDef(
      'Measure & Pour Base',
      tip: 'Use a jigger for consistency — eyeballing leads to unbalanced drinks.',
      tasks: [
        'Measure 2 oz bourbon (or spirit of choice)',
        'Pour into mixing glass or shaker',
        'Add ¾ oz fresh lemon juice',
      ],
    ),
    CookStepDef(
      'Add Sweetener & Bitters',
      tasks: [
        'Add ½ oz honey syrup (2:1 honey to water)',
        'Dash 2–3 drops Angostura bitters',
        'Add optional: ¼ oz ginger liqueur',
      ],
    ),
    CookStepDef(
      'Shake or Stir',
      timerSecs: 15,
      tip: 'Shake citrus drinks, stir spirit-forward. 12-15 seconds is the sweet spot.',
      tasks: [
        'Fill shaker with ice',
        'Shake vigorously for 12–15 seconds',
        'You want it frosty cold on the outside',
      ],
    ),
    CookStepDef(
      'Strain & Garnish',
      tasks: [
        'Strain into prepared glass over fresh ice',
        'Express orange peel over surface',
        'Garnish with dehydrated citrus wheel or cherry',
      ],
    ),
    CookStepDef(
      'Serve & Enjoy 🥂',
      tasks: [
        'Slide a cocktail napkin underneath',
        'Take a photo for b🌶te 📸',
        'Sip and savor — cheers!',
      ],
    ),
  ];

  // ── Cook Mode "all ingredients" sheet, grouped by dish ──
  static List<CookDish> foodDishes(Color themeColor) => [
        CookDish(
          name: 'Gochujang Fried Chicken',
          emoji: '🍗',
          color: themeColor,
          items: const [
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
        ),
        const CookDish(
          name: 'Kimchi Fried Rice',
          emoji: '🍚',
          color: AppColors.amber,
          items: [
            '1 cup kimchi',
            '3 cups cooked rice',
            '2 eggs',
            '1 tbsp sesame oil',
            '2 tbsp soy sauce',
            '1 tsp gochugaru',
            'Scallions',
          ],
        ),
        const CookDish(
          name: 'Sesame Cucumber Salad',
          emoji: '🥒',
          color: Color(0xFF4CAF50),
          items: [
            '3 Persian cucumbers',
            '2 tbsp rice vinegar',
            '1 tbsp sesame oil',
            '1 tsp soy sauce',
            '½ tsp chili flakes',
            'Sesame seeds',
          ],
        ),
      ];

  static List<CookDish> drinkDishes(Color themeColor) => [
        CookDish(
          name: 'Spiced Honey Bourbon Smash',
          emoji: '🥃',
          color: AppColors.amber,
          items: const [
            '2 oz bourbon',
            '¾ oz lemon juice',
            '½ oz honey syrup',
            'Angostura bitters',
            'Ice',
            'Orange peel',
            'Cocktail cherry',
          ],
        ),
      ];

  // ── Sides sheet content ──
  static const List<SideDish> creatorPicks = [
    SideDish(
      name: 'Kimchi Fried Rice',
      emoji: '🍚',
      time: '22 min',
      color: AppColors.amber,
      desc: 'Perfect side for fried chicken',
      ingredients: [
        '1 cup kimchi, diced',
        '3 cups cooked rice (day-old)',
        '2 eggs',
        '1 tbsp sesame oil',
        '2 tbsp soy sauce',
        '1 tsp gochugaru',
        'Scallions for garnish',
      ],
    ),
    SideDish(
      name: 'Sesame Cucumber Salad',
      emoji: '🥒',
      time: '8 min',
      color: Color(0xFF4CAF50),
      desc: 'Light & refreshing contrast',
      ingredients: [
        '3 Persian cucumbers',
        '2 tbsp rice vinegar',
        '1 tbsp sesame oil',
        '1 tsp soy sauce',
        '½ tsp chili flakes',
        'Sesame seeds',
      ],
    ),
  ];

  static const List<SideDish> browseSides = [
    SideDish(
      name: 'Garlic Mashed Potatoes',
      emoji: '🥔',
      time: '20 min',
      color: AppColors.amber,
      desc: 'Creamy comfort classic',
      ingredients: [
        '2 lbs russet potatoes',
        '4 tbsp butter',
        '½ cup heavy cream',
        '4 cloves garlic, roasted',
        'Salt & pepper to taste',
      ],
    ),
    SideDish(
      name: 'Roasted Asparagus',
      emoji: '🌿',
      time: '12 min',
      color: Color(0xFF4CAF50),
      desc: 'Simple & elegant',
      ingredients: [
        '1 bunch asparagus',
        '2 tbsp olive oil',
        '2 cloves garlic, minced',
        'Salt, pepper, lemon zest',
      ],
    ),
    SideDish(
      name: 'Mac & Cheese',
      emoji: '🧀',
      time: '25 min',
      color: Color(0xFFFFD700),
      desc: 'Baked southern style',
      ingredients: [
        '8 oz elbow macaroni',
        '2 cups sharp cheddar',
        '1 cup whole milk',
        '2 tbsp butter',
        '2 tbsp flour',
        '½ cup breadcrumbs',
      ],
    ),
    SideDish(
      name: 'Corn on the Cob',
      emoji: '🌽',
      time: '10 min',
      color: AppColors.amber,
      desc: 'Grilled with herb butter',
      ingredients: [
        '4 ears corn',
        '2 tbsp butter',
        'Fresh herbs (cilantro, chives)',
        'Salt & pepper',
      ],
    ),
    SideDish(
      name: 'Coleslaw',
      emoji: '🥗',
      time: '5 min',
      color: Color(0xFF4CAF50),
      desc: 'Tangy & crunchy',
      ingredients: [
        '½ head cabbage, shredded',
        '2 carrots, grated',
        '½ cup mayo',
        '2 tbsp apple cider vinegar',
        '1 tbsp sugar',
      ],
    ),
  ];

  static const List<SideDish> genieSides = [
    SideDish(
      name: 'Sesame Cucumber Salad',
      emoji: '🥒',
      time: '10 min',
      color: AppColors.amber,
      desc: 'Light & refreshing — balances the heat',
      match: '95%',
    ),
    SideDish(
      name: 'Coconut Jasmine Rice',
      emoji: '🍚',
      time: '15 min',
      color: AppColors.amber,
      desc: 'Absorbs the gochujang glaze perfectly',
      match: '92%',
    ),
    SideDish(
      name: 'Quick Kimchi Slaw',
      emoji: '🥬',
      time: '5 min',
      color: AppColors.amber,
      desc: 'Traditional Korean pairing',
      match: '88%',
    ),
  ];

  static const List<SideDish> genieDrinks = [
    SideDish(
      name: 'Korean Lager (Hite)',
      emoji: '🍺',
      time: '—',
      color: AppColors.cyan,
      desc: 'Classic pairing with fried chicken',
      match: '97%',
    ),
    SideDish(
      name: 'Thai Iced Tea',
      emoji: '🧋',
      time: '5 min',
      color: AppColors.cyan,
      desc: 'Sweet cream cuts the spice',
      match: '90%',
    ),
  ];

  static const List<SideDish> genieDesserts = [
    SideDish(
      name: 'Mango Sticky Rice',
      emoji: '🍧',
      time: '15 min',
      color: AppColors.coral,
      desc: 'Sweet finish after spicy meal',
      match: '91%',
    ),
    SideDish(
      name: 'Matcha Mochi',
      emoji: '🍡',
      time: '—',
      color: AppColors.coral,
      desc: 'Light, not too heavy after fried food',
      match: '85%',
    ),
  ];

  /// Ports `scaleQty` from `screens-detail.jsx` — scales a base quantity to
  /// the selected serving count and prefers common fraction glyphs.
  static String scaleQty(double qty, int baseServings, int servings) {
    if (qty == 0) return '';
    final scaled = (qty / baseServings) * servings;
    if (scaled == scaled.roundToDouble()) return scaled.toInt().toString();
    final nearestHalf = (scaled * 2).round() / 2;
    if ((scaled - nearestHalf).abs() < 0.01) {
      final whole = scaled.floor();
      final frac = scaled - whole;
      if ((frac - 0.5).abs() < 0.01) return whole > 0 ? '$whole½' : '½';
      if ((frac - 0.25).abs() < 0.01) return whole > 0 ? '$whole¼' : '¼';
      if ((frac - 0.75).abs() < 0.01) return whole > 0 ? '$whole¾' : '¾';
    }
    return scaled % 1 == 0 ? scaled.toInt().toString() : scaled.toStringAsFixed(1);
  }

  static String formatIngredient(CookIngredient ing, int baseServings, int servings) {
    final q = scaleQty(ing.qty, baseServings, servings);
    if (q.isEmpty) return ing.name;
    return '$q ${ing.unit} ${ing.name}'.replaceAll(RegExp(r'  +'), ' ').trim();
  }

  static String fmtTime(int seconds) {
    final s = seconds.abs();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }
}
