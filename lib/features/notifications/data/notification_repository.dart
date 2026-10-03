import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/app_notification.dart';

/// Reads/updates the signed-in user's rows in `public.notifications` and
/// registers FCM device tokens in `public.device_tokens`.
class NotificationRepository {
  NotificationRepository({SupabaseClientProvider? provider})
    : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  Future<List<AppNotification>> fetch(String userId) async {
    final res = await _client
        .from(TableNames.notifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromRow)
        .toList();
  }

  Future<void> markRead(String userId, String id) => _client
      .from(TableNames.notifications)
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', userId)
      .eq('id', id);

  Future<void> markAllRead(String userId) => _client
      .from(TableNames.notifications)
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', userId)
      .isFilter('read_at', null);

  Future<void> delete(String userId, String id) => _client
      .from(TableNames.notifications)
      .delete()
      .eq('user_id', userId)
      .eq('id', id);

  /// Calls [onChange] whenever the user's notifications change.
  RealtimeChannel subscribe(String userId, void Function() onChange) {
    return _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TableNames.notifications,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) =>
      _client.removeChannel(channel);

  Future<void> saveDeviceToken(String userId, String token, String platform) =>
      _client.from(TableNames.deviceTokens).upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');

  Future<void> deleteDeviceToken(String token) =>
      _client.from(TableNames.deviceTokens).delete().eq('token', token);
}
