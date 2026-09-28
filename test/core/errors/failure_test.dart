import 'package:flutter_test/flutter_test.dart';

import 'package:bite/core/errors/app_exception.dart';
import 'package:bite/core/errors/failure.dart';

void main() {
  group('FailureMapper.from', () {
    test('maps AppException subtypes to their Failure', () {
      expect(
        FailureMapper.from(const NetworkException('offline')),
        isA<NetworkFailure>(),
      );
      expect(
        FailureMapper.from(const AuthException('nope')),
        isA<AuthFailure>(),
      );
      expect(
        FailureMapper.from(const DatabaseException('constraint')),
        isA<DatabaseFailure>(),
      );
      expect(
        FailureMapper.from(const CacheException('corrupt')),
        isA<CacheFailure>(),
      );
      expect(
        FailureMapper.from(const UnknownException('??')),
        isA<UnknownFailure>(),
      );
    });

    test('preserves the message', () {
      final failure = FailureMapper.from(const AuthException('bad creds'));
      expect(failure.message, 'bad creds');
    });
  });

  group('failureFrom', () {
    test('passes AppException through unmapped', () {
      final failure = failureFrom(const NetworkException('timeout'));
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'timeout');
    });

    test('wraps a generic Exception as a NetworkFailure', () {
      final failure = failureFrom(Exception('boom'));
      expect(failure, isA<NetworkFailure>());
    });

    test('wraps a FormatException as a CacheFailure', () {
      final failure = failureFrom(const FormatException('bad'));
      expect(failure, isA<CacheFailure>());
    });

    test('falls back to UnknownFailure for null/unknown', () {
      expect(failureFrom(null), isA<UnknownFailure>());
      expect(failureFrom('a string'), isA<UnknownFailure>());
    });
  });
}
