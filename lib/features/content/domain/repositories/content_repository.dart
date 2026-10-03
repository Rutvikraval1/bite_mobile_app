import '../entities/bite_card.dart';
import '../entities/cook_entry.dart';
import '../entities/recipe_draft.dart';
import '../entities/meal_plan.dart';
import '../entities/saved_item.dart';

/// Result of a content write — mirrors JS `Result`.
class ContentWriteResult<T> {
  const ContentWriteResult._(this.error, this.data);

  const ContentWriteResult.ok([T? data]) : this._(null, data);

  const ContentWriteResult.failure(String error) : this._(error, null);

  final String? error;
  final T? data;

  bool get isSuccess => error == null;
}

/// Result of a catalog fetch.
class ContentCatalog {
  const ContentCatalog({
    this.recipes = const [],
    this.drinks = const [],
    this.places = const [],
  });

  final List<BiteCard> recipes;
  final List<BiteCard> drinks;
  final List<BiteCard> places;

  bool get isEmpty => recipes.isEmpty && drinks.isEmpty && places.isEmpty;
}

/// Loads the global content catalog and user-scoped saved items / meal plans.
/// Ports `contentService`, `savedItemsService`, `mealPlansService` and
/// `swipesService` from the JS prototype.
abstract interface class ContentRepository {
  /// Fetch the full content catalog (recipes, drinks, places) in parallel.
  /// Content is global — readable by any authenticated user via RLS.
  Future<ContentCatalog> fetchContent();

  /// Derive the deck list for a given sub-tab.
  List<BiteCard> deckFor(String subTab, ContentCatalog catalog);

  /// All saved items for a user, newest first.
  Future<List<SavedItem>> fetchSavedItems(String userId);

  /// Save a card for the current user. No-op if already saved.
  Future<ContentWriteResult> saveItem(
    String userId,
    BiteCard card,
    String itemType,
  );

  /// Remove a saved item for the current user.
  Future<ContentWriteResult> removeSavedItem(String userId, String id);

  /// All meal plans for a user, grouped by date then slot.
  Future<MealCalendar> fetchMealPlans(String userId);

  /// Add a meal to the current user's plan.
  Future<ContentWriteResult<MealPlan>> addMealPlan(
    String userId, {
    required String planDate,
    required String mealSlot,
    required String title,
    required String emoji,
    required String color,
  });

  /// Remove a meal from the current user's plan.
  Future<ContentWriteResult> removeMealPlan(String userId, String mealId);

  /// Recipes created by [userId] (published and drafts), newest first.
  Future<List<BiteCard>> fetchMyRecipes(String userId);

  /// Insert a user recipe; returns the saved row.
  Future<ContentWriteResult<BiteCard>> createRecipe(
    String userId,
    String creator,
    RecipeDraft draft,
  );

  /// Delete one of the user's own recipes.
  Future<ContentWriteResult> deleteRecipe(String userId, int recipeId);

  /// The user's cooking history, newest first.
  Future<List<CookEntry>> fetchCookHistory(String userId);

  /// Record that the user cooked a recipe.
  Future<ContentWriteResult> logCook(
    String userId, {
    required String title,
    required String emoji,
    int? recipeId,
    String? imageUrl,
    int? rating,
  });

  /// Log a swipe interaction. Best-effort — swipe UX must never break
  /// if analytics logging fails.
  Future<void> recordSwipe(
    String userId, {
    required String itemType,
    required int itemId,
    required String action,
    String? cuisine,
  });
}
