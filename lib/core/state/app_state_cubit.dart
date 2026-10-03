import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/profile.dart';
import '../../features/content/domain/entities/bite_card.dart';
import '../../features/content/domain/entities/meal_plan.dart';
import '../constants/badge_catalog.dart';
import '../services/xp_float_service.dart';
import 'app_state.dart';

/// Owns every screen's shared, mutable state — ports the top-level React
/// `useState` batch and the `awardBadges`/hydration logic from the prototype.
class AppStateCubit extends Cubit<AppState> {
  AppStateCubit() : super(guestAppState);

  // ── Tab / sub-tab ──
  void setActiveTab(AppTab tab) => emit(state.copyWith(activeTab: tab));

  void setSubTab(DeckTab tab) => emit(state.copyWith(subTab: tab));

  // ── Gating ──
  void setAgeVerified(bool value) => emit(state.copyWith(ageVerified: value));

  void setLocationGranted(bool value) =>
      emit(state.copyWith(locationGranted: value));

  // ── XP / coins ──
  void setXp(int xp) => emit(state.copyWith(xp: xp));

  /// Add [points] to XP and fire the floating "+XP" particle.
  void addXp(int points, {double? x, double? y}) {
    emit(state.copyWith(xp: state.xp + points));
    XpFloatService.instance.show(points, x: x, y: y);
  }

  void setBiteCoins(int coins) => emit(state.copyWith(biteCoins: coins));

  void addBiteCoins(int coins) =>
      emit(state.copyWith(biteCoins: state.biteCoins + coins));

  // ── Streaks ──
  void setStreakCount(int count) => emit(state.copyWith(streakCount: count));

  void setLongestStreak(int count) =>
      emit(state.copyWith(longestStreak: count));

  void setStreakMultiplier(double m) =>
      emit(state.copyWith(streakMultiplier: m));

  void setStreakFreezes(int count) =>
      emit(state.copyWith(streakFreezes: count));

  // ── Daily chest / sheets ──
  void setDailyChestClaimed(bool value) =>
      emit(state.copyWith(dailyChestClaimed: value));

  void setShowDailyChest(bool value) =>
      emit(state.copyWith(showDailyChest: value));

  void setShowChestRewards(ChestRewards? rewards) =>
      emit(state.copyWith(showChestRewards: rewards, clearChestRewards: rewards == null));

  void setShowStreakSheet(bool value) =>
      emit(state.copyWith(showStreakSheet: value));

  void setMealPlannerSheet(MealPlannerSheet? sheet) => emit(state.copyWith(
        mealPlannerSheet: sheet,
        clearMealPlannerSheet: sheet == null,
      ));

  // ── Meal tray / calendar ──
  void addMealItem(MealItem item) {
    if (state.mealItems.contains(item)) return;
    emit(state.copyWith(mealItems: [...state.mealItems, item]));
  }

  void removeMealItem(MealItem item) {
    emit(state.copyWith(
      mealItems: state.mealItems.where((m) => m != item).toList(),
    ));
  }

  void clearMealItems() => emit(state.copyWith(mealItems: const []));

  void setMealCalendar(MealCalendar calendar) =>
      emit(state.copyWith(mealCalendar: calendar));

  // ── Social ──
  void setSharedPost(SharedPost? post) =>
      emit(state.copyWith(sharedPost: post, clearSharedPost: post == null));

  void setTrendingMode(bool value) =>
      emit(state.copyWith(trendingMode: value));

  /// Opening a deck card clears any recipe picked from elsewhere.
  void setActiveCardIndex(int index) => emit(
        state.copyWith(activeCardIndex: index, clearSelectedRecipe: true),
      );

  /// Show [card] in Recipe Detail (used outside the swipe deck).
  void viewRecipe(BiteCard card) =>
      emit(state.copyWith(selectedRecipe: card));

  void setNotificationCount(int count) =>
      emit(state.copyWith(notificationCount: count));

  // ── Badges ──
  void setUserBadges(List<String> badges) =>
      emit(state.copyWith(userBadges: badges));

  void setBadgeReveal(String? id) =>
      emit(state.copyWith(badgeReveal: id, clearBadgeReveal: id == null));

  /// Grant badges for real user actions. Dedupes owned ids and pops the
  /// reveal overlay for the first newly-unlocked badge.
  void awardBadges(List<String> ids) {
    if (ids.isEmpty) return;
    final owned = state.userBadges.toSet();
    final fresh = ids.where((id) => !owned.contains(id)).toList();
    if (fresh.isEmpty) return;
    emit(state.copyWith(userBadges: [...state.userBadges, ...fresh]));
    if (state.badgeReveal != null) return;
    final badge = BadgeCatalog.byId(fresh.first);
    if (badge != null) {
      emit(state.copyWith(badgeReveal: badge.id));
      Future<void>.delayed(const Duration(milliseconds: 3200), () {
        if (isClosed || state.badgeReveal != badge.id) return;
        emit(state.copyWith(clearBadgeReveal: true));
      });
    }
  }

  // ── Profile hydration ──
  /// Re-hydrate gamification + preference state from the signed-in profile.
  /// Idempotent — only hydrates once per profile (until [resetHydration]).
  void hydrateFromProfile(Profile profile) {
    if (state.hydrated) return;
    emit(state.copyWith(
      xp: profile.xp,
      biteCoins: profile.biteCoins,
      streakCount: profile.streakCount,
      longestStreak: profile.longestStreak,
      streakMultiplier: profile.streakMultiplier,
      streakFreezes: profile.streakFreezes,
      dailyChestClaimed: profile.dailyChestClaimed,
      isPremium: profile.isPremium,
      userTier: profile.userTier,
      userCuisines: profile.cuisines,
      userBadges: profile.badges,
      ageVerified: profile.ageVerified,
      locationGranted: profile.locationGranted,
      hydrated: true,
    ));
  }

  void resetHydration() => emit(state.copyWith(hydrated: false));

  /// Gamification fields persisted to `profiles`. Used to detect changes
  /// worth syncing (see `_FlowHost`).
  Map<String, dynamic> get persistedFields => {
        'xp': state.xp,
        'bite_coins': state.biteCoins,
        'streak_count': state.streakCount,
        'longest_streak': state.longestStreak,
        'streak_multiplier': state.streakMultiplier,
        'streak_freezes': state.streakFreezes,
        'daily_chest_claimed': state.dailyChestClaimed,
        'badges': state.userBadges,
        'age_verified': state.ageVerified,
        'location_granted': state.locationGranted,
      };

  /// Reset to guest defaults — mirrors `restartDemo` for logged-out users.
  void resetToGuest() {
    emit(guestAppState);
  }
}
