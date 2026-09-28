import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for all application exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown for connectivity / timeout issues.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Thrown for auth (Supabase AuthException or missing session) issues.
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

/// Thrown for database query/constraint issues.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

/// Thrown when cached/local state is unavailable or corrupted.
class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// Generic fallback.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause});
}

/// Maps any thrown object to an [AppException].
abstract final class ExceptionMapper {
  static AppException from(Object? error, {String fallback = 'Something went wrong'}) {
    if (error is AppException) return error;
    if (error is AuthException) {
      return AuthException(error.message, cause: error);
    }
    if (error is PostgrestException) {
      return DatabaseException(error.message, cause: error);
    }
    if (error is FormatException) {
      return CacheException('Invalid data format', cause: error);
    }
    if (error is Exception) {
      return NetworkException(error.toString(), cause: error);
    }
    return UnknownException(fallback, cause: error);
  }
}
