import 'auth_result.dart';
import 'profile.dart';

/// Auth session state exposed by the auth layer.
class AuthState {
  const AuthState({this.user, this.profile, this.loading = true});

  final AuthUser? user;
  final Profile? profile;
  final bool loading;

  bool get authenticated => user != null;

  /// Whether this signed-in user still has to go through signup onboarding
  /// (profile setup → cuisines → dietary → skill → tutorial).
  ///
  /// A profile row always exists after signup (DB trigger), so "no profile"
  /// can't be used as the signal. Accounts from before the `onboarded` flag
  /// count as done if they already saved onboarding preferences.
  bool get needsOnboarding {
    final u = user;
    if (u == null || u.onboarded) return false;
    final p = profile;
    if (p == null) return true;
    return p.cookingSkill == null && p.cuisines.isEmpty;
  }

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
