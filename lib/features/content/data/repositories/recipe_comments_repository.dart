import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/table_names.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../domain/entities/recipe_comment.dart';

/// Comments on recipes and drinks (`public.recipe_comments`). The
/// `comments_count` on the recipe / drink row is kept by a DB trigger.
class RecipeCommentsRepository {
  RecipeCommentsRepository({SupabaseClientProvider? provider})
    : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  /// Signed-in user's id, or null when signed out.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Newest first. [itemType] is `recipe` or `drink`.
  Future<List<RecipeComment>> fetch(
    String itemType,
    int itemId, {
    int limit = 200,
  }) async {
    final res = await _client
        .from(TableNames.recipeComments)
        .select(RecipeComment.select)
        .eq('item_type', itemType)
        .eq('item_id', itemId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(RecipeComment.fromRow)
        .toList();
  }

  /// The user's "@handle" — comments are posted under it (null until they
  /// pick a username).
  Future<String?> fetchMyHandle(String userId) async {
    final res = await _client
        .from(TableNames.creators)
        .select('handle')
        .eq('profile_id', userId)
        .maybeSingle();
    return res?['handle'] as String?;
  }

  Future<RecipeComment> add({
    required String userId,
    required String handle,
    required String itemType,
    required int itemId,
    required String body,
  }) async {
    final res = await _client
        .from(TableNames.recipeComments)
        .insert({
          'item_type': itemType,
          'item_id': itemId,
          'user_id': userId,
          'author_handle': handle,
          'body': body,
        })
        .select(RecipeComment.select)
        .single();
    return RecipeComment.fromRow(res);
  }

  /// RLS only lets the author delete their own comment.
  Future<void> delete(String userId, String commentId) => _client
      .from(TableNames.recipeComments)
      .delete()
      .eq('user_id', userId)
      .eq('id', commentId);
}
