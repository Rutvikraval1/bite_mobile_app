import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Local-only demo data backing the screens that have no Supabase table yet
/// (community posts, competitions, cook-offs, Elo voting). Ports the static
/// arrays inlined throughout `screens-profile.jsx` — none of this persists.
abstract final class MockProfileData {
  // ── Saved screen — "My Recipes" (scanned/manual personal cookbook) ──
  static const myRecipes = [
    (title: "Grandma's Lasagna", source: '📸 Photo scan', emoji: '🍝', date: '2d ago'),
    (title: "Mom's Chicken Soup", source: '📸 Photo scan', emoji: '🍲', date: '1w ago'),
    (title: "Uncle's BBQ Ribs", source: '✍️ Manual entry', emoji: '🍖', date: '2w ago'),
  ];

  // ── Saved screen — Collections ──
  static const collections = [
    (name: 'Date Night', count: 8, emoji: '🌙', color: AppColors.placesPurple),
    (name: 'Meal Prep', count: 12, emoji: '📦', color: AppColors.amber),
    (name: 'Party Recipes', count: 5, emoji: '🎉', color: AppColors.coral),
  ];

  // ── Saved screen — Recently passed ──
  static const recentlyPassed = [
    (title: 'Truffle Mushroom Risotto', emoji: '🍄', creator: '@chefmarco'),
    (title: 'Spicy Tuna Poke Bowl', emoji: '🐟', creator: '@hawaiieats'),
    (title: 'Lamb Shawarma Wrap', emoji: '🌯', creator: '@levantine_kitchen'),
    (title: 'Lobster Mac & Cheese', emoji: '🦞', creator: '@sarah_bakes'),
    (title: 'Mango Sticky Rice', emoji: '🥭', creator: '@bangkokbites'),
    (title: 'French Onion Soup', emoji: '🧅', creator: '@parisplate'),
  ];

  // ── Saved screen — Kitchen requests (family meal planning teaser) ──
  static const kitchenRequests = [
    (from: 'Jake', emoji: '🍗', title: 'Gochujang Fried Chicken', note: 'Can we have this for dinner?', time: '2h ago', avatar: '🧒', day: 'Wed'),
    (from: 'Emma', emoji: '🍝', title: 'Truffle Mushroom Risotto', note: 'Please please please! 🙏', time: '5h ago', avatar: '👧', day: 'Sat'),
    (from: 'Mom', emoji: '🥘', title: 'Butter Chicken', note: 'Family dinner Sunday?', time: '1d ago', avatar: '👩', day: null),
  ];

  static const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ── Premium screen — charities ──
  static const charities = [
    (id: 1, emoji: '🐝', name: 'Save the Bees', desc: 'Protecting pollinators worldwide'),
    (id: 2, emoji: '🎖', name: 'Feed Homeless Veterans', desc: 'Meals for those who served'),
    (id: 3, emoji: '🍽', name: 'Feed the Hungry', desc: 'Fighting global food insecurity'),
    (id: 4, emoji: '💧', name: 'Clean Water for All', desc: 'Safe drinking water access'),
    (id: 5, emoji: '🐕', name: 'Rescue Animals', desc: 'Shelter & adoption support'),
    (id: 6, emoji: '🌱', name: 'Plant Trees', desc: 'Reforestation & climate action'),
    (id: 0, emoji: '🚫', name: 'No donation', desc: 'Keep my full payment'),
  ];

  // ── Community impact ──
  static const myCharity = (emoji: '🎖', name: 'Feed Homeless Veterans', donated: r'$12.47', meals: 24);

  static const communityStats = [
    (emoji: '🎖', name: 'Feed Homeless Veterans', total: r'$48,230', impact: '96,460 meals served', pct: 28),
    (emoji: '💧', name: 'Clean Water for All', total: r'$35,100', impact: '3.5M people with clean water', pct: 20),
    (emoji: '🍽', name: 'Feed the Hungry', total: r'$31,800', impact: '127,200 meals provided', pct: 18),
    (emoji: '🐝', name: 'Save the Bees', total: r'$22,500', impact: '450 hives protected', pct: 13),
    (emoji: '🐕', name: 'Rescue Animals', total: r'$19,400', impact: '3,880 animals sheltered', pct: 11),
    (emoji: '🌱', name: 'Plant Trees', total: r'$17,200', impact: '86,000 trees planted', pct: 10),
  ];

  // ── Competitions ──
  static const pets = [
    (name: 'Nacho', emoji: '🐕', active: true),
    (name: 'Biscuit', emoji: '🐱', active: false),
    (name: 'Ember', emoji: '🦊', active: false),
    (name: 'Mochi', emoji: '🐼', active: false),
    (name: 'Basil', emoji: '🐸', active: false),
  ];

  static const frames = [
    (name: 'Default', colors: <Color>[]),
    (name: 'Flame', colors: [AppColors.coral, AppColors.amber, AppColors.coral]),
    (name: 'Crystal', colors: [AppColors.cyan, Color(0xFFE0F7FA), AppColors.drinksBlue, AppColors.cyan]),
    (name: 'Legend', colors: [AppColors.coral, AppColors.amber, Color(0xFF4CAF50), AppColors.cyan, AppColors.placesPurple, AppColors.coral]),
    (name: 'Circuit', colors: [Color(0x884ECDC4), Colors.transparent, Color(0x884ECDC4), Colors.transparent]),
  ];
}

/// A prize tier within a competition.
class CompPrize {
  const CompPrize(this.place, this.prize);
  final String place;
  final String prize;
}

/// A single competition within a tier.
class Competition {
  const Competition({
    required this.title,
    required this.emoji,
    required this.sponsor,
    required this.time,
    required this.entrants,
    required this.theme,
    required this.prizes,
    required this.entry,
  });

  final String title;
  final String emoji;
  final String? sponsor;
  final String time;
  final int entrants;
  final String theme;
  final List<CompPrize> prizes;
  final String entry;
}

/// A competition tier (casual / ranked / elite).
class CompetitionTier {
  const CompetitionTier({
    required this.id,
    required this.label,
    required this.icon,
    required this.desc,
    required this.color,
    required this.comps,
    required this.info,
    this.requirement,
  });

  final String id;
  final String label;
  final String icon;
  final String desc;
  final Color color;
  final List<Competition> comps;
  final String info;
  final String? requirement;
}

abstract final class CompetitionData {
  static final List<CompetitionTier> tiers = [
    CompetitionTier(
      id: 'casual',
      label: '🍳 Casual',
      icon: '🍳',
      desc: 'Everyone welcome',
      color: const Color(0xFF4CAF50),
      info: 'Open to all users. No entry fee, no requirements. Cook, plate, '
          'post — let the community vote!',
      comps: const [
        Competition(
          title: 'Weekend Taco Challenge',
          emoji: '🌮',
          sponsor: '🌿 Whole Foods Market',
          time: '47h 12m',
          entrants: 127,
          theme: 'Create the most creative taco recipe using at least 5 ingredients.',
          entry: 'Free',
          prizes: [
            CompPrize('🥇 1st', '500 b🌶te Coins + Casual Champ Badge'),
            CompPrize('🥈 2nd', '250 b🌶te Coins'),
            CompPrize('🥉 3rd', '100 b🌶te Coins'),
          ],
        ),
        Competition(
          title: 'Best Breakfast Bowl',
          emoji: '🥣',
          sponsor: null,
          time: '3d 8h',
          entrants: 54,
          theme: 'Show us your most photogenic breakfast bowl.',
          entry: 'Free',
          prizes: [CompPrize('🥇 1st', '300 b🌶te Coins')],
        ),
      ],
    ),
    CompetitionTier(
      id: 'ranked',
      label: '🔥 Ranked',
      icon: '🔥',
      desc: '10+ cooks',
      color: AppColors.amber,
      requirement: '🍳 10+ recipes cooked to unlock free entry',
      info: 'For active cooks. Requires 10+ cooked recipes or coin entry. '
          'Higher stakes, bigger prizes, tougher competition.',
      comps: const [
        Competition(
          title: 'b🌶te Chef Showdown',
          emoji: '👨‍🍳',
          sponsor: '🔪 Williams Sonoma',
          time: '12d 4h',
          entrants: 1842,
          theme: 'Cook any dish from scratch, plating matters. Top 10 advance '
              'to live stream finale.',
          entry: '100 Coins OR 10+ cooks',
          prizes: [
            CompPrize('🥇 1st', r'$2,500 Kitchen Set + Ranked Badge'),
            CompPrize('🥈 2nd', r'$1,000 Gift Card + 2K Coins'),
            CompPrize('🥉 3rd', r'$500 Gift Card + 1K Coins'),
            CompPrize('4-10', '500 b🌶te Coins each'),
          ],
        ),
      ],
    ),
    CompetitionTier(
      id: 'elite',
      label: '👑 Elite',
      icon: '👑',
      desc: '50+ cooks · 25+ ratings',
      color: AppColors.coral,
      requirement: '🏆 Win 1 Ranked challenge OR 50 cooks + 25 ratings',
      info: 'The ultimate cooking stage. For serious cooks with 50+ recipes '
          'cooked and 25+ community ratings. Cash prizes up to \$10K.',
      comps: const [
        Competition(
          title: 'World Cook Championship',
          emoji: '🏆',
          sponsor: '🌶 b🌶te Official',
          time: '28d',
          entrants: 8431,
          theme: 'Annual elite competition. Theme revealed at launch. Past '
              'winners have appeared on Food Network.',
          entry: 'Win a Ranked challenge OR 2,000 Coins',
          prizes: [
            CompPrize('🥇 1st', r'$10,000 + b🌶te Ambassador + 1yr Premium'),
            CompPrize('🥈 2nd', r'$5,000 + 10K Coins'),
            CompPrize('🥉 3rd', r'$2,500 + 5K Coins'),
            CompPrize('4-10', r'$500 + 2K Coins each'),
          ],
        ),
      ],
    ),
  ];

  static const activeCookOffs = [
    (
      recipe: 'Gochujang Fried Chicken', emoji: '🍗',
      challenger: '@homecook', challengerAvatar: '🧑‍🍳',
      defender: '@chefpriya', defenderAvatar: '👩‍🍳',
      timeLeft: '18h left', votesLeft: 34, votesRight: 41,
      status: 'voting', verified: true,
    ),
    (
      recipe: 'Birria Street Tacos', emoji: '🌮',
      challenger: '@tacoqueen', challengerAvatar: '👩',
      defender: '@abuelitas_kitchen', defenderAvatar: '👵',
      timeLeft: '2d left', votesLeft: 12, votesRight: 8,
      status: 'voting', verified: true,
    ),
    (
      recipe: 'Pad Thai', emoji: '🥘',
      challenger: '@bangkokbites', challengerAvatar: '👨‍🍳',
      defender: '@homecook', defenderAvatar: '🧑‍🍳',
      timeLeft: '6h left', votesLeft: 0, votesRight: 0,
      status: 'cooking', verified: false,
    ),
  ];

  static const openCookOffs = [
    (recipe: 'Butter Chicken', emoji: '🍛', poster: '@bombay_kitchen', posterAvatar: '👨‍🍳', deadline: '48h', difficulty: 'Medium', note: 'Think you can make it better? Prove it.'),
    (recipe: 'Classic Carbonara', emoji: '🍝', poster: '@marco.eats', posterAvatar: '👨‍🍳', deadline: '72h', difficulty: 'Hard', note: 'No cream allowed. Traditional only.'),
    (recipe: 'Chocolate Lava Cake', emoji: '🍫', poster: '@sarah_bakes', posterAvatar: '👩‍🍳', deadline: '24h', difficulty: 'Medium', note: 'Dessert battle! Best center wins.'),
    (recipe: 'Kung Pao Chicken', emoji: '🥡', poster: '@wok_master', posterAvatar: '👨‍🍳', deadline: '48h', difficulty: 'Easy', note: 'Spiciest version wins. Bring the heat!'),
    (recipe: 'Fish Tacos', emoji: '🌮', poster: '@coastalcook', posterAvatar: '🧑‍🍳', deadline: '72h', difficulty: 'Easy', note: 'Beach vibes only. Freshness is key.'),
  ];
}

/// A single Elo-ranked voting contest entry — mirrors `EloVotingScreen`.
class EloEntry {
  const EloEntry({
    required this.id,
    required this.creator,
    required this.name,
    required this.emoji,
    required this.color,
    required this.elo,
    required this.gradient,
  });

  final int id;
  final String creator;
  final String name;
  final String emoji;
  final Color color;
  final int elo;
  final List<Color> gradient;
}

abstract final class EloVotingData {
  static const List<EloEntry> entries = [
    EloEntry(id: 1, creator: '@abuelitas_kitchen', name: 'Birria Street Tacos', emoji: '🌮', color: Color(0xFF8B4513), elo: 1200, gradient: [Color(0xFF3D1C00), Color(0xFF8B4513), Color(0xFFCD853F)]),
    EloEntry(id: 2, creator: '@chefpriya', name: 'Korean Fusion Tacos', emoji: '🌶', color: AppColors.coral, elo: 1180, gradient: [Color(0xFF2D0000), Color(0xFF8B0000), Color(0xFFFF6347)]),
    EloEntry(id: 3, creator: '@marcusfoods', name: 'Smoked Brisket Tacos', emoji: '🥩', color: Color(0xFF654321), elo: 1150, gradient: [Color(0xFF1A0F00), Color(0xFF654321), Color(0xFFA0522D)]),
    EloEntry(id: 4, creator: '@bangkokbites', name: 'Thai Shrimp Tacos', emoji: '🦐', color: Color(0xFFFF8C00), elo: 1220, gradient: [Color(0xFF331A00), Color(0xFFFF8C00), Color(0xFFFFA500)]),
    EloEntry(id: 5, creator: '@noodlequeen', name: 'Miso Glazed Fish Tacos', emoji: '🐟', color: AppColors.cyan, elo: 1190, gradient: [Color(0xFF001A1A), Color(0x884ECDC4), AppColors.cyan]),
    EloEntry(id: 6, creator: '@sarah_bakes', name: 'Dessert Churro Tacos', emoji: '🍫', color: Color(0xFFD2691E), elo: 1170, gradient: [Color(0xFF1A0A00), Color(0xFFD2691E), Color(0xFFF4A460)]),
    EloEntry(id: 7, creator: '@grillmaster', name: 'Carne Asada Tacos', emoji: '🔥', color: Color(0xFFB22222), elo: 1210, gradient: [Color(0xFF1A0000), Color(0xFFB22222), Color(0xFFDC143C)]),
    EloEntry(id: 8, creator: '@veganvibes', name: 'Jackfruit Carnitas Tacos', emoji: '🌱', color: Color(0xFF228B22), elo: 1160, gradient: [Color(0xFF001A00), Color(0xFF228B22), Color(0xFF32CD32)]),
  ];
}
