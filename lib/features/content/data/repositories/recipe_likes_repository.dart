import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/table_names.dart';
import '../../../../core/network/supabase_client_provider.dart';

/// Likes on recipes and drinks (`public.recipe_likes`). The `hearts_count`
/// on the recipe / drink row is kept by a DB trigger.
class RecipeLikesRepository {
  RecipeLikesRepository({SupabaseClientProvider? provider})
    : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  /// Signed-in user's id, or null when signed out.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Whether [userId] has liked the item. [itemType] is `recipe` or `drink`.
  Future<bool> isLiked(String userId, String itemType, int itemId) async {
    final res = await _client
        .from(TableNames.recipeLikes)
        .select('item_id')
        .eq('user_id', userId)
        .eq('item_type', itemType)
        .eq('item_id', itemId)
        .maybeSingle();
    return res != null;
  }

  /// Current `hearts_count` of the item (the cached card may be stale).
  Future<String?> fetchHearts(String itemType, int itemId) async {
    final res = await _client
        .from(itemType == 'drink' ? TableNames.drinks : TableNames.recipes)
        .select('hearts_count')
        .eq('id', itemId)
        .maybeSingle();
    return res?['hearts_count'] as String?;
  }

  /// Upsert so a double tap can't fail on the primary key.
  Future<void> like(String userId, String itemType, int itemId) => _client
      .from(TableNames.recipeLikes)
      .upsert(
        {'item_type': itemType, 'item_id': itemId, 'user_id': userId},
        ignoreDuplicates: true,
      );

  Future<void> unlike(String userId, String itemType, int itemId) => _client
      .from(TableNames.recipeLikes)
      .delete()
      .eq('user_id', userId)
      .eq('item_type', itemType)
      .eq('item_id', itemId);

  /// True when the `recipe_likes` migration hasn't been applied.
  static bool isMissingTable(Object e) =>
      e is PostgrestException && (e.code == 'PGRST205' || e.code == '42P01');
}
