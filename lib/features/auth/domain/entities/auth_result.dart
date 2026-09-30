/// Auth provider options.
enum AuthProviderType { google, apple, email }

/// Result of an auth action.
class AuthResult {
  const AuthResult({
    this.error,
    this.userId,
    this.needsEmailConfirmation = false,
  });

  final String? error;
  final String? userId;
  final bool needsEmailConfirmation;

  bool get isSuccess => error == null;

  static AuthResult failure(String error) => AuthResult(error: error);
}

/// Authenticated user (wraps the Supabase auth user).
class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.name = '',
    this.username = '',
    this.onboarded = false,
  });

  final String id;
  final String? email;
  final String name;
  final String username;

  /// True once the user has finished (or skipped) signup onboarding.
  /// Stored in Supabase auth user metadata so it follows the account.
  final bool onboarded;

  AuthUser copyWith({bool? onboarded}) => AuthUser(
    id: id,
    email: email,
    name: name,
    username: username,
    onboarded: onboarded ?? this.onboarded,
  );
}
