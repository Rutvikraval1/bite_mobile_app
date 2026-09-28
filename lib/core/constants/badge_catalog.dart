import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A badge definition from the catalog.
class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.color,
    required this.description,
  });

  final String id;
  final String name;
  final String emoji;
  final String rarity;
  final Color color;
  final String description;
}

/// Badge catalog shared by the award system and profile UI.
abstract final class BadgeCatalog {
  static const List<Badge> all = [
    Badge(id: 'first_bite', name: 'First Bite', emoji: '🍴', rarity: 'Common', color: Color(0xFF9E9E9E), description: 'Swipe your first dish'),
    Badge(id: 'first_save', name: 'Recipe Saver', emoji: '🔖', rarity: 'Common', color: Color(0xFF9E9E9E), description: 'Save your first recipe'),
    Badge(id: 'first_cook', name: 'First Cook', emoji: '🍳', rarity: 'Common', color: Color(0xFF9E9E9E), description: 'Complete your first cook'),
    Badge(id: 'first_share', name: 'Share Master', emoji: '📤', rarity: 'Uncommon', color: AppColors.saveGreenLight, description: 'Share your first creation'),
    Badge(id: 'spice_seeker', name: 'Spice Seeker', emoji: '🌶️', rarity: 'Uncommon', color: AppColors.saveGreenLight, description: 'Cook your first spicy dish'),
    Badge(id: 'meal_planner', name: 'Meal Planner', emoji: '📅', rarity: 'Uncommon', color: AppColors.saveGreenLight, description: 'Add your first meal to the plan'),
    Badge(id: 'first_streak', name: 'First Streak', emoji: '🔥', rarity: 'Uncommon', color: AppColors.saveGreenLight, description: 'Start your first streak'),
    Badge(id: 'week_warrior', name: 'Week Warrior', emoji: '⚡', rarity: 'Rare', color: Color(0xFFFFD700), description: 'Reach a 7-day streak'),
    Badge(id: 'night_owl', name: 'Night Owl', emoji: '🦉', rarity: 'Rare', color: Color(0xFFFFD700), description: 'Swipe after midnight'),
    Badge(id: 'trending_taste', name: 'Trending Taste', emoji: '💫', rarity: 'Rare', color: Color(0xFFFFD700), description: 'Save a trending dish'),
    Badge(id: 'world_traveler', name: 'Globe Trotter', emoji: '🌍', rarity: 'Epic', color: AppColors.placesPurple, description: 'Explore 5 different cuisines'),
    Badge(id: 'streak_legend', name: 'Streak Legend', emoji: '♨️', rarity: 'Legendary', color: AppColors.coral, description: 'Reach a 30-day streak'),
  ];

  static Badge? byId(String id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }
}
