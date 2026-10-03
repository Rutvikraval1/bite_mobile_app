import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';

/// Reads/writes the signed-in user's rows in `public.follows`.
class FollowRepository {
  FollowRepository({SupabaseClientProvider? provider})
      : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  Future<Set<String>> fetch(String userId) async {
    final res = await _client
        .from(TableNames.follows)
        .select('creator_handle')
        .eq('user_id', userId);
    return (res as List)
        .map((r) => (r as Map)['creator_handle'] as String)
        .toSet();
  }

  Future<void> follow(String userId, String handle) => _client
      .from(TableNames.follows)
      .upsert(
        {'user_id': userId, 'creator_handle': handle},
        onConflict: 'user_id,creator_handle',
      );

  Future<void> unfollow(String userId, String handle) => _client
      .from(TableNames.follows)
      .delete()
      .eq('user_id', userId)
      .eq('creator_handle', handle);
}
