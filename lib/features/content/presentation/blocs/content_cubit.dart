import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bite_card.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/content_repository.dart';

/// Loads and mutates the global catalog + user-scoped saved items and meal
/// plans. Ports `useContent` and the `data.js` reactive store.
class ContentState {
  const ContentState({
    this.recipes = const [],
    this.drinks = const [],
    this.places = const [],
    this.loading = true,
    this.error,
    this.savedItems = const [],
    this.savedLoading = false,
    this.mealPlans = const {},
  });

  final List<BiteCard> recipes;
  final List<BiteCard> drinks;
  final List<BiteCard> places;
  final bool loading;
  final String? error;
  final List<SavedItem> savedItems;
  final bool savedLoading;
  final MealCalendar mealPlans;

  ContentState copyWith({
    List<BiteCard>? recipes,
    List<BiteCard>? drinks,
    List<BiteCard>? places,
    bool? loading,
    String? error,
    bool clearError = false,
    List<SavedItem>? savedItems,
    bool? savedLoading,
    MealCalendar? mealPlans,
  }) {
    return ContentState(
      recipes: recipes ?? this.recipes,
      drinks: drinks ?? this.drinks,
      places: places ?? this.places,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      savedItems: savedItems ?? this.savedItems,
      savedLoading: savedLoading ?? this.savedLoading,
      mealPlans: mealPlans ?? this.mealPlans,
    );
  }
}

class ContentCubit extends Cubit<ContentState> {
  ContentCubit(this._repository) : super(const ContentState()) {
    loadContent();
  }

  final ContentRepository _repository;

  /// Current authenticated user id — set via [bind].
  String? _userId;
  String? get userId => _userId;

  /// Attach a user (session resume) and load their saved items + meal plans.
  /// Passing null unbinds and clears user-scoped data.
  Future<void> bind(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      emit(state.copyWith(
        savedItems: const [],
        mealPlans: const {},
        savedLoading: false,
      ));
      return;
    }
    await Future.wait([reloadSaved(), reloadMealPlans()]);
  }

  /// Load the global catalog. Fetch-once; retry on error.
  Future<void> loadContent() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final catalog = await _repository.fetchContent();
      if (isClosed) return;
      emit(state.copyWith(
        recipes: catalog.recipes,
        drinks: catalog.drinks,
        places: catalog.places,
        loading: false,
        clearError: true,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> refetch() => loadContent();

  Future<void> reloadSaved() async {
    final userId = _userId;
    if (userId == null) return;
    emit(state.copyWith(savedLoading: true));
    final items = await _repository.fetchSavedItems(userId);
    if (isClosed) return;
    emit(state.copyWith(savedItems: items, savedLoading: false));
  }

  Future<void> reloadMealPlans() async {
    final userId = _userId;
    if (userId == null) return;
    final plans = await _repository.fetchMealPlans(userId);
    if (isClosed) return;
    emit(state.copyWith(mealPlans: plans));
  }

  /// Best-effort swipe logging; never affects deck UX.
  Future<void> recordSwipe({
    required String itemType,
    required int itemId,
    required String action,
    String? cuisine,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.recordSwipe(
      userId,
      itemType: itemType,
      itemId: itemId,
      action: action,
      cuisine: cuisine,
    );
  }

  Future<ContentWriteResult> saveItem(BiteCard card, String itemType) async {
    final userId = _userId;
    if (userId == null) {
      return ContentWriteResult.failure('Not authenticated');
    }
    final result = await _repository.saveItem(userId, card, itemType);
    if (result.isSuccess) await reloadSaved();
    return result;
  }

  Future<ContentWriteResult> removeSavedItem(String id) async {
    final userId = _userId;
    if (userId == null) {
      return ContentWriteResult.failure('Not authenticated');
    }
    final result = await _repository.removeSavedItem(userId, id);
    if (result.isSuccess) {
      emit(state.copyWith(
        savedItems: state.savedItems.where((s) => s.id != id).toList(),
      ));
    }
    return result;
  }

  Future<ContentWriteResult<MealPlan>> addMealPlan({
    required String planDate,
    required String mealSlot,
    required String title,
    required String emoji,
    required String color,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return ContentWriteResult.failure('Not authenticated');
    }
    final result = await _repository.addMealPlan(
      userId,
      planDate: planDate,
      mealSlot: mealSlot,
      title: title,
      emoji: emoji,
      color: color,
    );
    final meal = result.data;
    if (result.isSuccess && meal != null) {
      final next = Map<String, Map<String, List<MealPlan>>>.from(
        state.mealPlans,
      );
      next.putIfAbsent(meal.planDate, () => {});
      next[meal.planDate]!.putIfAbsent(meal.mealSlot, () => []);
      next[meal.planDate]![meal.mealSlot]!.add(meal);
      emit(state.copyWith(mealPlans: next));
    }
    return result;
  }

  Future<ContentWriteResult> removeMealPlan(String mealId) async {
    final userId = _userId;
    if (userId == null) {
      return ContentWriteResult.failure('Not authenticated');
    }
    final result = await _repository.removeMealPlan(userId, mealId);
    if (result.isSuccess) {
      final next = <String, Map<String, List<MealPlan>>>{};
      state.mealPlans.forEach((date, slots) {
        final filteredSlots = <String, List<MealPlan>>{};
        slots.forEach((slot, items) {
          final filtered = items.where((m) => m.id != mealId).toList();
          if (filtered.isNotEmpty) filteredSlots[slot] = filtered;
        });
        if (filteredSlots.isNotEmpty) next[date] = filteredSlots;
      });
      emit(state.copyWith(mealPlans: next));
    }
    return result;
  }

  /// Deck for a given sub-tab ("food" / "drinks" / "places").
  List<BiteCard> deckFor(String subTab) {
    return _repository.deckFor(subTab, ContentCatalog(
      recipes: state.recipes,
      drinks: state.drinks,
      places: state.places,
    ));
  }
}
