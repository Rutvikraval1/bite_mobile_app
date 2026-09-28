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
  });

  final String id;
  final String? email;
  final String name;
  final String username;
}
