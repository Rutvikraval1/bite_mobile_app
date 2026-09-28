import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/premium_gate_service.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

/// Manages the auth session and profile. Ports `useAuth` + `AuthProvider`.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _authSub = _repository.streamAuthUser().listen(_onUserChanged);
    _bootstrap();
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _authSub;

  Future<void> _bootstrap() async {
    final user = await _repository.getCurrentUser();
    if (user == null) {
      emit(const AuthState(user: null, loading: false));
      return;
    }
    _loadProfile(user);
  }

  Future<void> _onUserChanged(AuthUser? user) async {
    if (user == null) {
      emit(const AuthState(user: null, loading: false));
      return;
    }
    _loadProfile(user);
  }

  Future<void> _loadProfile(AuthUser user) async {
    emit(AuthState(user: user, loading: true));
    var result = await _repository.fetchProfile(user.id);
    if (result.hasError) {
      // Trigger race — create a minimal row then refetch.
      await _repository.createProfile(user.id);
      result = await _repository.fetchProfile(user.id);
    }
    final profile = result.profile;
    if (profile != null) {
      PremiumGateService.instance
          .setPremiumState(premium: profile.isPremium, tier: profile.userTier);
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

  Future<AuthResult> deleteAccount() {
    return _repository.deleteAccount();
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
      if (!fresh.hasError) {
        emit(state.copyWith(profile: fresh.profile));
      }
    }
    return result.isSuccess
        ? const AuthResult()
        : AuthResult.failure(result.error!);
  }

  /// Local-only profile refresh used after XP/reward flows update a table.
  Future<void> refreshProfile() async {
    final userId = state.user?.id;
    if (userId == null) return;
    final result = await _repository.fetchProfile(userId);
    if (!result.hasError) {
      emit(state.copyWith(profile: result.profile));
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await super.close();
  }
}
