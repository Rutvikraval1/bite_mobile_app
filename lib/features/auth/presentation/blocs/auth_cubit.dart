import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/premium_gate_service.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

/// Manages the auth session and profile. Ports `useAuth` + `AuthProvider`.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _authSub = _repository.streamAuthUser().listen(
      _onUserChanged,
      // Token-refresh/network errors on the auth stream must not go uncaught.
      onError: (Object e) => debugPrint('[bite] auth stream error: $e'),
    );
    _bootstrap();
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _authSub;

  Future<void> _bootstrap() async {
    AuthUser? user;
    try {
      user = await _repository.getCurrentUser();
    } catch (e) {
      debugPrint('[bite] getCurrentUser failed: $e');
    }
    if (isClosed) return;
    if (user == null) {
      emit(const AuthState(user: null, loading: false));
      return;
    }
    _loadProfile(user);
  }

  Future<void> _onUserChanged(AuthUser? user) async {
    if (isClosed) return;
    if (user == null) {
      emit(const AuthState(user: null, loading: false));
      return;
    }
    _loadProfile(user);
  }

  Future<void> _loadProfile(AuthUser user) async {
    if (isClosed) return;
    emit(AuthState(user: user, loading: true));
    var result = await _repository.fetchProfile(user.id);
    if (result.hasError && !isClosed) {
      // Trigger race — create a minimal row then refetch.
      await _repository.createProfile(user.id);
      result = await _repository.fetchProfile(user.id);
    }
    // Bail if closed or a newer auth event (sign-out / other user) landed.
    if (isClosed || state.user?.id != user.id) return;
    final profile = result.profile;
    if (profile != null) {
      PremiumGateService.instance.setPremiumState(
        premium: profile.isPremium,
        tier: profile.userTier,
      );
    }
    emit(AuthState(user: user, profile: profile, loading: false));
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String name = '',
    String username = '',
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      name: name,
      username: username,
    );
  }

  Future<AuthResult> signIn(String email, String password) {
    return _repository.signInWithEmail(email, password);
  }

  Future<AuthResult> signInWithProvider(AuthProviderType provider) {
    return _repository.signInWithProvider(provider);
  }

  Future<AuthResult> resetPassword(String email) {
    return _repository.resetPassword(email);
  }

  Future<AuthResult> updatePassword(String newPassword) {
    return _repository.updatePassword(newPassword);
  }

  Future<AuthResult> updateEmail(String newEmail) {
    return _repository.updateEmail(newEmail);
  }

  Future<AuthResult> deleteAccount() {
    return _repository.deleteAccount();
  }

  /// Records that signup onboarding is done so the user isn't sent through
  /// it again on their next login. No-op if already recorded.
  Future<void> markOnboarded() async {
    final user = state.user;
    if (user == null || user.onboarded) return;
    // Update locally first so repeated calls don't re-send the request.
    emit(state.copyWith(user: user.copyWith(onboarded: true)));
    final result = await _repository.markOnboarded();
    if (result.error != null) {
      debugPrint('[bite] markOnboarded failed: ${result.error}');
    }
  }

  Future<AuthResult> signOut() {
    return _repository.signOut();
  }

  Future<AuthResult> updateProfile(Map<String, dynamic> updates) async {
    final userId = state.user?.id;
    if (userId == null) return AuthResult.failure('Not authenticated');
    final result = await _repository.updateProfile(userId, updates);
    if (result.isSuccess) {
      final fresh = await _repository.fetchProfile(userId);
      if (!fresh.hasError && !isClosed && state.user?.id == userId) {
        emit(state.copyWith(profile: fresh.profile));
      }
    }
    return result.isSuccess
        ? const AuthResult()
        : AuthResult.failure(result.error ?? 'Could not update profile');
  }

  /// Writes [updates] to the profile without refetching — used for
  /// frequent background syncs (XP, coins, streaks, badges).
  Future<void> saveFields(Map<String, dynamic> updates) async {
    final userId = state.user?.id;
    if (userId == null || updates.isEmpty) return;
    final result = await _repository.updateProfile(userId, updates);
    if (!result.isSuccess) {
      debugPrint('[bite] saveFields failed: ${result.error}');
    }
  }

  /// Local-only profile refresh used after XP/reward flows update a table.
  Future<void> refreshProfile() async {
    final userId = state.user?.id;
    if (userId == null) return;
    final result = await _repository.fetchProfile(userId);
    if (!result.hasError && !isClosed && state.user?.id == userId) {
      emit(state.copyWith(profile: result.profile));
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await super.close();
  }
}
