import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/chat_repository.dart';
import '../../domain/social_models.dart';

@immutable
class ChatState {
  const ChatState({
    this.loading = true,
    this.conversations = const [],
    this.rooms = const [],
    this.joinedRooms = const {},
    this.roomNewCounts = const {},
  });

  final bool loading;

  /// DMs + groups (accepted and pending requests).
  final List<ChatConversation> conversations;
  final List<ChatRoom> rooms;

  /// Room id → the user's last-read time, for rooms they joined.
  final Map<String, DateTime> joinedRooms;

  /// Room id → messages since last read (joined) or in the last 24h.
  final Map<String, int> roomNewCounts;

  List<ChatConversation> get messages =>
      conversations.where((c) => !c.isRequest && !c.isGroup).toList();
  List<ChatConversation> get requests => conversations.where((c) => c.isRequest).toList();
  List<ChatConversation> get groups =>
      conversations.where((c) => !c.isRequest && c.isGroup).toList();
  List<ChatRoom> get kitchens => rooms.where((r) => r.isKitchen).toList();
  List<ChatRoom> communities(String tier) =>
      rooms.where((r) => !r.isKitchen && r.tier == tier).toList();

  ChatState copyWith({
    bool? loading,
    List<ChatConversation>? conversations,
    List<ChatRoom>? rooms,
    Map<String, DateTime>? joinedRooms,
    Map<String, int>? roomNewCounts,
  }) {
    return ChatState(
      loading: loading ?? this.loading,
      conversations: conversations ?? this.conversations,
      rooms: rooms ?? this.rooms,
      joinedRooms: joinedRooms ?? this.joinedRooms,
      roomNewCounts: roomNewCounts ?? this.roomNewCounts,
    );
  }
}

/// Chat tab inbox: conversations, requests, rooms. Stays live through a
/// realtime subscription while a user is bound.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.repository) : super(const ChatState());

  final ChatRepository repository;
  String? _userId;
  String? get userId => _userId;
  RealtimeChannel? _channel;
  Timer? _debounce;

  int unreadCount() {
    final id = _userId;
    if (id == null) return 0;
    return state.messages.where((c) => c.unreadFor(id)).length;
  }

  Future<void> bind(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    _debounce?.cancel();
    final old = _channel;
    _channel = null;
    if (old != null) unawaited(repository.unsubscribe(old));
    if (isClosed) return;
    emit(const ChatState());
    if (userId == null) return;
    _channel = repository.subscribeInbox(userId, _scheduleRefresh);
    await refresh();
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), refresh);
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null || isClosed) return;
    try {
      final (conversations, rooms) = await (
        repository.fetchConversations(userId),
        repository.fetchRooms(),
      ).wait;
      final roomIds = [for (final r in rooms) r.id];
      final since = DateTime.now().subtract(const Duration(days: 1));
      final (joined, activity) = await (
        repository.fetchJoinedRooms(userId, roomIds),
        repository.fetchRoomActivity(roomIds, since),
      ).wait;
      if (isClosed || userId != _userId) return;
      emit(state.copyWith(
        loading: false,
        conversations: conversations,
        rooms: rooms,
        joinedRooms: joined,
        roomNewCounts: {
          for (final r in rooms)
            r.id: (activity[r.id] ?? const <DateTime>[])
                .where((at) => joined[r.id] == null || at.isAfter(joined[r.id]!))
                .length,
        },
      ));
    } catch (e) {
      debugPrint('[chat] refresh failed: $e');
      if (!isClosed && userId == _userId) emit(state.copyWith(loading: false));
    }
  }

  /// Marks a thread read locally and in the database.
  Future<void> markRead(String conversationId) async {
    final userId = _userId;
    if (userId == null) return;
    final now = DateTime.now();
    emit(state.copyWith(
      conversations: [
        for (final c in state.conversations)
          c.id == conversationId
              ? ChatConversation(
                  id: c.id,
                  kind: c.kind,
                  status: c.status,
                  lastReadAt: now,
                  name: c.name,
                  emoji: c.emoji,
                  peers: c.peers,
                  muted: c.muted,
                  lastMessagePreview: c.lastMessagePreview,
                  lastMessageAt: c.lastMessageAt,
                  lastSenderId: c.lastSenderId,
                  createdAt: c.createdAt,
                )
              : c,
      ],
      joinedRooms: state.joinedRooms.containsKey(conversationId)
          ? {...state.joinedRooms, conversationId: now}
          : null,
      roomNewCounts: {...state.roomNewCounts, conversationId: 0},
    ));
    try {
      await repository.markRead(userId, conversationId);
    } catch (e) {
      debugPrint('[chat] markRead failed: $e');
    }
  }

  /// Joins a public room (no-op if already a member). Returns success.
  Future<bool> joinRoom(String roomId) async {
    final userId = _userId;
    if (userId == null) return false;
    if (state.joinedRooms.containsKey(roomId)) return true;
    try {
      await repository.joinRoom(userId, roomId);
      if (!isClosed) {
        emit(state.copyWith(joinedRooms: {...state.joinedRooms, roomId: DateTime.now()}));
      }
      return true;
    } catch (e) {
      debugPrint('[chat] join failed: $e');
      return false;
    }
  }

  Future<bool> acceptRequest(String conversationId) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await repository.acceptRequest(userId, conversationId);
      await refresh();
      return true;
    } catch (e) {
      debugPrint('[chat] accept failed: $e');
      return false;
    }
  }

  Future<bool> declineRequest(String conversationId) async {
    final userId = _userId;
    if (userId == null) return false;
    final before = state.conversations;
    emit(state.copyWith(conversations: [for (final c in before) if (c.id != conversationId) c]));
    try {
      await repository.declineRequest(userId, conversationId);
      return true;
    } catch (e) {
      debugPrint('[chat] decline failed: $e');
      if (!isClosed) emit(state.copyWith(conversations: before));
      return false;
    }
  }

  /// Opens (or reuses) a DM with [handle]. Returns the conversation id.
  Future<String?> startDm(String handle) async {
    try {
      final id = await repository.startDm(handle);
      unawaited(refresh());
      return id;
    } catch (e) {
      debugPrint('[chat] startDm failed: $e');
      return null;
    }
  }

  Future<bool> setMuted(String conversationId, bool muted) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await repository.setMuted(userId, conversationId, muted);
      unawaited(refresh());
      return true;
    } catch (e) {
      debugPrint('[chat] mute failed: $e');
      return false;
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    final ch = _channel;
    if (ch != null) unawaited(repository.unsubscribe(ch));
    return super.close();
  }
}
