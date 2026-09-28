/// Typed result used by repositories — mirrors the JS `Result<T>` shape.
library;

import 'package:equatable/equatable.dart';

class DataResult<T> with Equatable {
  const DataResult._({this.error, this.data});

  const DataResult.success(T data)
      : this._(error: null, data: data);

  const DataResult.failure(String error) : this._(error: error, data: null);

  final String? error;
  final T? data;

  bool get hasError => error != null;

  @override
  List<Object?> get props => [error, data];
}
