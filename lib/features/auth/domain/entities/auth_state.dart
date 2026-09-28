import 'auth_result.dart';
import 'profile.dart';

/// Auth session state exposed by the auth layer.
class AuthState {
  const AuthState({
    this.user,
    this.profile,
    this.loading = true,
  });

  final AuthUser? user;
  final Profile? profile;
  final bool loading;

  bool get authenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    Profile? profile,
    bool? loading,
    bool clearUser = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearProfile ? null : (profile ?? this.profile),
      loading: loading ?? this.loading,
    );
  }
}
