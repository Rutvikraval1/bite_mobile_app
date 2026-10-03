import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/toast_service.dart';
import '../../data/follow_repository.dart';

/// Creators the signed-in user follows (lowercase "@handle" set), shared by
/// every Follow button and the Profile "Following" count.
class FollowCubit extends Cubit<Set<String>> {
  FollowCubit(this._repository) : super(const {});

  final FollowRepository _repository;
  String? _userId;

  /// "Chef Priya" / "chefpriya" / "@ChefPriya" → "@chefpriya".
  static String normalize(String handle) {
    final h = handle.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    return '@$h';
  }

  bool isFollowing(String handle) => state.contains(normalize(handle));

  Future<void> bind(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (isClosed) return;
    emit(const {});
    if (userId == null) return;
    try {
      final handles = await _repository.fetch(userId);
      if (!isClosed && userId == _userId) emit(handles);
    } catch (e) {
      debugPrint('[bite] follows fetch failed: $e');
    }
  }

  /// Optimistic follow/unfollow; reverts and toasts on failure.
  Future<void> toggle(String handle) async {
    final userId = _userId;
    final h = normalize(handle);
    if (userId == null || h == '@') return;
    final wasFollowing = state.contains(h);
    emit(wasFollowing ? ({...state}..remove(h)) : {...state, h});
    ToastService.instance.show(wasFollowing ? 'Unfollowed $h' : '✅ Following $h!');
    try {
      if (wasFollowing) {
        await _repository.unfollow(userId, h);
      } else {
        await _repository.follow(userId, h);
      }
    } catch (e) {
      debugPrint('[bite] follow toggle failed: $e');
      if (isClosed || userId != _userId) return;
      emit(wasFollowing ? {...state, h} : ({...state}..remove(h)));
      ToastService.instance.show("⚠️ Couldn't update follow. Try again.");
    }
  }
}
