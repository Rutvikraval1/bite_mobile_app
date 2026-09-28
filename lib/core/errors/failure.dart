import 'package:equatable/equatable.dart';

import 'app_exception.dart';

/// UI-facing failure types surfaced by BLoCs/Cubits.
sealed class Failure with Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

/// Maps an [AppException] to a UI-facing [Failure].
abstract final class FailureMapper {
  static Failure from(AppException exception) {
    return switch (exception) {
      NetworkException() => NetworkFailure(exception.message),
      AuthException() => AuthFailure(exception.message),
      DatabaseException() => DatabaseFailure(exception.message),
      CacheException() => CacheFailure(exception.message),
      UnknownException() => UnknownFailure(exception.message),
    };
  }
}

/// Convenience: turn any throwable into a [Failure].
Failure failureFrom(Object? error) {
  final mapped = ExceptionMapper.from(error);
  return FailureMapper.from(mapped);
}
