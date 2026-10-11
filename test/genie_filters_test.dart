import 'package:bite/features/content/domain/entities/bite_card.dart';
import 'package:bite/features/genie/domain/genie_filters.dart';
import 'package:bite/features/genie/domain/genie_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

BiteCard _card(
  int id, {
  String time = '20 min',
  String diff = 'Easy',
  int heat = 0,
  String cuisine = 'Korean',
  List<String> tags = const [],
  String hearts = '1K',
}) => BiteCard(
  id: id,
  title: 'Dish $id',
  creator: '@c',
  time: time,
  diff: diff,
  serves: 2,
  heat: heat,
  saved: '0',
  hearts: hearts,
  comments: 0,
  emoji: '🍽',
  cuisine: cuisine,
  gradient: '',
  tags: tags,
);

void main() {
  group('GenieFilters', () {
    test('minutesOf parses display strings and prep/cook', () {
      expect(GenieFilters.minutesOf(_card(1, time: '25 min')), 25);
      expect(GenieFilters.minutesOf(_card(1, time: '1 hr 10 min')), 70);
      expect(GenieFilters.minutesOf(_card(1, time: '')), isNull);
    });

    test('empty filters match everything', () {
      final cards = [_card(1), _card(2)];
      expect(GenieFilters.empty.apply(cards, GenieFilterKind.food), cards);
    });

    test('vibes and dietary require every selection; cuisine is any', () {
      final cards = [
        _card(1, time: '15 min', tags: ['#healthy', '#vegan']),
        _card(2, time: '45 min', tags: ['#healthy', '#vegan']),
        _card(3, time: '15 min', tags: ['#comfort'], cuisine: 'Thai'),
      ];
      const f = GenieFilters(
        vibes: {'Under 30 Min', 'Healthy'},
        dietary: {'Vegetarian'},
      );
      expect(f.apply(cards, GenieFilterKind.food).map((c) => c.id), [1]);

      const c = GenieFilters(cuisines: {'Thai', 'Italian'});
      expect(c.apply(cards, GenieFilterKind.food).map((c) => c.id), [3]);
    });

    test('max time, difficulty and heat', () {
      final cards = [
        _card(1, time: '20 min', heat: 3, diff: 'Hard'),
        _card(2, time: '40 min', heat: 0),
        _card(3, time: '10 min', heat: 1),
      ];
      const f = GenieFilters(maxMinutes: 30, maxHeat: 2);
      expect(f.apply(cards, GenieFilterKind.food).map((c) => c.id), [3]);
      const d = GenieFilters(difficulty: {'Hard'});
      expect(d.apply(cards, GenieFilterKind.food).map((c) => c.id), [1]);
    });

    test('json round trip', () {
      const f = GenieFilters(
        vibes: {'Healthy'},
        cuisines: {'Korean'},
        dietary: {'Vegan'},
        difficulty: {'Easy'},
        maxMinutes: 30,
        maxHeat: 1,
      );
      expect(GenieFilters.fromJson(f.toJson()), f);
      expect(GenieFilters.fromJson(null).isEmpty, isTrue);
    });

    test('maps onboarding dietary prefs to chips', () {
      expect(
        GenieFilters.dietaryFromProfile(['Vegetarian 🥬', 'Dairy-Free 🥛']),
        {'Vegetarian', 'Dairy-Free'},
      );
    });
  });

  group('GenieSuggestions', () {
    test('favors loved cuisines and explains why', () {
      final picks = GenieSuggestions.rank(
        pool: [
          _card(1, cuisine: 'Italian', time: '45 min'),
          _card(2, cuisine: 'Korean', time: '45 min'),
        ],
        favoriteCuisines: ['Korean'],
        limit: 1,
      );
      expect(picks.single.card.id, 2);
      expect(picks.single.reason, contains('Korean'));
    });
  });
}
