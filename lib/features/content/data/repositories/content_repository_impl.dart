import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/table_names.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/bite_card.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/content_repository.dart';
import '../models/content_mapper.dart';
import '../seed_data.dart';

/// Supabase-backed [ContentRepository] with seed fallback.
/// Mirrors the JS reactive store: real rows replace seeds when present,
/// and any failure silently keeps the demo data so UX never breaks.
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({SupabaseClientProvider? provider})
      : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  @override
  Future<ContentCatalog> fetchContent() async {
    final seeds = ContentCatalog(
      recipes: SeedData.recipes,
      drinks: SeedData.drinks,
      places: SeedData.places,
    );
    try {
      final rRes = await _client.from(TableNames.recipes).select().order('id');
      final dRes = await _client.from(TableNames.drinks).select().order('id');
      final pRes = await _client.from(TableNames.places).select().order('id');

      final recipes = _rows(rRes);
      final drinks = _rows(dRes);
      final places = _rows(pRes);

      return ContentCatalog(
        recipes: recipes.isEmpty
            ? seeds.recipes
            : recipes.map(ContentMapper.recipeFromRow).toList(),
        drinks: drinks.isEmpty
            ? seeds.drinks
            : drinks.map(ContentMapper.drinkFromRow).toList(),
        places: places.isEmpty
            ? seeds.places
            : places.map(ContentMapper.placeFromRow).toList(),
      );
    } catch (e) {
      debugPrint('[content] Falling back to seed data: $e');
      return seeds;
    }
  }

  @override
  List<BiteCard> deckFor(String subTab, ContentCatalog catalog) {
    return switch (subTab) {
      'drinks' => catalog.drinks,
      'places' => catalog.places,
      _ => catalog.recipes,
    };
  }

  @override
  Future<List<SavedItem>> fetchSavedItems(String userId) async {
    try {
      final res = await _client
          .from(TableNames.savedItems)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final rows = _rows(res);
      if (rows.isEmpty) return SeedData.savedItems;
      return rows.map(ContentMapper.savedFromRow).toList();
    } catch (e) {
      debugPrint('[content] Saved items fallback to seed: $e');
      return SeedData.savedItems;
    }
  }

  @override
  Future<ContentWriteResult> saveItem(
    String userId,
    BiteCard card,
    String itemType,
  ) async {
    try {
      final existing = await _client
          .from(TableNames.savedItems)
          .select('id')
          .eq('user_id', userId)
          .eq('item_type', itemType)
          .eq('item_id', card.id)
          .maybeSingle();
      if (existing != null) return const ContentWriteResult.ok();

      await _client.from(TableNames.savedItems).insert({
        'user_id': userId,
        'item_type': itemType,
        'item_id': card.id,
        'title': card.title,
        'emoji': card.emoji,
        'image_url': card.image,
        'cuisine': card.cuisine,
      });
      return const ContentWriteResult.ok();
    } catch (e) {
      return ContentWriteResult.failure(e.toString());
    }
  }

  @override
  Future<ContentWriteResult> removeSavedItem(
    String userId,
    String id,
  ) async {
    try {
      await _client
          .from(TableNames.savedItems)
          .delete()
          .eq('user_id', userId)
          .eq('id', id);
      return const ContentWriteResult.ok();
    } catch (e) {
      return ContentWriteResult.failure(e.toString());
    }
  }

  @override
  Future<MealCalendar> fetchMealPlans(String userId) async {
    final grouped = <String, Map<String, List<MealPlan>>>{};
    try {
      final res = await _client
          .from(TableNames.mealPlans)
          .select()
          .eq('user_id', userId)
          .order('plan_date');
      for (final row in _rows(res)) {
        final meal = ContentMapper.mealFromRow(row);
        grouped
            .putIfAbsent(meal.planDate, () => {})
            .putIfAbsent(meal.mealSlot, () => [])
            .add(meal);
      }
    } catch (e) {
      debugPrint('[content] Meal plans load failed: $e');
    }
    return grouped;
  }

  @override
  Future<ContentWriteResult<MealPlan>> addMealPlan(
    String userId, {
    required String planDate,
    required String mealSlot,
    required String title,
    required String emoji,
    required String color,
  }) async {
    try {
      final res = await _client
          .from(TableNames.mealPlans)
          .insert({
            'user_id': userId,
            'plan_date': planDate,
            'meal_slot': mealSlot,
            'title': title,
            'emoji': emoji,
            'color': color,
          })
          .select()
          .single();
      return ContentWriteResult.ok(ContentMapper.mealFromRow(res));
    } catch (e) {
      return ContentWriteResult.failure(e.toString());
    }
  }

  @override
  Future<ContentWriteResult> removeMealPlan(
    String userId,
    String mealId,
  ) async {
    try {
      await _client
          .from(TableNames.mealPlans)
          .delete()
          .eq('user_id', userId)
          .eq('id', mealId);
      return const ContentWriteResult.ok();
    } catch (e) {
      return ContentWriteResult.failure(e.toString());
    }
  }

  @override
  Future<void> recordSwipe(
    String userId, {
    required String itemType,
    required int itemId,
    required String action,
    String? cuisine,
  }) async {
    try {
      await _client.from(TableNames.swipes).insert({
        'user_id': userId,
        'item_type': itemType,
        'item_id': itemId,
        'action': action,
        'cuisine': cuisine,
      });
    } catch (e) {
      debugPrint('[content] Swipe record failed (non-critical): $e');
    }
  }

  List<Map<String, dynamic>> _rows(List<dynamic> data) {
    return data.cast<Map<String, dynamic>>();
  }
}
