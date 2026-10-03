import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

@immutable
class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<AppNotification> items;
  final bool loading;
  final String? error;

  int get unreadCount => items.where((n) => !n.isRead).length;
}

/// The signed-in user's notification inbox, kept live via Supabase Realtime.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;
  String? _userId;
  RealtimeChannel? _channel;

  /// Attach to [userId] (or detach with null).
  Future<void> bind(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    final old = _channel;
    _channel = null;
    if (old != null) await _repository.unsubscribe(old);
    if (isClosed) return;
    if (userId == null) {
      emit(const NotificationsState());
      return;
    }
    try {
      _channel = _repository.subscribe(userId, refresh);
    } catch (e) {
      debugPrint('[bite] notifications realtime failed: $e');
    }
    await refresh();
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null || isClosed) return;
    emit(NotificationsState(items: state.items, loading: state.items.isEmpty));
    try {
      final items = await _repository.fetch(userId);
      if (isClosed || userId != _userId) return;
      emit(NotificationsState(items: items));
    } catch (e) {
      debugPrint('[bite] notifications fetch failed: $e');
      if (isClosed) return;
      emit(NotificationsState(items: state.items, error: e.toString()));
    }
  }

  Future<void> markRead(String id) async {
    final userId = _userId;
    if (userId == null) return;
    emit(
      NotificationsState(
        items: [for (final n in state.items) n.id == id ? n.markedRead() : n],
      ),
    );
    try {
      await _repository.markRead(userId, id);
    } catch (e) {
      debugPrint('[bite] markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    final userId = _userId;
    if (userId == null) return;
    emit(
      NotificationsState(items: [for (final n in state.items) n.markedRead()]),
    );
    try {
      await _repository.markAllRead(userId);
    } catch (e) {
      debugPrint('[bite] markAllRead failed: $e');
    }
  }

  Future<void> dismiss(String id) async {
    final userId = _userId;
    if (userId == null) return;
    emit(
      NotificationsState(items: state.items.where((n) => n.id != id).toList()),
    );
    try {
      await _repository.delete(userId, id);
    } catch (e) {
      debugPrint('[bite] dismiss failed: $e');
    }
  }

  @override
  Future<void> close() async {
    final c = _channel;
    if (c != null) await _repository.unsubscribe(c);
    return super.close();
  }
}
