import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../domain/social_models.dart';

/// DMs, groups, community rooms, live kitchens and their messages.
class ChatRepository {
  ChatRepository({SupabaseClientProvider? provider})
      : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  List<Map<String, dynamic>> _rows(Object? res) =>
      (res as List).cast<Map<String, dynamic>>();

  /// DMs and private groups the user belongs to (accepted + requests).
  Future<List<ChatConversation>> fetchConversations(String userId) async {
    final res = await _client
        .from(TableNames.conversationMembers)
        .select(ChatConversation.memberSelect)
        .eq('user_id', userId);
    final list = [
      for (final r in _rows(res))
        if (r['conversation'] != null) ChatConversation.fromMemberRow(r, userId),
    ].where((c) => c.kind == 'dm' || c.kind == 'group').toList()
      ..sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return list;
  }

  Future<ChatConversation?> fetchConversation(String userId, String conversationId) async {
    final res = await _client
        .from(TableNames.conversationMembers)
        .select(ChatConversation.memberSelect)
        .eq('user_id', userId)
        .eq('conversation_id', conversationId)
        .maybeSingle();
    if (res == null || res['conversation'] == null) return null;
    return ChatConversation.fromMemberRow(res, userId);
  }

  /// Community rooms and live kitchens.
  Future<List<ChatRoom>> fetchRooms() async {
    final res = await _client
        .from(TableNames.conversations)
        .select()
        .inFilter('kind', ['community', 'kitchen'])
        .order('sort_order');
    return _rows(res).map(ChatRoom.fromRow).toList();
  }

  Future<ChatRoom?> fetchRoom(String id) async {
    final res = await _client.from(TableNames.conversations).select().eq('id', id).maybeSingle();
    return res == null ? null : ChatRoom.fromRow(res);
  }

  /// Rooms the user joined → their last-read time.
  Future<Map<String, DateTime>> fetchJoinedRooms(String userId, List<String> roomIds) async {
    if (roomIds.isEmpty) return {};
    final res = await _client
        .from(TableNames.conversationMembers)
        .select('conversation_id, last_read_at')
        .eq('user_id', userId)
        .inFilter('conversation_id', roomIds);
    return {
      for (final r in _rows(res))
        r['conversation_id'] as String:
            DateTime.tryParse(r['last_read_at'].toString())?.toLocal() ?? DateTime.now(),
    };
  }

  /// Message timestamps per room since [since] (for "N new" pills).
  Future<Map<String, List<DateTime>>> fetchRoomActivity(List<String> roomIds, DateTime since) async {
    if (roomIds.isEmpty) return {};
    final res = await _client
        .from(TableNames.messages)
        .select('conversation_id, created_at')
        .inFilter('conversation_id', roomIds)
        .gte('created_at', since.toUtc().toIso8601String())
        .limit(2000);
    final out = <String, List<DateTime>>{};
    for (final r in _rows(res)) {
      final at = DateTime.tryParse(r['created_at'].toString())?.toLocal();
      if (at != null) out.putIfAbsent(r['conversation_id'] as String, () => []).add(at);
    }
    return out;
  }

  Future<List<ChatMessageItem>> fetchMessages(String conversationId, {int limit = 200}) async {
    final res = await _client
        .from(TableNames.messages)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);
    return _rows(res).map(ChatMessageItem.fromRow).toList().reversed.toList();
  }

  Future<ChatMessageItem> sendMessage({
    required String userId,
    required String conversationId,
    String body = '',
    int? recipeId,
  }) async {
    final res = await _client
        .from(TableNames.messages)
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'body': body,
          'recipe_id': recipeId,
        })
        .select()
        .single();
    return ChatMessageItem.fromRow(res);
  }

  /// Opens (or reuses) a DM with [handle]; returns the conversation id.
  Future<String> startDm(String handle) async {
    final res = await _client.rpc('start_dm', params: {'p_handle': handle});
    return res as String;
  }

  Future<void> joinRoom(String userId, String conversationId) => _client
      .from(TableNames.conversationMembers)
      .upsert(
        {'conversation_id': conversationId, 'user_id': userId, 'status': 'accepted'},
        onConflict: 'conversation_id,user_id',
        ignoreDuplicates: true,
      );

  Future<void> markRead(String userId, String conversationId) => _client
      .from(TableNames.conversationMembers)
      .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', userId)
      .eq('conversation_id', conversationId);

  Future<void> setMuted(String userId, String conversationId, bool muted) => _client
      .from(TableNames.conversationMembers)
      .update({'muted': muted})
      .eq('user_id', userId)
      .eq('conversation_id', conversationId);

  Future<void> acceptRequest(String userId, String conversationId) => _client
      .from(TableNames.conversationMembers)
      .update({'status': 'accepted', 'last_read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', userId)
      .eq('conversation_id', conversationId);

  /// Declining a request removes the user from the conversation.
  Future<void> declineRequest(String userId, String conversationId) => _client
      .from(TableNames.conversationMembers)
      .delete()
      .eq('user_id', userId)
      .eq('conversation_id', conversationId);

  // ── Realtime ──

  /// Fires for every new message the user can see (inbox refresh).
  RealtimeChannel subscribeInbox(String userId, void Function() onChange) {
    return _client
        .channel('inbox:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: TableNames.messages,
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TableNames.conversationMembers,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  /// Live thread: new messages, typing broadcasts and online presence.
  RealtimeChannel subscribeThread({
    required String conversationId,
    required String userId,
    required void Function(ChatMessageItem message) onMessage,
    required void Function(String userId) onTyping,
    required void Function(Set<String> onlineUserIds) onPresence,
  }) {
    final channel = _client.channel(
      'chat:$conversationId',
      opts: RealtimeChannelConfig(key: userId),
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: TableNames.messages,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onMessage(ChatMessageItem.fromRow(payload.newRecord)),
        )
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final from = payload['user_id'] as String?;
            if (from != null && from != userId) onTyping(from);
          },
        )
        .onPresenceSync((_) {
          onPresence({
            for (final s in channel.presenceState())
              for (final p in s.presences)
                if (p.payload['user_id'] is String) p.payload['user_id'] as String,
          });
        })
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            channel.track({'user_id': userId});
          }
        });
    return channel;
  }

  Future<void> sendTyping(RealtimeChannel channel, String userId) =>
      channel.sendBroadcastMessage(event: 'typing', payload: {'user_id': userId});

  Future<void> unsubscribe(RealtimeChannel channel) => _client.removeChannel(channel);
}
