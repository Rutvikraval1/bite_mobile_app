import 'package:flutter/foundation.dart';

import '../../features/content/domain/entities/meal_plan.dart';

/// Bottom-nav tabs — mirrors the JS `activeTab`.
enum AppTab { home, social, genie, saved, chat }

/// Deck sub-tabs — mirrors the JS `subTab`.
enum DeckTab { food, drinks, places }

/// A meal added to the tray / planner — mirrors JS `mealItems` entries.
@immutable
class MealItem {
  const MealItem({
    required this.title,
    required this.emoji,
    required this.type,
    this.color,
  });

  final String title;
  final String emoji;
  final String type; // food | drink | place
  final int? color;

  MealItem copyWith({int? color}) {
    return MealItem(
      title: title,
      emoji: emoji,
      type: type,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MealItem && other.title == title && other.type == type;

  @override
  int get hashCode => Object.hash(title, type);
}

/// In-progress "add to meal plan" sheet payload — JS `mealPlannerSheet`.
@immutable
class MealPlannerSheet {
  const MealPlannerSheet({
    required this.title,
    required this.emoji,
    required this.color,
    this.type = 'food',
  });

  final String title;
  final String emoji;
  final int color;
  final String type;
}

/// A post the user is sharing after cooking — JS `sharedPost`.
@immutable
class SharedPost {
  const SharedPost({
    this.comment = '',
    this.rating = 0,
    this.photo,
    this.name = '',
    this.emoji = '🍽',
  });

  final String comment;
  final int rating;
  final String? photo;
  final String name;
  final String emoji;
}

/// Global app state shared across every screen.
/// Ports the top-level `useState` batch in the JS prototype.
@immutable
class AppState {
  const AppState({
    this.activeTab = AppTab.home,
    this.subTab = DeckTab.food,
    this.ageVerified = false,
    this.locationGranted = false,
    this.xp = 140,
    this.biteCoins = 156,
    this.streakCount = 12,
    this.longestStreak = 23,
    this.streakMultiplier = 1.5,
    this.streakFreezes = 1,
    this.dailyChestClaimed = false,
    this.showDailyChest = false,
    this.showChestRewards,
    this.showStreakSheet = false,
    this.mealItems = const [],
    this.mealCalendar = const {},
    this.mealPlannerSheet,
    this.sharedPost,
    this.userBadges = const [],
    this.badgeReveal,
    this.isPremium = false,
    this.userTier = 'free',
    this.userCuisines = const [],
    this.notificationCount = 3,
    this.trendingMode = false,
    this.activeCardIndex = 0,
    this.hydrated = false,
  });

  final AppTab activeTab;
  final DeckTab subTab;
  final bool ageVerified;
  final bool locationGranted;
  final int xp;
  final int biteCoins;
  final int streakCount;
  final int longestStreak;
  final double streakMultiplier;
  final int streakFreezes;
  final bool dailyChestClaimed;
  final bool showDailyChest;
  final ChestRewards? showChestRewards;
  final bool showStreakSheet;
  final List<MealItem> mealItems;
  final MealCalendar mealCalendar;
  final MealPlannerSheet? mealPlannerSheet;
  final SharedPost? sharedPost;
  final List<String> userBadges;

  /// Badge id currently being revealed by the overlay.
  final String? badgeReveal;
  final bool isPremium;
  final String userTier;
  final List<String> userCuisines;
  final int notificationCount;
  final bool trendingMode;
  final int activeCardIndex;

  /// True once gamification state has been hydrated from the profile.
  final bool hydrated;

  AppState copyWith({
    AppTab? activeTab,
    DeckTab? subTab,
    bool? ageVerified,
    bool? locationGranted,
    int? xp,
    int? biteCoins,
    int? streakCount,
    int? longestStreak,
    double? streakMultiplier,
    int? streakFreezes,
    bool? dailyChestClaimed,
    bool? showDailyChest,
    ChestRewards? showChestRewards,
    bool clearChestRewards = false,
    bool? showStreakSheet,
    List<MealItem>? mealItems,
    MealCalendar? mealCalendar,
    MealPlannerSheet? mealPlannerSheet,
    bool clearMealPlannerSheet = false,
    SharedPost? sharedPost,
    bool clearSharedPost = false,
    List<String>? userBadges,
    String? badgeReveal,
    bool clearBadgeReveal = false,
    bool? isPremium,
    String? userTier,
    List<String>? userCuisines,
    int? notificationCount,
    bool? trendingMode,
    int? activeCardIndex,
    bool? hydrated,
  }) {
    return AppState(
      activeTab: activeTab ?? this.activeTab,
      subTab: subTab ?? this.subTab,
      ageVerified: ageVerified ?? this.ageVerified,
      locationGranted: locationGranted ?? this.locationGranted,
      xp: xp ?? this.xp,
      biteCoins: biteCoins ?? this.biteCoins,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      streakMultiplier: streakMultiplier ?? this.streakMultiplier,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      dailyChestClaimed: dailyChestClaimed ?? this.dailyChestClaimed,
      showDailyChest: showDailyChest ?? this.showDailyChest,
      showChestRewards: clearChestRewards
          ? null
          : showChestRewards ?? this.showChestRewards,
      showStreakSheet: showStreakSheet ?? this.showStreakSheet,
      mealItems: mealItems ?? this.mealItems,
      mealCalendar: mealCalendar ?? this.mealCalendar,
      mealPlannerSheet: clearMealPlannerSheet
          ? null
          : mealPlannerSheet ?? this.mealPlannerSheet,
      sharedPost: clearSharedPost ? null : sharedPost ?? this.sharedPost,
      userBadges: userBadges ?? this.userBadges,
      badgeReveal: clearBadgeReveal ? null : badgeReveal ?? this.badgeReveal,
      isPremium: isPremium ?? this.isPremium,
      userTier: userTier ?? this.userTier,
      userCuisines: userCuisines ?? this.userCuisines,
      notificationCount: notificationCount ?? this.notificationCount,
      trendingMode: trendingMode ?? this.trendingMode,
      activeCardIndex: activeCardIndex ?? this.activeCardIndex,
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

/// Rewards from a claimed daily chest — JS `showChestRewards`.
@immutable
class ChestRewards {
  const ChestRewards({this.coins = 0, this.xp = 0, this.shard, this.type = ''});

  final int coins;
  final int xp;
  final String? shard;
  final String type;
}

/// Default guest state — mirrors `restartDemo` for logged-out users.
const AppState guestAppState = AppState();
