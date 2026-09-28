import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One component of a curated meal (entree / side / drink).
@immutable
class GenieMealComponent {
  const GenieMealComponent({
    required this.title,
    required this.creator,
    required this.time,
    required this.emoji,
    required this.color,
  });

  final String title;
  final String creator;
  final String time;
  final String emoji;
  final Color color;

  /// Parsed leading integer of [time], e.g. "25 min" → 25.
  int get minutes =>
      int.tryParse(RegExp(r'\d+').firstMatch(time)?[0] ?? '') ?? 0;
}

/// A complete curated meal — entree + side + drink with a shared vibe.
@immutable
class GenieMealPairing {
  const GenieMealPairing({
    required this.name,
    required this.vibe,
    required this.entree,
    required this.side,
    required this.drink,
  });

  final String name;
  final String vibe;
  final GenieMealComponent entree;
  final GenieMealComponent side;
  final GenieMealComponent drink;

  int get totalMinutes => entree.minutes + side.minutes + drink.minutes;
}

/// Canned "Genie curated" meal pairings — there is no real pairing backend,
/// so this mirrors the prototype's hardcoded `mealPairings` demo data.
abstract final class GenieMealPairingsData {
  GenieMealPairingsData._();

  static const List<GenieMealPairing> pairings = [
    GenieMealPairing(
      name: 'Korean Night 🇰🇷',
      vibe: 'Bold, spicy, communal',
      entree: GenieMealComponent(
        title: 'Gochujang Fried Chicken',
        creator: '@chefpriya',
        time: '25 min',
        emoji: '🍗',
        color: AppColors.coral,
      ),
      side: GenieMealComponent(
        title: 'Kimchi Fried Rice',
        creator: '@seoulfoods',
        time: '15 min',
        emoji: '🍚',
        color: AppColors.amber,
      ),
      drink: GenieMealComponent(
        title: 'Soju Watermelon Cooler',
        creator: '@barcraft_mike',
        time: '5 min',
        emoji: '🍉',
        color: AppColors.drinksBlue,
      ),
    ),
    GenieMealPairing(
      name: 'Date Night Italian 🇮🇹',
      vibe: 'Romantic, elegant, wine-friendly',
      entree: GenieMealComponent(
        title: 'Truffle Mushroom Risotto',
        creator: '@noodlequeen',
        time: '35 min',
        emoji: '🍄',
        color: Color(0xFF8B7355),
      ),
      side: GenieMealComponent(
        title: 'Burrata & Heirloom Tomato',
        creator: '@sarah_bakes',
        time: '10 min',
        emoji: '🍅',
        color: AppColors.coralDark,
      ),
      drink: GenieMealComponent(
        title: 'Aperol Spritz',
        creator: '@barcraft_mike',
        time: '3 min',
        emoji: '🍹',
        color: Color(0xFFFF6B35),
      ),
    ),
    GenieMealPairing(
      name: 'Taco Tuesday 🌮',
      vibe: 'Fun, shareable, crowd-pleaser',
      entree: GenieMealComponent(
        title: 'Birria Street Tacos',
        creator: '@abuelitas_kitchen',
        time: '45 min',
        emoji: '🌮',
        color: AppColors.amber,
      ),
      side: GenieMealComponent(
        title: 'Elote Street Corn',
        creator: '@grillmaster',
        time: '15 min',
        emoji: '🌽',
        color: Color(0xFFFFD700),
      ),
      drink: GenieMealComponent(
        title: 'Spicy Margarita',
        creator: '@bangkokbites',
        time: '5 min',
        emoji: '🍋',
        color: AppColors.saveGreen,
      ),
    ),
  ];
}
