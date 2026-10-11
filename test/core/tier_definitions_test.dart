import 'package:bite/core/constants/tier_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TierDefinitions.fromRows', () {
    test('sorts by min_xp and ends each level at the next one', () {
      final tiers = TierDefinitions.fromRows([
        {'level': 2, 'name': 'Beginner', 'emoji': '🥄', 'min_xp': 10, 'color': '#4CAF50'},
        {'level': 1, 'name': 'Curious', 'emoji': '👀', 'min_xp': 0, 'color': '#64B5F6'},
        {'level': 3, 'name': 'Chef', 'emoji': '👨‍🍳', 'min_xp': 50, 'color': '#F5A623'},
      ]);
      expect(tiers.map((t) => t.name), ['Curious', 'Beginner', 'Chef']);
      expect(tiers.map((t) => (t.min, t.max)), [(0, 10), (10, 50), (50, 99999)]);
      expect(tiers.first.color.toARGB32(), 0xFF64B5F6);
    });

    test('reads tagline and kitchen reward, blank reward means none', () {
      final tiers = TierDefinitions.fromRows([
        {'level': 1, 'name': 'Curious', 'min_xp': 0, 'tagline': 'Welcome!', 'reward_name': ''},
        {'level': 2, 'name': 'Beginner', 'min_xp': 10, 'reward_emoji': '🥄', 'reward_name': 'Wooden Spoon'},
      ]);
      expect(tiers[0].tagline, 'Welcome!');
      expect(tiers[0].hasReward, isFalse);
      expect(tiers[1].rewardName, 'Wooden Spoon');
      expect(tiers[1].hasReward, isTrue);
    });

    test('skips invalid rows and rejects a ladder not starting at 0', () {
      expect(
        TierDefinitions.fromRows([
          {'level': 1, 'name': '', 'min_xp': 0},
          {'level': 2, 'name': 'Beginner', 'min_xp': 10},
        ]),
        isEmpty,
      );
    });

    test('defaults cover the full built-in ladder', () {
      expect(TierDefinitions.tierFor(0).name, 'Curious');
      expect(TierDefinitions.tierFor(299).name, 'Chef');
      expect(TierDefinitions.tierFor(300).name, 'Master Chef');
      expect(TierDefinitions.tierFor(5000).name, 'b🌶te Legend');
    });
  });
}
